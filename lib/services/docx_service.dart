import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class DocxService {
  Future<List<String>> readParagraphs(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return readParagraphsFromBytes(bytes);
  }

  List<String> readParagraphsFromBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) {
      throw Exception('Invalid DOCX: missing word/document.xml');
    }

    final xmlContent = utf8.decode(documentFile.content as List<int>);
    final document = XmlDocument.parse(xmlContent);
    final paragraphs = <String>[];

    for (final paragraph in document.findAllElements('w:p')) {
      final buffer = StringBuffer();
      for (final textNode in paragraph.findAllElements('w:t')) {
        buffer.write(textNode.innerText);
      }
      paragraphs.add(buffer.toString());
    }

    if (paragraphs.isEmpty) {
      paragraphs.add('');
    }
    return paragraphs;
  }

  Future<void> saveParagraphs(
    String filePath,
    List<String> paragraphs, {
    List<int>? originalBytes,
  }) async {
    List<int> output;

    if (originalBytes != null) {
      final archive = ZipDecoder().decodeBytes(originalBytes);
      final documentFile = archive.findFile('word/document.xml');
      if (documentFile == null) {
        throw Exception('Invalid DOCX: missing word/document.xml');
      }

      final xmlContent = utf8.decode(documentFile.content as List<int>);
      final document = XmlDocument.parse(xmlContent);
      final body = document.findAllElements('w:body').firstOrNull;
      if (body == null) {
        throw Exception('Invalid DOCX: missing w:body');
      }

      body.children.clear();
      for (final text in paragraphs) {
        body.children.add(_paragraphElement(text));
      }
      body.children.add(_sectionProperties());

      final updatedXml = document.toXmlString(pretty: false);
      archive.removeFile(documentFile);
      archive.addFile(
        ArchiveFile('word/document.xml', updatedXml.length, updatedXml.codeUnits),
      );
      output = ZipEncoder().encode(archive)!;
    } else {
      output = _createMinimalDocx(paragraphs);
    }

    await File(filePath).writeAsBytes(output);
  }

  XmlElement _paragraphElement(String text) {
    return XmlElement(
      XmlName('w:p'),
      [],
      [
        XmlElement(
          XmlName('w:r'),
          [],
          [
            XmlElement(
              XmlName('w:t'),
              [XmlAttribute(XmlName('xml:space'), 'preserve')],
              [XmlText(text)],
            ),
          ],
        ),
      ],
    );
  }

  XmlElement _sectionProperties() {
    return XmlDocument.parse(
      '<w:sectPr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:pgSz w:w="11906" w:h="16838"/>'
      '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>'
      '</w:sectPr>',
    ).rootElement;
  }

  List<int> _createMinimalDocx(List<String> paragraphs) {
    final bodyChildren = StringBuffer();
    for (final text in paragraphs) {
      final escaped = _escapeXml(text);
      bodyChildren.write(
        '<w:p><w:r><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>',
      );
    }
    bodyChildren.write(
      '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
      '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>'
      '</w:sectPr>',
    );

    final documentXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>$bodyChildren</w:body></w:document>';

    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    const rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    const docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';

    final archive = Archive()
      ..addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, contentTypes.codeUnits))
      ..addFile(ArchiveFile('_rels/.rels', rels.length, rels.codeUnits))
      ..addFile(ArchiveFile('word/_rels/document.xml.rels', docRels.length, docRels.codeUnits))
      ..addFile(ArchiveFile('word/document.xml', documentXml.length, documentXml.codeUnits));

    return ZipEncoder().encode(archive)!;
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
