import 'package:abdulmalik_erp/src/core/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('Saudi riyal formatting', () {
    setUp(() => Intl.defaultLocale = 'ar');

    test('formats minor units as Saudi riyals in Arabic', () {
      expect(money(125050), '1,250.5 ر.س');
      expect(money(100), '1 ر.س');
    });

    test('formats Saudi riyals in English', () {
      Intl.defaultLocale = 'en';
      expect(money(125050), 'SAR 1,250.5');
    });

    test('parses Saudi riyal labels and Arabic digits as minor units', () {
      expect(parseMoney('١٬٢٥٠٫٥ ر.س'), 125050);
      expect(parseMoney('SAR 2,500.75'), 250075);
    });

    test('validates Saudi identity and residency numbers while retaining legacy Egyptian IDs', () {
      expect(isValidNationalId('١٠٩٨٧٦٥٤٣٢'), isTrue);
      expect(isValidNationalId('۱۰۹۸۷۶۵۴۳۲'), isTrue);
      expect(isValidNationalId('2098765432'), isTrue);
      expect(isValidNationalId('29001011234567'), isTrue);
      expect(isValidNationalId('123'), isFalse);
      expect(isValidNationalId('3098765432'), isFalse);
    });
  });
}
