import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:path/path.dart' as p;

class LanguageDetector {
  static String detect(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return switch (ext) {
      '.dart' => 'dart',
      '.js' || '.mjs' || '.cjs' => 'javascript',
      '.ts' || '.tsx' => 'typescript',
      '.jsx' => 'javascript',
      '.json' => 'json',
      '.py' => 'python',
      '.java' => 'java',
      '.go' => 'go',
      '.php' => 'php',
      '.sql' => 'sql',
      '.md' || '.markdown' => 'markdown',
      '.yaml' || '.yml' => 'yaml',
      '.xml' || '.html' || '.htm' => 'xml',
      '.css' => 'xml',
      '.sh' || '.bash' => 'bash',
      '.rs' => 'rust',
      '.c' || '.h' => 'c',
      '.cpp' || '.hpp' || '.cc' => 'cpp',
      '.cs' => 'csharp',
      '.swift' => 'swift',
      '.kt' || '.kts' => 'kotlin',
      _ => 'plaintext',
    };
  }

  static dynamic modeFor(String language) {
    return switch (language) {
      'dart' => dart,
      'javascript' => javascript,
      'typescript' => typescript,
      'json' => json,
      'python' => python,
      'java' => java,
      'go' => go,
      'php' => php,
      'sql' => sql,
      'markdown' => markdown,
      'yaml' => yaml,
      'xml' => xml,
      _ => null,
    };
  }
}
