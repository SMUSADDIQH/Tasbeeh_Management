import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/zikr/data/islamic_phrase_resolver.dart';

void main() {
  group('IslamicPhraseResolver Unit Tests', () {
    test('1. "subhanallah" resolves immediately to "سبحان الله"', () {
      final result = IslamicPhraseResolver.resolve('subhanallah');
      expect(result, 'سبحان الله');
    });

    test('2. Alias "subhan allah" resolves identically', () {
      final result = IslamicPhraseResolver.resolve('subhan allah');
      expect(result, 'سبحان الله');
    });

    test('3. Other listed Islamic aliases resolve correctly', () {
      expect(IslamicPhraseResolver.resolve('alhamdulillah'), 'الحمد لله');
      expect(IslamicPhraseResolver.resolve('alhamdu lillah'), 'الحمد لله');
      expect(IslamicPhraseResolver.resolve('allahu akbar'), 'الله أكبر');
      expect(IslamicPhraseResolver.resolve("allah hu akbar"), 'الله أكبر');
      expect(IslamicPhraseResolver.resolve('astaghfirullah'), 'أستغفر الله');
      expect(IslamicPhraseResolver.resolve('astagfirullah'), 'أستغفر الله');
      expect(IslamicPhraseResolver.resolve('astaghfir allah'), 'أستغفر الله');
      expect(
        IslamicPhraseResolver.resolve('la ilaha illallah'),
        'لا إله إلا الله',
      );
      expect(
        IslamicPhraseResolver.resolve('la hawla wala quwwata illa billah'),
        'لا حول ولا قوة إلا بالله',
      );
      expect(
        IslamicPhraseResolver.resolve('subhanallahi wa bihamdihi'),
        'سبحان الله وبحمده',
      );
      expect(
        IslamicPhraseResolver.resolve('subhanallahil azeem'),
        'سبحان الله العظيم',
      );
      expect(
        IslamicPhraseResolver.resolve("hasbunallahu wa nimal wakeel"),
        'حسبنا الله ونعم الوكيل',
      );
      expect(
        IslamicPhraseResolver.resolve('allahumma salli ala muhammad'),
        'اللهم صل على محمد',
      );
      expect(
        IslamicPhraseResolver.resolve('bismillahir rahmanir raheem'),
        'بسم الله الرحمن الرحيم',
      );
    });

    test('4. Local phrase matching handles punctuation, spaces and casing', () {
      expect(IslamicPhraseResolver.resolve("  Subhan'Allah--  "), 'سبحان الله');
      expect(IslamicPhraseResolver.resolve("ALHAMDU... LILLAH!"), 'الحمد لله');
    });

    test('5. Unknown English text returns null (fallback to ML Kit)', () {
      expect(IslamicPhraseResolver.resolve('custom random text'), isNull);
    });
  });
}
