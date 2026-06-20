import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:cope_x_studio/models/text_encoding.dart';
import 'package:dart3_big5/big5.dart' as big5_codec;

class TextEncodingService {
  TextEncodingService._();
  static final TextEncodingService instance = TextEncodingService._();

  Encoding? _encodingFor(TextEncoding encoding) {
    return switch (encoding.id) {
      'utf-8' => utf8,
      'iso-8859-1' => latin1,
      'iso-8859-2' => latin2,
      'windows-1250' => windows1250,
      'windows-1251' => windows1251,
      'iso-8859-9' => latin5,
      'iso-8859-5' => latinCyrillic,
      'gb2312' || 'gbk' => gbk,
      'shift_jis' => shiftJis,
      'iso-2022-jp' => eucJp,
      'euc-kr' => eucKr,
      'iso-8859-7' => latinGreek,
      'iso-8859-13' => latin7,
      'iso-8859-4' => latin4,
      'windows-1257' => windows1257,
      _ => null,
    };
  }

  String decode(List<int> bytes, TextEncoding encoding) {
    if (bytes.isEmpty) return '';
    try {
      if (encoding.id == 'big5') {
        return big5_codec.Big5.decode(bytes);
      }
      if (encoding.id == 'utf-8') {
        return utf8.decode(bytes, allowMalformed: true);
      }
      final codec = _encodingFor(encoding);
      if (codec == null) {
        return utf8.decode(bytes, allowMalformed: true);
      }
      return codec.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  List<int> encode(String text, TextEncoding encoding) {
    try {
      if (encoding.id == 'big5') {
        return big5_codec.Big5.encode(text);
      }
      final codec = _encodingFor(encoding) ?? utf8;
      return codec.encode(text);
    } catch (_) {
      return utf8.encode(text);
    }
  }
}
