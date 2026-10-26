/// 한글 문장이 낱말 중간에서 끊기지 않게 하는 도우미
///
/// Flutter는 한글을 글자 단위로 줄바꿈해서 "있어" / "요"처럼 끊길 수 있다.
/// 붙어 있는 한글·숫자·영문 글자 사이에 단어 결합자(U+2060)를 넣어 띄어쓰기에서만 줄이 바뀌게 한다.
/// ("7시에"가 "7" / "시에"로 끊기는 것도 막는다)
extension KoreanWordWrap on String {
  String get keepWords {
    final out = StringBuffer();
    int? previous;
    for (final rune in runes) {
      if (previous != null && _isWordChar(previous) && _isWordChar(rune)) {
        out.write('\u2060');
      }
      out.writeCharCode(rune);
      previous = rune;
    }
    return out.toString();
  }

  static bool _isWordChar(int rune) =>
      (rune >= 0xAC00 && rune <= 0xD7A3) || // 한글 음절
      (rune >= 0x30 && rune <= 0x39) || // 숫자
      (rune >= 0x41 && rune <= 0x5A) ||
      (rune >= 0x61 && rune <= 0x7A);
}
