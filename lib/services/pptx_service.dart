import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cope_x_studio/models/editor_tab.dart';
import 'package:xml/xml.dart';

class PptxService {
  Future<List<PptxSlideData>> loadSlides(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return loadSlidesFromBytes(bytes);
  }

  List<PptxSlideData> loadSlidesFromBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final slideFiles = archive.files
        .where((f) => RegExp(r'ppt/slides/slide\d+\.xml').hasMatch(f.name))
        .toList()
      ..sort((a, b) => _slideNumber(a.name).compareTo(_slideNumber(b.name)));

    final mediaFiles = <String, Uint8List>{};
    for (final file in archive.files) {
      if (file.name.startsWith('ppt/media/') && file.isFile) {
        mediaFiles[file.name] = Uint8List.fromList(file.content as List<int>);
      }
    }

    final slides = <PptxSlideData>[];
    for (var i = 0; i < slideFiles.length; i++) {
      final slideFile = slideFiles[i];
      final xmlContent = utf8.decode(slideFile.content as List<int>);
      final document = XmlDocument.parse(xmlContent);
      final texts = <String>[];

      for (final textNode in document.findAllElements('a:t')) {
        final text = textNode.innerText.trim();
        if (text.isNotEmpty) {
          texts.add(text);
        }
      }

      Uint8List? imageBytes;
      for (final blip in document.findAllElements('a:blip')) {
        final embed = blip.getAttribute('r:embed');
        if (embed == null) continue;
        final relsPath = slideFile.name.replaceAll(
          RegExp(r'slides/[^/]+\.xml$'),
          'slides/_rels/${_basename(slideFile.name)}.rels',
        );
        final relsFile = archive.findFile(relsPath);
        if (relsFile == null) continue;

        final relsDoc = XmlDocument.parse(
          utf8.decode(relsFile.content as List<int>),
        );
        for (final rel in relsDoc.findAllElements('Relationship')) {
          if (rel.getAttribute('Id') == embed) {
            final target = rel.getAttribute('Target');
            if (target != null) {
              final mediaPath = 'ppt/${target.replaceAll('../', '')}';
              imageBytes = mediaFiles[mediaPath];
              break;
            }
          }
        }
        if (imageBytes != null) break;
      }

      slides.add(
        PptxSlideData(
          index: i + 1,
          texts: texts.isEmpty ? ['(Slide trống)'] : texts,
          imageBytes: imageBytes?.toList(),
        ),
      );
    }

    if (slides.isEmpty) {
      slides.add(const PptxSlideData(index: 1, texts: ['Không có slide']));
    }
    return slides;
  }

  int _slideNumber(String path) {
    final match = RegExp(r'slide(\d+)\.xml').firstMatch(path);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  String _basename(String path) => path.split('/').last;
}
