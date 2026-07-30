String formatCount(int value) {
  final digits = value.toString();
  final formatted = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final positionFromEnd = digits.length - index;
    formatted.write(digits[index]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      formatted.write(',');
    }
  }
  return formatted.toString();
}
