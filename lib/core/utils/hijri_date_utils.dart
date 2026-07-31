class HijriDateUtils {
  HijriDateUtils._();

  static const List<String> _hijriMonths = [
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  /// Calculates approximate Hijri date from Gregorian DateTime
  static String formatHijriDate(DateTime date) {
    int day = date.day;
    int month = date.month;
    int year = date.year;

    if (month < 3) {
      year -= 1;
      month += 12;
    }

    int a = (year / 100).floor();
    int b = 2 - a + (a / 4).floor();
    int jd =
        (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524;

    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    int j =
        (((10985 - l) / 5316).floor()) * ((50 * l / 17719).floor()) +
        ((l / 5670).floor()) * ((43 * l / 15238).floor());
    l =
        l -
        (((30 - j) / 15).floor()) * ((17719 * j / 50).floor()) -
        ((j / 30).floor()) * ((15238 * j / 43).floor()) +
        29;
    int hMonth = ((24 * l / 709).floor());
    int hDay = l - ((709 * hMonth / 24).floor());
    int hYear = 30 * n + j - 30;

    if (hMonth < 1) hMonth = 1;
    if (hMonth > 12) hMonth = 12;
    if (hDay < 1) hDay = 1;

    String monthName = _hijriMonths[hMonth - 1];
    return '$hDay $monthName $hYear';
  }
}
