import 'dart:io';

import 'package:abdulmalik_erp/src/server/db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v9 migration normalizes stored Saudi phone numbers without changing legacy Egyptian numbers', () async {
    final dir = await Directory.systemTemp.createTemp('abdulmalik_db_migration');
    final path = '${dir.path}/shop.db';

    var db = AppDb.open(path);
    final now = DateTime.utc(2026, 1, 1).toIso8601String();
    for (final entry in const {
      'saudi_international': '966501234567',
      'saudi_local_without_zero': '501234567',
      'saudi_international_00': '00966501234567',
      'saudi_local': '0501234567',
      'egypt_legacy': '01001234567',
    }.entries) {
      db.execute(
        'INSERT INTO customers(id, name, phone, phone_norm, created_at, updated_at) VALUES(?, ?, ?, ?, ?, ?)',
        [entry.key, entry.key, entry.value, entry.value, now, now],
      );
    }

    // Simulate a database last opened by schema version 8.
    db.raw.userVersion = 8;
    db.close();

    db = AppDb.open(path);
    final rows = db.select('SELECT id, phone_norm FROM customers ORDER BY id');
    final normalized = {for (final row in rows) row['id']: row['phone_norm']};
    expect(normalized, {
      'egypt_legacy': '01001234567',
      'saudi_international': '0501234567',
      'saudi_international_00': '0501234567',
      'saudi_local': '0501234567',
      'saudi_local_without_zero': '0501234567',
    });

    db.close();
    await dir.delete(recursive: true);
  });
}
