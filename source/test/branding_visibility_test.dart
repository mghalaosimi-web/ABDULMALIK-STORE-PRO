import 'package:abdulmalik_erp/src/core/branding_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrandingVisibility', () {
    test('remains hidden through January 3, 2027', () {
      expect(BrandingVisibility.isVisibleAt(DateTime(2026, 11, 4)), isFalse);
      expect(
        BrandingVisibility.isVisibleAt(DateTime(2026, 12, 31, 23, 59)),
        isFalse,
      );
      expect(
        BrandingVisibility.isVisibleAt(DateTime(2027, 1, 3, 23, 59)),
        isFalse,
      );
    });

    test('becomes visible automatically on January 4, 2027', () {
      expect(BrandingVisibility.isVisibleAt(DateTime(2027, 1, 4)), isTrue);
      expect(BrandingVisibility.isVisibleAt(DateTime(2027, 1, 4, 12)), isTrue);
    });
  });
}
