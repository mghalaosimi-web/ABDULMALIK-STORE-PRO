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

  test('v10 backfills legacy accessory categories and always creates the accessories root', () async {
    final dir = await Directory.systemTemp.createTemp('abdulmalik_category_migration');
    final path = '${dir.path}/shop.db';

    var db = AppDb.open(path);
    // Rewind this temporary database to the v9 schema and insert a legacy product.
    db.execute('DROP TRIGGER IF EXISTS trg_products_no_duplicate_insert');
    db.execute('DROP TRIGGER IF EXISTS trg_products_no_duplicate_update');
    db.execute('DROP INDEX IF EXISTS idx_products_category_id');
    db.execute('ALTER TABLE products DROP COLUMN category_id');
    db.execute('DROP TABLE product_categories');
    db.raw.userVersion = 9;
    db.execute(
      'INSERT INTO products(id, name, category, created_at, updated_at) VALUES(?, ?, ?, ?, ?)',
      ['legacy-accessory', 'شاحن قديم', 'الأكسسوارات::شواحن', DateTime.utc(2026).toIso8601String(), DateTime.utc(2026).toIso8601String()],
    );
    db.close();

    db = AppDb.open(path);
    final row = db.selectOne(
      'SELECT p.category_id, c.name, c.parent_id FROM products p JOIN product_categories c ON c.id = p.category_id WHERE p.id = ?',
      ['legacy-accessory'],
    );
    expect(row, isNotNull);
    expect(row!['name'], 'شواحن');
    expect(row['parent_id'], isNotNull);
    expect(
      db.selectOne("SELECT id FROM product_categories WHERE name = 'الأكسسوارات' AND parent_id IS NULL"),
      isNotNull,
    );

    db.close();
    await dir.delete(recursive: true);
  });
}
