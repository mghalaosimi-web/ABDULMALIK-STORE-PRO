const accessoriesCategoryPrefix = 'الأكسسوارات::';

const accessoriesCategories = <String>[
  'أغطية وحافظات',
  'سماعات',
  'شواحن',
  'كابلات',
  'حماية الشاشة',
  'حوامل',
  'بطاقات ذاكرة',
  'بطاريات وقطع',
  'أخرى',
];

bool isAccessoriesCategory(String? value) =>
    value != null && value.startsWith(accessoriesCategoryPrefix);

String visibleProductCategory(String? value) {
  if (isAccessoriesCategory(value)) {
    return value!.substring(accessoriesCategoryPrefix.length);
  }
  return value ?? '';
}

String storedAccessoriesCategory(String value) =>
    '$accessoriesCategoryPrefix${value.trim()}';

/// اقتراحات تصنيفات الأكسسوارات: التصنيفات المستخدمة حديثاً أولاً، ثم الافتراضية دون تكرار.
List<String> accessoryCategorySuggestions(Iterable<String> storedCategories) {
  final recent = storedCategories
      .where(isAccessoriesCategory)
      .map(visibleProductCategory)
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList();
  return [
    ...recent,
    ...accessoriesCategories.where((category) => !recent.contains(category)),
  ];
}
