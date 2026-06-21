import 'dart:convert';
import 'dart:io';

import 'package:cope_x_studio/services/archive_service.dart';
import 'package:cope_x_studio/services/file_service.dart';
import 'package:cope_x_studio/services/thumbnail_service.dart';
import 'package:cope_x_studio/services/web_server/path_guard.dart';
import 'package:cope_x_studio/services/web_server/web_ui.dart';
import 'package:cope_x_studio/utils/file_type_utils.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:cope_x_studio/l10n/l10n_scope.dart';

class WebServerService {
  WebServerService({
    required FileService fileService,
    required ArchiveService archiveService,
  })  : _fileService = fileService,
        _archiveService = archiveService;

  static const int port = 2910;

  final FileService _fileService;
  final ArchiveService _archiveService;

  HttpServer? _server;
  PathGuard? _guard;
  List<String> _addresses = [];
  bool Function(String password)? _passwordVerifier;
  Future<bool> Function(String password)? _asyncPasswordVerifier;

  bool get isRunning => _server != null;
  String? get rootPath => _guard?.defaultRoot;
  List<String> get addresses => List.unmodifiable(_addresses);
  bool get authRequired => _passwordVerifier != null || _asyncPasswordVerifier != null;

  Future<List<String>> start({
    required String defaultRoot,
    required List<String> knownRoots,
    bool restrictToRoots = false,
    bool Function(String password)? passwordVerifier,
    Future<bool> Function(String password)? asyncPasswordVerifier,
  }) async {
    if (_server != null) await stop();

    _passwordVerifier = passwordVerifier;
    _asyncPasswordVerifier = asyncPasswordVerifier;
    _guard = PathGuard(
      defaultRoot: defaultRoot,
      knownRoots: knownRoots,
      restrictToRoots: restrictToRoots,
    );
    final router = Router()
      ..get('/', _serveUi)
      ..get('/api/info', _apiInfo)
      ..get('/api/list', _apiList)
      ..get('/api/file', _apiFile)
      ..get('/api/thumb', _apiThumb)
      ..get('/api/read', _apiRead)
      ..post('/api/mkdir', _apiMkdir)
      ..post('/api/create', _apiCreate)
      ..post('/api/rename', _apiRename)
      ..post('/api/delete', _apiDelete)
      ..post('/api/write', _apiWrite)
      ..post('/api/zip', _apiZip)
      ..post('/api/unzip', _apiUnzip)
      ..post('/api/upload', _apiUpload);

    final handler = Pipeline()
        .addMiddleware(_corsMiddleware)
        .addMiddleware(_authMiddleware)
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    _addresses = await _localIpv4Addresses();
    return _addresses;
  }

  Future<void> stop() async {
    final server = _server;
    if (server == null) return;
    // Clear state immediately so isRunning flips false before socket close completes.
    _server = null;
    _guard = null;
    _addresses = [];
    _passwordVerifier = null;
    _asyncPasswordVerifier = null;
    try {
      await server.close(force: true);
    } catch (_) {}
  }

  Middleware get _authMiddleware {
    return (Handler inner) {
      return (Request request) async {
        final verifier = _passwordVerifier;
        final asyncVerifier = _asyncPasswordVerifier;
        if (verifier == null && asyncVerifier == null) return inner(request);

        final auth = request.headers['Authorization'];
        if (auth == null || !auth.startsWith('Basic ')) {
          return Response(
            401,
            body: L10nScope.current.apiPasswordRequired,
            headers: {'WWW-Authenticate': 'Basic realm="Cope X Studio"'},
          );
        }

        try {
          final decoded = utf8.decode(base64Decode(auth.substring(6).trim()));
          final password = decoded.contains(':')
              ? decoded.substring(decoded.indexOf(':') + 1)
              : decoded;
          final ok = verifier != null
              ? verifier(password)
              : await asyncVerifier!(password);
          if (!ok) {
            return Response(
              401,
              body: L10nScope.current.apiWrongPassword,
              headers: {'WWW-Authenticate': 'Basic realm="Cope X Studio"'},
            );
          }
        } catch (_) {
          return Response(
            401,
            headers: {'WWW-Authenticate': 'Basic realm="Cope X Studio"'},
          );
        }
        return inner(request);
      };
    };
  }

  Middleware get _corsMiddleware {
    const headers = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
    return (Handler inner) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: headers);
        }
        final response = await inner(request);
        return response.change(headers: headers);
      };
    };
  }

  Response _serveUi(Request request) {
    return Response.ok(
      buildWebUiHtml(),
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  Response _apiInfo(Request request) {
    return _json({
      'root': _guard!.defaultRoot,
      'roots': _guard!.knownRoots,
      'port': port,
      'addresses': _addresses,
      'authRequired': authRequired,
    });
  }

  Response _apiList(Request request) {
    try {
      final pathParam = request.url.queryParameters['path'];
      if (pathParam == '@roots') {
        final entries = _guard!.knownRoots.map((root) {
          return {
            'name': root,
            'path': root,
            'isDir': true,
            'size': null,
            'ext': '',
          };
        }).toList();
        return _json({'path': '@roots', 'entries': entries});
      }

      final showHidden = request.url.queryParameters['showHidden'] == 'true';
      final dirPath = _guard!.resolve(pathParam);
      final entities = _fileService.listDirectory(dirPath, showHidden: showHidden);
      final entries = entities.map((entity) {
        final isDir = entity is Directory;
        int? size;
        if (entity is File) {
          try {
            size = entity.statSync().size;
          } catch (_) {}
        }
        return {
          'name': p.basename(entity.path),
          'path': entity.path,
          'isDir': isDir,
          'size': size,
          'ext': isDir ? '' : p.extension(entity.path).toLowerCase(),
        };
      }).toList();

      return _json({'path': dirPath, 'entries': entries});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiFile(Request request) async {
    try {
      final filePath = _guard!.resolve(request.url.queryParameters['path']);
      if (_fileService.isDirectory(filePath)) {
        return _jsonError(L10nScope.current.apiCannotListFolder, 400);
      }
      final file = File(filePath);
      if (!file.existsSync()) return _jsonError(L10nScope.current.apiFileNotFound, 404);

      final mime = lookupMimeType(filePath) ?? 'application/octet-stream';
      final length = await file.length();
      final download = request.url.queryParameters['download'] == '1';
      final headers = <String, String>{
        'Content-Type': mime,
        'Content-Length': '$length',
      };
      if (download) {
        final filename = p.basename(filePath);
        final encodedFilename = Uri.encodeComponent(filename);
        headers['Content-Disposition'] = 'attachment; filename="$encodedFilename"; filename*=UTF-8\'\'$encodedFilename';
      }
      return Response.ok(file.openRead(), headers: headers);
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiThumb(Request request) async {
    try {
      final filePath = _guard!.resolve(request.url.queryParameters['path']);
      if (_fileService.isDirectory(filePath)) {
        return _jsonError(L10nScope.current.apiCannotFolderThumbnail, 400);
      }
      final bytes = await ThumbnailService.instance.load(filePath);
      if (bytes == null || bytes.isEmpty) {
        return Response(404, body: 'No thumbnail');
      }
      return Response.ok(
        bytes,
        headers: {
          'Content-Type': 'image/png',
          'Content-Length': '${bytes.length}',
          'Cache-Control': 'max-age=3600',
        },
      );
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiRead(Request request) async {
    try {
      final filePath = _guard!.resolve(request.url.queryParameters['path']);
      if (_fileService.isDirectory(filePath)) {
        return _jsonError(L10nScope.current.apiCannotReadFolder, 400);
      }
      final file = File(filePath);
      if (!file.existsSync()) return _jsonError(L10nScope.current.apiFileNotFound, 404);
      if (file.lengthSync() > 2 * 1024 * 1024) {
        return _jsonError(L10nScope.current.apiFileTooLargeEdit, 400);
      }
      final content = await _fileService.readText(filePath);
      return _json({'path': filePath, 'content': content});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiMkdir(Request request) async {
    try {
      final body = await _readJson(request);
      final parent = _guard!.resolve(body['path'] as String?);
      final name = (body['name'] as String?)?.trim();
      if (name == null || name.isEmpty) return _jsonError(L10nScope.current.apiMissingFolderName, 400);
      final folderPath = p.join(parent, name);
      await _fileService.createFolder(folderPath);
      return _json({'path': folderPath});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiCreate(Request request) async {
    try {
      final body = await _readJson(request);
      final parent = _guard!.resolve(body['path'] as String?);
      final name = (body['name'] as String?)?.trim();
      if (name == null || name.isEmpty) return _jsonError(L10nScope.current.apiMissingFileName, 400);
      final filePath = p.join(parent, name);
      await _fileService.createFile(filePath);
      return _json({'path': filePath});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiRename(Request request) async {
    try {
      final body = await _readJson(request);
      final oldPath = _guard!.resolve(body['path'] as String?);
      final newName = (body['newName'] as String?)?.trim();
      if (newName == null || newName.isEmpty) return _jsonError(L10nScope.current.apiMissingNewName, 400);
      final newPath = p.join(p.dirname(oldPath), newName);
      await _fileService.renameEntity(oldPath, newPath);
      return _json({'path': newPath});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiDelete(Request request) async {
    try {
      final body = await _readJson(request);
      final paths = (body['paths'] as List?)?.cast<String>() ?? [];
      if (paths.isEmpty) return _jsonError(L10nScope.current.apiNothingToDelete, 400);
      for (final path in paths) {
        await _fileService.delete(_guard!.resolve(path));
      }
      return _json({'deleted': paths.length});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiWrite(Request request) async {
    try {
      final body = await _readJson(request);
      final filePath = _guard!.resolve(body['path'] as String?);
      final content = body['content'] as String? ?? '';
      if (_fileService.isDirectory(filePath)) {
        return _jsonError(L10nScope.current.apiCannotWriteFolder, 400);
      }
      await _fileService.writeText(filePath, content);
      return _json({'path': filePath});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiZip(Request request) async {
    try {
      final body = await _readJson(request);
      final paths = (body['paths'] as List?)?.cast<String>() ?? [];
      if (paths.isEmpty) return _jsonError(L10nScope.current.apiNothingToZip, 400);

      final resolved = paths.map(_guard!.resolve).toList();
      final parent = _guard!.resolve(body['dest'] as String? ?? p.dirname(resolved.first));
      final baseName = resolved.length == 1
          ? '${p.basenameWithoutExtension(resolved.first)}.zip'
          : 'archive.zip';
      final zipName = _fileService.uniqueName(parent, baseName);
      final zipPath = p.join(parent, zipName);

      await _archiveService.zipPaths(resolved, zipPath);
      return _json({'path': zipPath, 'name': zipName});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiUnzip(Request request) async {
    try {
      final body = await _readJson(request);
      final zipPath = _guard!.resolve(body['path'] as String?);
      if (!FileTypeUtils.isZip(zipPath)) {
        return _jsonError(L10nScope.current.apiNotZipFile, 400);
      }
      final parent = p.dirname(zipPath);
      final folderName = _fileService.uniqueName(
        parent,
        p.basenameWithoutExtension(zipPath),
      );
      final destDir = p.join(parent, folderName);
      await _archiveService.unzipTo(zipPath, destDir);
      return _json({'path': destDir, 'name': folderName});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Response> _apiUpload(Request request) async {
    try {
      final destDir = _guard!.resolve(request.url.queryParameters['path']);
      if (!_fileService.isDirectory(destDir)) {
        return _jsonError(L10nScope.current.apiInvalidDestFolder, 400);
      }

      final filename = request.url.queryParameters['name']?.trim();
      if (filename == null || filename.isEmpty) {
        return _jsonError(L10nScope.current.apiMissingFileNameParam, 400);
      }

      final safeName = p.basename(filename);
      final filePath = p.join(destDir, _fileService.uniqueName(destDir, safeName));
      final sink = File(filePath).openWrite();
      await for (final chunk in request.read()) {
        sink.add(chunk);
      }
      await sink.close();

      return _json({'uploaded': [filePath]});
    } catch (e) {
      return _jsonError('$e');
    }
  }

  Future<Map<String, dynamic>> _readJson(Request request) async {
    final body = await request.readAsString();
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Response _json(Map<String, dynamic> data, [int status = 200]) {
    return Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
  }

  Response _jsonError(String message, [int status = 400]) {
    return _json({'error': message}, status);
  }

  Future<List<String>> _localIpv4Addresses() async {
    final result = <String>[];
    try {
      for (final iface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      )) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) result.add(addr.address);
        }
      }
    } catch (_) {}
    if (result.isEmpty) result.add('127.0.0.1');
    return result;
  }
}
