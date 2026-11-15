/// Lightweight estimate: three ASCII characters, one non-ASCII BMP character,
/// or half a supplementary character per token. Count Unicode scalars so CJK
/// and emoji do not inherit the much cheaper ASCII estimate.
int estimateTokens(String text) {
  var units = 0;
  for (final rune in text.runes) {
    units += rune <= 0x7F ? 1 : (rune <= 0xFFFF ? 3 : 6);
  }
  return (units + 2) ~/ 3;
}
