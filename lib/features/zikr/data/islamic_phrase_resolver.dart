class IslamicPhraseResolver {
  const IslamicPhraseResolver._();

  static String normalize(String text) {
    var s = text.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\-–]'), ' ');
    s = s.replaceAll(RegExp(r"['’`]"), '');
    s = s.replaceAll(RegExp(r'[^\w\s]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static const Map<String, String> _phraseMap = {
    'ayat e kareem': 'آية الكريمة',
    'ayat e karima': 'آية الكريمة',
    'ayatekarima': 'آية الكريمة',
    'ayat e kareema': 'آية الكريمة',
    'subhanallah': 'سبحان الله',
    'subhan allah': 'سبحان الله',
    'alhamdulillah': 'الحمد لله',
    'alhamdu lillah': 'الحمد لله',
    'allahu akbar': 'الله أكبر',
    'allah hu akbar': 'الله أكبر',
    'astaghfirullah': 'أستغفر الله',
    'astagfirullah': 'أستغفر الله',
    'astaghfir allah': 'أستغفر الله',
    'la ilaha illallah': 'لا إله إلا الله',
    'la ilaha illa allah': 'لا إله إلا الله',
    'la hawla wala quwwata illa billah': 'لا حول ولا قوة إلا بالله',
    'la hawla wa la quwwata illa billah': 'لا حول ولا قوة إلا بالله',
    'subhanallahi wa bihamdihi': 'سبحان الله وبحمده',
    'subhanallah wa bihamdihi': 'سبحان الله وبحمده',
    'subhanallahil azeem': 'سبحان الله العظيم',
    'subhanallah al azeem': 'سبحان الله العظيم',
    'hasbunallahu wa nimal wakeel': 'حسبنا الله ونعم الوكيل',
    'allahumma salli ala muhammad': 'اللهم صل على محمد',
    'allahumma salli ala sayyidina muhammad': 'اللهم صل على محمد',
    'bismillah': 'بسم الله',
    'bismillahir rahmanir raheem': 'بسم الله الرحمن الرحيم',
  };

  static String? resolve(String text) {
    final key = normalize(text);
    return _phraseMap[key];
  }
}
