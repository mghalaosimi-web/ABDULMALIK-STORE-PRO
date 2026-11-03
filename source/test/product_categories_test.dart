import 'dart:io';

import 'package:abdulmalik_erp/src/server/db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('category sibling names are unique and product names cannot repeat in a category', () async {
    final dir = await Directory.systemTemp.createTemp('abdulmalik_categories');
    final db = AppDb.open('${dir.path}/shop.db');
    final now = DateTime.utc(2026, 1, 1).toIso8601String();

    db.execute(
      'INSERT INTO product_categories(id, name, normalized_name, parent_id, created_at) VALUES(?, ?, ?, NULL, ?)',
      ['phones', 'هواتف', 'هواتف', now],
    );
    expect(
      () => db.execute(
        'INSERT INTO product_categories(id, name, normalized_name, parent_id, created_at) VALUES(?, ?, ?, NULL, ?)',
        ['phones-duplicate', ' هواتف ', 'هواتف', now],
      ),
      throwsA(anything),
    );

    db.execute(
      'INSERT INTO products(id, name, category_id, created_at, updated_at) VALUES(?, ?, ?, ?, ?)',
      ['p1', 'Galaxy A17', 'phones', now, now],
    );
    expect(
      () => db.execute(
        'INSERT INTO products(id, name, category_id, created_at, updated_at) VALUES(?, ?, ?, ?, ?)',
        ['p2', ' galaxy a17 ', 'phones', now, now],
      ),
      throwsA(anything),
    );

    db.close();
    await dir.delete(recursive: true);
  });
}
