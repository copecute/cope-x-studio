/// Mã hóa văn bản phổ biến khi đọc/ghi file.
class TextEncoding {
  const TextEncoding({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  static const utf8 = TextEncoding(id: 'utf-8', label: 'utf-8');
  static const iso88591 = TextEncoding(id: 'iso-8859-1', label: '8859-1 (Western)');
  static const iso88592 = TextEncoding(id: 'iso-8859-2', label: '8859-2 (Central/Eastern European)');
  static const windows1250 = TextEncoding(id: 'windows-1250', label: 'Windows-1250 (Central/Eastern European)');
  static const windows1251 = TextEncoding(id: 'windows-1251', label: 'Windows-1251 (Cyrillic)');
  static const iso88599 = TextEncoding(id: 'iso-8859-9', label: '8859-9 (Turkish)');
  static const iso88595 = TextEncoding(id: 'iso-8859-5', label: '8859-5 (Latin/Cyrillic)');
  static const big5 = TextEncoding(id: 'big5', label: 'Big 5 (Traditional Chinese)');
  static const gb2312 = TextEncoding(id: 'gb2312', label: 'GB 2312 (Simplified Chinese)');
  static const gbk = TextEncoding(id: 'gbk', label: 'GBK (Simplified Chinese)');
  static const shiftJis = TextEncoding(id: 'shift_jis', label: 'Shift-JIS (Japanese)');
  static const iso2022Jp = TextEncoding(id: 'iso-2022-jp', label: 'iso-2022-jp (Japanese)');
  static const eucKr = TextEncoding(id: 'euc-kr', label: 'euc-kr (Korean)');
  static const iso88597 = TextEncoding(id: 'iso-8859-7', label: '8859-7 (Greek)');
  static const iso885913 = TextEncoding(id: 'iso-8859-13', label: '8859-13 (Baltic)');
  static const iso88594 = TextEncoding(id: 'iso-8859-4', label: 'ISO-8859-4 (North European)');
  static const windows1257 = TextEncoding(id: 'windows-1257', label: 'Windows-1257 (Baltic)');

  static const values = [
    utf8,
    iso88591,
    iso88592,
    windows1250,
    windows1251,
    iso88599,
    iso88595,
    big5,
    gb2312,
    gbk,
    shiftJis,
    iso2022Jp,
    eucKr,
    iso88597,
    iso885913,
    iso88594,
    windows1257,
  ];

  static TextEncoding fromId(String? id) {
    if (id == null || id.isEmpty) return utf8;
    for (final item in values) {
      if (item.id == id) return item;
    }
    return utf8;
  }
}
