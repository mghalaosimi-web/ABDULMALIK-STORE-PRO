import 'package:flutter_test/flutter_test.dart';

import 'package:abdulmalik_erp/src/core/product_sections.dart';

void main() {
  group('accessory product categories', () {
    test('stores accessory categories with an internal namespace', () {
      expect(storedAccessoriesCategory('سماعات'), 'الأكسسوارات::سماعات');
    });

    test('recognizes and displays accessory categories without the namespace', () {
      const stored = 'الأكسسوارات::حماية الشاشة';
      expect(isAccessoriesCategory(stored), isTrue);
      expect(visibleProductCategory(stored), 'حماية الشاشة');
    });

    test('puts recently used custom categories before defaults without duplicates', () {
      final suggestions = accessoryCategorySuggestions([
        'الأكسسوارات::أغطية مخصصة',
        'المخزون العام',
        'الأكسسوارات::شواحن',
        'الأكسسوارات::شواحن',
      ]);

      expect(suggestions.take(2), ['أغطية مخصصة', 'شواحن']);
      expect(suggestions.toSet().length, suggestions.length);
      expect(suggestions, containsAll(accessoriesCategories));
    });

    test('does not classify regular inventory categories as accessories', () {
      expect(isAccessoriesCategory('قطع غيار'), isFalse);
      expect(visibleProductCategory('قطع غيار'), 'قطع غيار');
      expect(isAccessoriesCategory(null), isFalse);
    });
  });
}
