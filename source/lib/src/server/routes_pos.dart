part of 'api_server.dart';

const _cashStaff = {'owner', 'reception'};

/// أقصى عدد حركات بيظهر في شاشة الدرج (الإجماليات بتتحسب من كل الحركات).
const _cashMovesShown = 200;

/// أنواع حركات الخزنة. الموجب داخل للخزنة والسالب خارج.
const cashMoveTypes = {
  'sale': 'بيع',
  'sale_refund': 'مرتجع بيع',
  'repair_payment': 'دفعة صيانة',
  'repair_refund': 'مرتجع صيانة',
  'customer_payment': 'تحصيل من عميل',
  'expense': 'مصروف',
  'deposit': 'إيداع في الخزنة',
  'withdraw': 'سحب من الخزنة',
  'supplier_payment': 'دفعة لمورد',
  'purchase_payment': 'فاتورة شراء',
  'used_purchase': 'شراء جهاز مستعمل',
  'service': 'خدمات ومحافظ',
  'wallet_topup': 'تغذية محفظة',
  'wallet_withdraw': 'سحب من محفظة',
};

const defaultExpenseCategories = ['إيجار', 'كهرباء', 'رواتب', 'بضاعة', 'مأكولات ومشروبات', 'مواصلات', 'إنترنت وهاتف', 'تصليحات للمحل', 'أخرى'];

extension _PosRoutes on AbdulmalikErpServer {
  void _registerPosRoutes(Router r) {
    r.get('/api/products', _authed(_listProducts));
    r.get('/api/products/lookup', _authed(_lookupProduct));
    r.get('/api/products/categories', _authed(_productCategories));
    r.post('/api/products/categories', _authed(_createProductCategory, only: _cashStaff));
    r.post('/api/products', _authed(_createProduct, only: _cashStaff));
    r.post('/api/products/barcode', _authed((req, u) => {'barcode': _newBarcode()}, only: _cashStaff));
    r.post('/api/products/import', _authed(_importProducts, only: {'owner'}));
    r.patch('/api/products/<id>', _authed(_updateProduct, only: _cashStaff));
    r.post('/api/products/<id>/adjust', _authed(_adjustStock, only: {'owner', 'reception'}));
    r.get('/api/products/<id>/moves', _authed(_productMoves, only: _cashStaff));

    r.post('/api/customers', _authed(_createCustomer, only: _cashStaff));
    r.get('/api/customers/<id>/ledger', _authed(_customerLedger, only: _cashStaff));
    r.post('/api/customers/<id>/payments', _authed(_collectFromCustomer, only: _cashStaff));

    r.post('/api/sales', _authed(_createSale, only: _cashStaff));
    r.get('/api/sales', _authed(_listSales, only: _cashStaff));
    r.get('/api/sales/<id>', _authed(_getSale, only: _cashStaff));
    r.post('/api/sales/<id>/return', _authed(_returnSale, only: _cashStaff));

    r.get('/api/cash/current', _authed(_cashCurrent, only: _cashStaff));
    r.post('/api/cash/moves', _authed(_addCashMove, only: _cashStaff));
    r.post('/api/cash/close', _authed(_closeCash, only: _cashStaff));
    r.get('/api/cash/sessions', _authed(_cashSessions, only: {'owner'}));
  }

  // ================================================================ products

  Map<String, Object?> _productJson(Map<String, Object?> p) => {
        'id': p['id'],
        'name': p['name'],
        'barcode': p['barcode'],
        'category': p['category'],
        'costCents': p['cost_cents'],
        'priceCents': p['price_cents'],
        'qty': p['qty'],
        'lowStock': p['low_stock'],
        'trackStock': p['track_stock'] == 1,
        'serialized': p['serialized'] == 1,
        'warrantyMonths': p['warranty_months'] ?? 0,
        'active': p['active'] == 1,
        'notes': p['notes'],
        'imageFileId': p['image_file_id'],
        'updatedAt': p['updated_at'],
      };

  Object? _listProducts(Request req, AuthUser u) {
    final qp = req.url.queryParameters;
    final q = (qp['q'] ?? '').trim();
    final where = <String>['active = 1'];
    final params = <Object?>[];
    if (q.isNotEmpty) {
      where.add('(name LIKE ? OR barcode = ? OR category LIKE ?)');
      params.addAll(['%$q%', q, '%$q%']);
    }
    if ((qp['category'] ?? '').isNotEmpty) {
      where.add('category = ?');
      params.add(qp['category']);
    }
    // افصل الأكسسوارات عن المخزون العام دون تغيير بنية قاعدة البيانات أو كسر الأصناف القديمة.
    if (qp['section'] == 'accessories') {
      where.add("category LIKE 'الأكسسوارات::%'");
    } else if (qp['section'] == 'general') {
      where.add("(category IS NULL OR category NOT LIKE 'الأكسسوارات::%')");
    }
    if (qp['low'] == '1') where.add('track_stock = 1 AND qty <= low_stock');
    if (qp['inactive'] == '1') where[0] = 'active = 0';
    final limit = (int.tryParse(qp['limit'] ?? '') ?? 100).clamp(1, 500);
    final offset = int.tryParse(qp['offset'] ?? '') ?? 0;
    final orderBy = qp['section'] == 'accessories'
        ? 'created_at DESC, name COLLATE NOCASE'
        : 'name COLLATE NOCASE';
    final rows = db.select(
      'SELECT * FROM products WHERE ${where.join(' AND ')} ORDER BY $orderBy LIMIT ? OFFSET ?',
      [...params, limit, offset],
    );
    final summaryWhere = <String>['active = 1'];
    if (qp['section'] == 'accessories') {
      summaryWhere.add("category LIKE 'الأكسسوارات::%'");
    } else if (qp['section'] == 'general') {
      summaryWhere.add("(category IS NULL OR category NOT LIKE 'الأكسسوارات::%')");
    }
    final totals = db.selectOne(
      'SELECT COUNT(*) AS c, COALESCE(SUM(CASE WHEN track_stock = 1 AND qty > 0 THEN qty * cost_cents ELSE 0 END), 0) AS value, '
      'COALESCE(SUM(CASE WHEN track_stock = 1 AND qty <= low_stock THEN 1 ELSE 0 END), 0) AS low '
      'FROM products WHERE ${summaryWhere.join(' AND ')}',
    )!;
    return {
      'products': rows.map(_productJson).toList(),
      'count': totals['c'],
      'lowCount': totals['low'],
      if (u.isOwner) 'stockValueCents': totals['value'],
    };
  }

  /// الرمز الشريطي لصنف، أو رقم IMEI لجهاز موجود في المخزون (يؤدي مسح رقم IMEI في نقطة البيع إلى إضافته مباشرة).
  Object? _lookupProduct(Request req, AuthUser u) {
    final code = latinDigits((req.url.queryParameters['barcode'] ?? '').trim());
    if (code.isEmpty) return {'product': null};
    final p = db.selectOne('SELECT * FROM products WHERE barcode = ? AND active = 1', [code]);
    if (p != null) return {'product': _productJson(p)};
    final unit = db.selectOne("${_StockRoutes._unitSelect} WHERE (x.imei = ? OR x.imei2 = ?) AND x.status = 'in_stock'", [code, code]);
    if (unit == null) return {'product': null};
    return {
      'product': _productJson(db.selectOne('SELECT * FROM products WHERE id = ?', [unit['product_id']])!),
      'unit': _unitJson(unit),
    };
  }

  Object? _productCategories(Request req, AuthUser u) {
    final rows = db.select(
      'SELECT id, name, parent_id AS parentId FROM product_categories ORDER BY COALESCE(parent_id, id), normalized_name',
    );
    // الحقل النصي القديم يبقى متاحاً للعملاء الحاليين.
    final legacy = db.select(
      "SELECT category, MAX(updated_at) AS latest FROM products WHERE category IS NOT NULL AND category <> '' AND active = 1 GROUP BY category ORDER BY latest DESC, category COLLATE NOCASE",
    );
    return {'categories': legacy.map((r) => r['category']).toList(), 'tree': rows};
  }

  Future<Object?> _createProductCategory(Request req, AuthUser u) async {
    final body = await _body(req);
    final name = _requiredText(body, 'name', 'اسم التصنيف').trim();
    if (name.length > 80 || name.contains('::')) throw ApiError(400, 'اسم التصنيف غير صالح');
    final parentId = _optionalText(body, 'parentId');
    if (parentId != null && db.selectOne('SELECT id FROM product_categories WHERE id = ?', [parentId]) == null) {
      throw ApiError(404, 'التصنيف الرئيسي غير موجود');
    }
    final normalized = name.toLowerCase();
    final duplicate = db.selectOne(
      "SELECT id FROM product_categories WHERE COALESCE(parent_id, '') = COALESCE(?, '') AND normalized_name = ?",
      [parentId, normalized],
    );
    if (duplicate != null) throw ApiError(409, 'هذا التصنيف موجود بالفعل في المستوى نفسه');
    final id = _uuid.v4();
    db.execute('INSERT INTO product_categories(id, name, normalized_name, parent_id, created_at) VALUES(?, ?, ?, ?, ?)',
      [id, name, normalized, parentId, nowIso()]);
    return {'category': {'id': id, 'name': name, 'parentId': parentId}};
  }


  void _assertUniqueProductName(String name, String? categoryId, {String? exceptId}) {
    if (categoryId == null) return;
    final duplicate = db.selectOne(
      'SELECT id FROM products WHERE category_id = ? AND lower(trim(name)) = lower(trim(?)) AND (? IS NULL OR id <> ?) LIMIT 1',
      [categoryId, name, exceptId, exceptId],
    );
    if (duplicate != null) throw ApiError(409, 'يوجد صنف بالاسم نفسه داخل هذا التصنيف؛ غيّر الاسم أو اختر التصنيف الصحيح');
  }

  String? _ensureCategoryForValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split('::').map((part) => part.trim()).toList();
    if (parts.any((part) => part.isEmpty || part.length > 80)) throw ApiError(400, 'مسار التصنيف غير صالح');
    String? parentId;
    for (final name in parts) {
      final normalized = name.toLowerCase();
      final found = db.selectOne(
        "SELECT id FROM product_categories WHERE COALESCE(parent_id, '') = COALESCE(?, '') AND normalized_name = ?",
        [parentId, normalized],
      );
      if (found != null) {
        parentId = found['id'] as String;
        continue;
      }
      final id = _uuid.v4();
      db.execute('INSERT INTO product_categories(id, name, normalized_name, parent_id, created_at) VALUES(?, ?, ?, ?, ?)',
        [id, name, normalized, parentId, nowIso()]);
      parentId = id;
    }
    return parentId;
  }

  String? _validBarcode(Object? raw, {String? exceptId}) {
    final v = (raw as String? ?? '').trim();
    if (v.isEmpty) return null;
    if (v.length > 64) throw ApiError(400, 'الرمز الشريطي طويل جداً');
    final other = db.selectOne('SELECT id, name FROM products WHERE barcode = ?', [v]);
    if (other != null && other['id'] != exceptId) throw ApiError(409, 'الرمز الشريطي مسجل لصنف آخر: ${other['name']}');
    return v;
  }

  /// باركود داخلي EAN-13 بيبدأ بـ 20 (مخصص للاستخدام الداخلي في المحلات).
  String _newBarcode() {
    for (var i = 0; i < 50; i++) {
      final body = '20${List.generate(10, (_) => randomBytes(1)[0] % 10).join()}';
      var sum = 0;
      for (var j = 0; j < 12; j++) {
        sum += int.parse(body[j]) * (j.isEven ? 1 : 3);
      }
      final code = '$body${(10 - sum % 10) % 10}';
      if (db.selectOne('SELECT id FROM products WHERE barcode = ?', [code]) == null) return code;
    }
    throw ApiError(500, 'تعذّر إنشاء رمز شريطي جديد');
  }

  Future<Object?> _createProduct(Request req, AuthUser u) async {
    final body = await _body(req);
    final id = _uuid.v4();
    final now = nowIso();
    final serialized = body['serialized'] == true;
    final category = _optionalText(body, 'category');
    final categoryId = _ensureCategoryForValue(category);
    _assertUniqueProductName(_requiredText(body, 'name', 'اسم الصنف'), categoryId);
    // الأجهزة بالـ IMEI كميتها بتيجي من الأجهزة نفسها، مش رقم بيتكتب
    final qty = serialized ? 0 : (body['qty'] is int ? body['qty'] as int : 0);
    db.transaction(() {
      db.execute(
        'INSERT INTO products(id, name, barcode, category, category_id, cost_cents, price_cents, qty, low_stock, track_stock, serialized, warranty_months, notes, image_file_id, created_at, updated_at) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id, _requiredText(body, 'name', 'اسم الصنف'), _validBarcode(body['barcode']), category, categoryId,
          body['costCents'] == null ? 0 : _cents(body['costCents'], 'سعر الشراء'),
          body['priceCents'] == null ? 0 : _cents(body['priceCents'], 'سعر البيع'),
          body['lowStock'] is int ? (body['lowStock'] as int).clamp(0, 100000) : 0,
          serialized || body['trackStock'] != false ? 1 : 0,
          serialized ? 1 : 0,
          body['warrantyMonths'] is int ? (body['warrantyMonths'] as int).clamp(0, 120) : 0,
          _optionalText(body, 'notes'), _optionalText(body, 'imageFileId'), now, now,
        ],
      );
      if (qty != 0) _moveStock(id, qty, 'initial', userId: u.id, note: 'رصيد أول المدة');
    });
    _audit(u.id, 'product.create', 'product', id, body['name'] as String?);
    _broadcast('products');
    return {'product': _productJson(db.selectOne('SELECT * FROM products WHERE id = ?', [id])!)};
  }

  Future<Object?> _updateProduct(Request req, AuthUser u) async {
    final id = req.params['id']!;
    final p = db.selectOne('SELECT * FROM products WHERE id = ?', [id]);
    if (p == null) throw ApiError(404, 'هذا الصنف غير موجود');
    final body = await _body(req);
    // سعر الشراء بيبان لصاحب المحل بس، فالاستقبال مايقدرش يغيّره
    if (!u.isOwner && body.containsKey('costCents')) throw ApiError(403, 'يقتصر تعديل سعر الشراء على مالك المحل');
    final sets = <String, Object?>{};
    if (body.containsKey('name')) sets['name'] = _requiredText(body, 'name', 'اسم الصنف');
    if (body.containsKey('barcode')) sets['barcode'] = _validBarcode(body['barcode'], exceptId: id);
    if (body.containsKey('category')) {
      final category = _optionalText(body, 'category');
      sets['category'] = category;
      sets['category_id'] = _ensureCategoryForValue(category);
    }
    if (sets.containsKey('name') || sets.containsKey('category_id')) {
      final nextName = (sets['name'] ?? p['name']) as String;
      final nextCategoryId = sets.containsKey('category_id')
          ? sets['category_id'] as String?
          : p['category_id'] as String?;
      _assertUniqueProductName(nextName, nextCategoryId, exceptId: id);
    }
    if (body.containsKey('costCents')) sets['cost_cents'] = _cents(body['costCents'], 'سعر الشراء');
    if (body.containsKey('priceCents')) sets['price_cents'] = _cents(body['priceCents'], 'سعر البيع');
    if (body.containsKey('lowStock')) sets['low_stock'] = (body['lowStock'] as int? ?? 0).clamp(0, 100000);
    if (body.containsKey('trackStock') && p['serialized'] != 1) sets['track_stock'] = body['trackStock'] == false ? 0 : 1;
    if (body['warrantyMonths'] is int) sets['warranty_months'] = (body['warrantyMonths'] as int).clamp(0, 120);
    if (body['serialized'] == true && p['serialized'] != 1) {
      if ((p['qty'] as int) != 0) throw ApiError(400, 'اجعل كمية الصنف صفراً أولاً، ثم أضف الأجهزة باستخدام أرقام IMEI');
      sets['serialized'] = 1;
      sets['track_stock'] = 1;
    }
    if (body.containsKey('notes')) sets['notes'] = _optionalText(body, 'notes');
    if (body.containsKey('imageFileId')) sets['image_file_id'] = _optionalText(body, 'imageFileId');
    if (body.containsKey('active')) sets['active'] = body['active'] == false ? 0 : 1;
    if (sets.isNotEmpty) {
      db.execute('UPDATE products SET ${sets.keys.map((k) => '$k = ?').join(', ')}, updated_at = ? WHERE id = ?', [...sets.values, nowIso(), id]);
      if (sets.containsKey('price_cents') && sets['price_cents'] != p['price_cents']) {
        _audit(u.id, 'product.price', 'product', id, '${p['name']}: من ${_money(p['price_cents'] as int)} لـ ${_money(sets['price_cents'] as int)}');
      }
      _broadcast('products');
    }
    return {'product': _productJson(db.selectOne('SELECT * FROM products WHERE id = ?', [id])!)};
  }

  /// تمر جميع تغييرات الكمية من هنا لضمان تسجيلها في سجل حركة المخزون.
  int _moveStock(String productId, int change, String reason, {String? refType, String? refId, String? note, String? userId}) {
    final p = db.selectOne('SELECT qty, track_stock FROM products WHERE id = ?', [productId]);
    if (p == null) throw ApiError(400, 'الصنف غير موجود');
    if (p['track_stock'] != 1) return p['qty'] as int;
    final after = (p['qty'] as int) + change;
    db.execute('UPDATE products SET qty = ?, updated_at = ? WHERE id = ?', [after, nowIso(), productId]);
    db.execute(
      'INSERT INTO stock_moves(product_id, qty_change, qty_after, reason, ref_type, ref_id, note, user_id, created_at) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [productId, change, after, reason, refType, refId, note, userId, nowIso()],
    );
    return after;
  }

  Future<Object?> _adjustStock(Request req, AuthUser u) async {
    final id = req.params['id']!;
    final p = db.selectOne('SELECT * FROM products WHERE id = ?', [id]);
    if (p == null) throw ApiError(404, 'هذا الصنف غير موجود');
    final body = await _body(req);
    int change;
    if (body['setQty'] is int) {
      change = (body['setQty'] as int) - (p['qty'] as int);
    } else if (body['qtyChange'] is int) {
      change = body['qtyChange'] as int;
    } else {
      throw ApiError(400, 'يُرجى إدخال الكمية');
    }
    if (change == 0) return {'product': _productJson(p)};
    if (p['serialized'] == 1) throw ApiError(400, 'تُضاف الأجهزة المسجلة بأرقام IMEI وتُحذف بصورة فردية، ولا تُدار من خلال الجرد');
    final reason = const {'purchase', 'count', 'damaged', 'lost', 'return_supplier', 'other'}.contains(body['reason']) ? body['reason'] as String : 'other';
    // الاستقبال يقدر يضيف بضاعة وصلت بس، والجرد والتالف لصاحب المحل
    if (!u.isOwner && (reason != 'purchase' || change <= 0)) throw ApiError(403, 'لا يمكن تعديل الجرد إلا من قِبل مالك المحل. يمكنك إضافة كمية واردة');
    final paid = u.isOwner && body['costCents'] is int && (body['costCents'] as int) > 0 && change > 0 ? body['costCents'] as int : null;
    db.transaction(() {
      if (paid != null) {
        // سعر الشراء الجديد = متوسط القديم والجديد
        final oldQty = (p['qty'] as int) < 0 ? 0 : p['qty'] as int;
        final newCost = ((oldQty * (p['cost_cents'] as int) + paid) / (oldQty + change)).round();
        db.execute('UPDATE products SET cost_cents = ?, updated_at = ? WHERE id = ?', [newCost, nowIso(), id]);
      }
      _moveStock(id, change, reason, userId: u.id, note: _optionalText(body, 'note'));
    });
    _audit(u.id, 'product.adjust', 'product', id, '${p['name']}: ${change > 0 ? '+' : ''}$change ($reason)');
    _broadcast('products');
    return {'product': _productJson(db.selectOne('SELECT * FROM products WHERE id = ?', [id])!)};
  }

  Object? _productMoves(Request req, AuthUser u) {
    final rows = db.select(
      'SELECT m.*, u.name AS user_name FROM stock_moves m LEFT JOIN users u ON u.id = m.user_id WHERE m.product_id = ? ORDER BY m.id DESC LIMIT 200',
      [req.params['id']],
    );
    return {
      'moves': rows
          .map((m) => {
                'change': m['qty_change'],
                'after': m['qty_after'],
                'reason': m['reason'],
                'refType': m['ref_type'],
                'refId': m['ref_id'],
                'note': m['note'],
                'userName': m['user_name'],
                'createdAt': m['created_at'],
              })
          .toList(),
    };
  }

  /// استيراد الأصناف من البرنامج السابق (الصفوف مستخرجة من Excel بعد تحديد المستخدم للأعمدة).
  /// لو الباركود أو الاسم موجود بيتحدّث، وإلا بيتضاف.
  Future<Object?> _importProducts(Request req, AuthUser u) async {
    final body = await _body(req);
    final rows = body['rows'];
    if (rows is! List || rows.isEmpty) throw ApiError(400, 'لا توجد بيانات');
    if (rows.length > 5000) throw ApiError(400, 'الدفعة كبيرة، ابعت 5000 صنف بالكتير في المرة');
    final updateQty = body['updateQty'] != false;
    var created = 0, updated = 0;
    final errors = <String>[];
    final now = nowIso();

    db.transaction(() {
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        if (r is! Map) continue;
        final name = (r['name'] as String? ?? '').trim();
        final barcode = (r['barcode'] as String? ?? '').trim();
        if (name.isEmpty) {
          errors.add('صف ${i + 1}: الاسم فارغ');
          continue;
        }
        int? cents(Object? v) => v is int && v >= 0 ? v : null;
        final existing = barcode.isNotEmpty
            ? db.selectOne('SELECT * FROM products WHERE barcode = ?', [barcode])
            : db.selectOne('SELECT * FROM products WHERE name = ? AND barcode IS NULL', [name]);
        final qty = r['qty'] is int ? r['qty'] as int : null;
        final category = (r['category'] as String?)?.trim();
        final categoryId = _ensureCategoryForValue(category);
        if (existing == null) {
          final duplicate = categoryId == null ? null : db.selectOne(
            'SELECT id FROM products WHERE category_id = ? AND lower(trim(name)) = lower(trim(?)) LIMIT 1',
            [categoryId, name],
          );
          if (duplicate != null) {
            errors.add('صف ${i + 1}: يوجد صنف بالاسم نفسه داخل التصنيف المحدد');
            continue;
          }
          final id = _uuid.v4();
          db.execute(
            'INSERT INTO products(id, name, barcode, category, category_id, cost_cents, price_cents, qty, low_stock, track_stock, created_at, updated_at) '
            'VALUES(?, ?, ?, ?, ?, ?, ?, 0, ?, 1, ?, ?)',
            [id, name, barcode.isEmpty ? null : barcode, category, categoryId, cents(r['costCents']) ?? 0, cents(r['priceCents']) ?? 0,
             r['lowStock'] is int ? r['lowStock'] : 0, now, now],
          );
          if (qty != null && qty != 0) _moveStock(id, qty, 'import', userId: u.id, note: 'استيراد');
          created++;
        } else {
          db.execute(
            'UPDATE products SET name = ?, category = COALESCE(?, category), category_id = COALESCE(?, category_id), cost_cents = COALESCE(?, cost_cents), '
            'price_cents = COALESCE(?, price_cents), active = 1, updated_at = ? WHERE id = ?',
            [name, category, categoryId, cents(r['costCents']), cents(r['priceCents']), now, existing['id']],
          );
          if (updateQty && qty != null && qty != existing['qty']) {
            _moveStock(existing['id'] as String, qty - (existing['qty'] as int), 'import', userId: u.id, note: 'استيراد');
          }
          updated++;
        }
      }
    });
    _audit(u.id, 'product.import', 'product', null, 'جديد $created، تحديث $updated');
    _broadcast('products');
    return {'created': created, 'updated': updated, 'errors': errors.take(50).toList()};
  }

  // ================================================================ customers (balance)

  Future<Object?> _createCustomer(Request req, AuthUser u) async {
    final body = await _body(req);
    final phone = _validPhone(body['phone']);
    final existing = db.selectOne('SELECT * FROM customers WHERE phone_norm = ?', [normalizePhone(phone)]);
    if (existing != null) return {'customer': _customerJson(existing), 'existing': true};
    final id = _uuid.v4();
    final now = nowIso();
    db.execute(
      'INSERT INTO customers(id, name, phone, phone_norm, whatsapp, notes, created_at, updated_at) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
      [id, _requiredText(body, 'name', 'اسم العميل'), phone, normalizePhone(phone), _optionalText(body, 'whatsapp'), null, now, now],
    );
    _broadcast('customers');
    return {'customer': _customerJson(db.selectOne('SELECT * FROM customers WHERE id = ?', [id])!)};
  }

  /// المبالغ المستحقة على العميل: فواتير البيع الآجل + أجهزة الصيانة المسلّمة ذات المبالغ المتبقية − المبالغ المسددة.
  int _customerBalance(String customerId) {
    final sales = db.selectOne(
      'SELECT COALESCE(SUM(total_cents - returned_cents - paid_cents), 0) AS s FROM sales WHERE customer_id = ?', [customerId])!['s'] as int;
    final repairs = db.selectOne(
      "SELECT COALESCE(SUM(COALESCE(t.final_cents, t.estimated_cents) - (SELECT COALESCE(SUM(amount_cents), 0) FROM payments p WHERE p.ticket_id = t.id)), 0) AS s "
      "FROM tickets t WHERE t.customer_id = ? AND t.status = 'delivered'",
      [customerId],
    )!['s'] as int;
    final paid = db.selectOne('SELECT COALESCE(SUM(amount_cents), 0) AS s FROM customer_payments WHERE customer_id = ?', [customerId])!['s'] as int;
    return sales + repairs - paid;
  }

  Object? _customerLedger(Request req, AuthUser u) {
    final id = req.params['id']!;
    if (db.selectOne('SELECT id FROM customers WHERE id = ?', [id]) == null) throw ApiError(404, 'العميل غير موجود');
    final entries = <Map<String, Object?>>[
      for (final s in db.select('SELECT id, number, total_cents, paid_cents, returned_cents, created_at FROM sales WHERE customer_id = ? AND total_cents - returned_cents - paid_cents <> 0', [id]))
        {'type': 'sale', 'refId': s['id'], 'label': 'فاتورة بيع #${s['number']}', 'amountCents': (s['total_cents'] as int) - (s['returned_cents'] as int) - (s['paid_cents'] as int), 'createdAt': s['created_at']},
      for (final t in db.select(
          "SELECT t.id, t.number, t.delivered_at, COALESCE(t.final_cents, t.estimated_cents) - (SELECT COALESCE(SUM(amount_cents), 0) FROM payments p WHERE p.ticket_id = t.id) AS due "
          "FROM tickets t WHERE t.customer_id = ? AND t.status = 'delivered'", [id]))
        if ((t['due'] as int) != 0) {'type': 'repair', 'refId': t['id'], 'label': 'صيانة جهاز #${t['number']}', 'amountCents': t['due'], 'createdAt': t['delivered_at']},
      for (final p in db.select('SELECT * FROM customer_payments WHERE customer_id = ?', [id]))
        {'type': 'payment', 'refId': p['id'], 'label': 'تحصيل (${PaymentMethod.parse(p['method'] as String?).label})', 'amountCents': -(p['amount_cents'] as int), 'createdAt': p['created_at'], 'note': p['note']},
    ]..sort((a, b) => (b['createdAt'] as String? ?? '').compareTo(a['createdAt'] as String? ?? ''));
    return {'balanceCents': _customerBalance(id), 'entries': entries};
  }

  Future<Object?> _collectFromCustomer(Request req, AuthUser u) async {
    final id = req.params['id']!;
    final c = db.selectOne('SELECT * FROM customers WHERE id = ?', [id]);
    if (c == null) throw ApiError(404, 'العميل غير موجود');
    final body = await _body(req);
    final amount = _cents(body['amountCents'], 'المبلغ');
    if (amount <= 0) throw ApiError(400, 'يُرجى إدخال المبلغ');
    final balance = _customerBalance(id);
    if (amount > balance) throw ApiError(400, 'المبلغ أكبر من المستحق على العميل (${_money(balance)})');
    final method = PaymentMethod.parse(body['method'] as String?);
    final pid = _uuid.v4();
    db.transaction(() {
      db.execute(
        'INSERT INTO customer_payments(id, customer_id, amount_cents, method, note, user_id, created_at) VALUES(?, ?, ?, ?, ?, ?, ?)',
        [pid, id, amount, method.name, _optionalText(body, 'note'), u.id, nowIso()],
      );
      _cashMove('customer_payment', amount, method, userId: u.id, refType: 'customer', refId: id, note: c['name'] as String);
    });
    _audit(u.id, 'customer.payment', 'customer', id, '${c['name']}: ${_money(amount)}');
    _broadcast('customers');
    _broadcast('cash');
    return {'balanceCents': _customerBalance(id)};
  }

  // ================================================================ sales

  Future<Object?> _createSale(Request req, AuthUser u) async {
    await _requireLicense();
    final body = await _body(req);
    final items = body['items'];
    if (items is! List || items.isEmpty) throw ApiError(400, 'الفاتورة فارغة');
    final customerId = body['customerId'] as String?;
    if (customerId != null && db.selectOne('SELECT id FROM customers WHERE id = ?', [customerId]) == null) {
      throw ApiError(400, 'العميل غير موجود');
    }
    final canDiscount = u.isOwner || db.setting('cashier_can_discount') != '0';

    final lines = <Map<String, Object?>>[];
    var subtotal = 0;
    for (final it in items) {
      if (it is! Map) continue;
      final qty = it['qty'] is int ? it['qty'] as int : 0;
      if (qty <= 0 || qty > 100000) throw ApiError(400, 'الكمية غير صحيحة');
      final p = db.selectOne('SELECT * FROM products WHERE id = ? AND active = 1', [it['productId']]);
      if (p == null) throw ApiError(400, 'يوجد صنف في الفاتورة غير موجود');
      // الهواتف المحمولة بتتباع جهاز جهاز بالـ IMEI
      Map<String, Object?>? unit;
      if (p['serialized'] == 1) {
        unit = db.selectOne('SELECT * FROM units WHERE id = ? AND product_id = ?', [it['unitId'], p['id']]);
        if (unit == null) throw ApiError(400, 'يُرجى تحديد الجهاز (IMEI) المراد بيعه من "${p['name']}"');
        if (unit['status'] != 'in_stock') throw ApiError(409, 'الجهاز ${unit['imei']} سبق بيعه');
        if (qty != 1) throw ApiError(400, 'كل جهاز بـ IMEI بيتباع لوحده');
        if (lines.any((l) => (l['unit'] as Map?)?['id'] == unit!['id'])) throw ApiError(400, 'الجهاز ${unit['imei']} متكرر في الفاتورة');
      }
      final listPrice = (unit?['price_cents'] as int?) ?? p['price_cents'] as int;
      final price = it['unitPriceCents'] == null ? listPrice : _cents(it['unitPriceCents'], 'السعر');
      if (price < listPrice && !canDiscount) throw ApiError(403, 'لا يُسمح لك بالبيع بسعر أقل من السعر المحدد');
      if (unit == null && p['track_stock'] == 1 && (p['qty'] as int) < qty && db.setting('allow_negative_stock') == '0') {
        throw ApiError(400, 'الكمية المتاحة من "${p['name']}" هي ${p['qty']} بس');
      }
      lines.add({'product': p, 'qty': qty, 'price': price, 'unit': unit});
      subtotal += price * qty;
    }
    final discount = body['discountCents'] == null ? 0 : _cents(body['discountCents'], 'الخصم');
    if (discount > 0 && !canDiscount) throw ApiError(403, 'لا يُسمح لك بإجراء خصم');
    if (discount > subtotal) throw ApiError(400, 'الخصم أكبر من الفاتورة');
    final total = subtotal - discount;

    final payments = <(PaymentMethod, int)>[];
    for (final pay in (body['payments'] as List? ?? const [])) {
      if (pay is! Map) continue;
      final amount = _cents(pay['amountCents'], 'المبلغ');
      if (amount > 0) payments.add((PaymentMethod.parse(pay['method'] as String?), amount));
    }
    final paid = payments.fold<int>(0, (s, p) => s + p.$2);
    if (paid > total) throw ApiError(400, 'المدفوع أكبر من الفاتورة');
    if (paid < total && customerId == null) throw ApiError(400, 'يتطلب البيع الآجل تحديد العميل. يُرجى اختيار العميل أولاً.');

    final id = _uuid.v4();
    final now = nowIso();
    final number = db.transaction(() {
      final number = db.selectOne('SELECT COALESCE(MAX(number), 0) + 1 AS n FROM sales')!['n'] as int;
      final session = _openSessionId(u.id);
      db.execute(
        'INSERT INTO sales(id, number, customer_id, session_id, subtotal_cents, discount_cents, total_cents, paid_cents, note, user_id, created_at) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [id, number, customerId, session, subtotal, discount, total, paid, _optionalText(body, 'note'), u.id, now],
      );
      for (final l in lines) {
        final p = l['product'] as Map<String, Object?>;
        final unit = l['unit'] as Map<String, Object?>?;
        db.execute(
          'INSERT INTO sale_items(id, sale_id, product_id, name, qty, unit_price_cents, cost_cents, unit_id) VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
          [_uuid.v4(), id, p['id'], p['name'], l['qty'], l['price'], unit?['cost_cents'] ?? p['cost_cents'], unit?['id']],
        );
        if (unit != null) {
          db.execute("UPDATE units SET status = 'sold', sale_id = ?, sold_at = ?, updated_at = ? WHERE id = ?", [id, now, now, unit['id']]);
        }
        _moveStock(p['id'] as String, -(l['qty'] as int), 'sale', refType: 'sale', refId: id, userId: u.id, note: unit == null ? null : 'IMEI ${unit['imei']}');
      }
      if (lines.any((l) => l['unit'] != null)) _broadcast('units');
      for (final (method, amount) in payments) {
        _cashMove('sale', amount, method, userId: u.id, refType: 'sale', refId: id, note: 'فاتورة #$number');
      }
      return number;
    });
    _audit(u.id, 'sale.create', 'sale', id, '#$number ${_money(total)}${paid < total ? ' (آجل ${_money(total - paid)})' : ''}');
    _broadcast('products');
    _broadcast('sales');
    _broadcast('cash');
    if (customerId != null) _broadcast('customers');
    return _saleDetail(id, number: number);
  }

  Map<String, Object?> _saleSummary(Map<String, Object?> s) => {
        'id': s['id'],
        'number': s['number'],
        'customerId': s['customer_id'],
        'customerName': s['customer_name'],
        'subtotalCents': s['subtotal_cents'],
        'discountCents': s['discount_cents'],
        'totalCents': s['total_cents'],
        'paidCents': s['paid_cents'],
        'returnedCents': s['returned_cents'],
        'dueCents': (s['total_cents'] as int) - (s['returned_cents'] as int) - (s['paid_cents'] as int),
        'itemsCount': s['items_count'],
        'userName': s['user_name'],
        'note': s['note'],
        'createdAt': s['created_at'],
      };

  static const _saleSelect = '''
    SELECT s.*, c.name AS customer_name, u.name AS user_name,
           (SELECT COALESCE(SUM(qty), 0) FROM sale_items i WHERE i.sale_id = s.id) AS items_count
    FROM sales s LEFT JOIN customers c ON c.id = s.customer_id LEFT JOIN users u ON u.id = s.user_id''';

  Object? _listSales(Request req, AuthUser u) {
    final qp = req.url.queryParameters;
    final q = (qp['q'] ?? '').trim();
    final where = <String>[];
    final params = <Object?>[];
    if (q.isNotEmpty) {
      final n = int.tryParse(latinDigits(q));
      where.add('(c.name LIKE ?${n != null ? ' OR s.number = ?' : ''} OR EXISTS (SELECT 1 FROM sale_items i WHERE i.sale_id = s.id AND i.name LIKE ?))');
      params.add('%$q%');
      if (n != null) params.add(n);
      params.add('%$q%');
    }
    if (qp['from'] != null) {
      where.add('s.created_at >= ?');
      params.add(_validDate(qp['from']));
    }
    if (qp['to'] != null) {
      where.add('s.created_at < ?');
      params.add(_validDate(qp['to']));
    }
    if (qp['due'] == '1') where.add('s.total_cents - s.returned_cents - s.paid_cents > 0');
    final limit = (int.tryParse(qp['limit'] ?? '') ?? 100).clamp(1, 500);
    final rows = db.select('$_saleSelect ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} ORDER BY s.created_at DESC LIMIT ?', [...params, limit]);
    return {'sales': rows.map(_saleSummary).toList()};
  }

  Object? _getSale(Request req, AuthUser u) => _saleDetail(req.params['id']!, showCost: u.isOwner);

  Map<String, Object?> _saleDetail(String id, {int? number, bool showCost = false}) {
    final s = db.selectOne('$_saleSelect WHERE s.id = ?', [id]);
    if (s == null) throw ApiError(404, 'الفاتورة غير موجودة');
    final items = db.select(
      'SELECT i.*, x.imei, x.imei2, x.condition, COALESCE(x.warranty_months, p.warranty_months, 0) AS warranty_months '
      'FROM sale_items i LEFT JOIN units x ON x.id = i.unit_id LEFT JOIN products p ON p.id = i.product_id WHERE i.sale_id = ? ORDER BY i.rowid',
      [id],
    );
    final moves = db.select("SELECT * FROM cash_moves WHERE ref_type = 'sale' AND ref_id = ? ORDER BY created_at", [id]);
    return {
      'sale': _saleSummary(s),
      'items': items
          .map((i) => {
                'id': i['id'],
                'productId': i['product_id'],
                'name': i['name'],
                'qty': i['qty'],
                'unitPriceCents': i['unit_price_cents'],
                'returnedQty': i['returned_qty'],
                'unitId': i['unit_id'],
                'imei': i['imei'],
                'condition': i['condition'],
                'warrantyMonths': i['warranty_months'],
                if (showCost) 'costCents': i['cost_cents'],
              })
          .toList(),
      'payments': moves
          .map((m) => {'type': m['type'], 'amountCents': m['amount_cents'], 'method': m['method'], 'createdAt': m['created_at']})
          .toList(),
    };
  }

  Future<Object?> _returnSale(Request req, AuthUser u) async {
    final id = req.params['id']!;
    final s = db.selectOne('SELECT * FROM sales WHERE id = ?', [id]);
    if (s == null) throw ApiError(404, 'الفاتورة غير موجودة');
    final body = await _body(req);
    final wanted = body['items'];
    if (wanted is! List || wanted.isEmpty) throw ApiError(400, 'يُرجى تحديد الأصناف المراد إرجاعها');
    final method = PaymentMethod.parse(body['method'] as String?);

    var value = 0;
    final plan = <(Map<String, Object?>, int)>[];
    for (final w in wanted) {
      if (w is! Map) continue;
      final item = db.selectOne('SELECT * FROM sale_items WHERE id = ? AND sale_id = ?', [w['saleItemId'], id]);
      if (item == null) throw ApiError(400, 'الصنف غير مدرج في هذه الفاتورة');
      final qty = w['qty'] is int ? w['qty'] as int : 0;
      final left = (item['qty'] as int) - (item['returned_qty'] as int);
      if (qty <= 0) continue;
      if (qty > left) throw ApiError(400, 'لا يمكن إرجاع كمية تتجاوز $left من "${item['name']}"');
      plan.add((item, qty));
      value += qty * (item['unit_price_cents'] as int);
    }
    if (plan.isEmpty) throw ApiError(400, 'يُرجى تحديد الأصناف المراد إرجاعها');
    // الخصم بيتوزع على الأصناف بالنسبة، فالمرتجع بيتحسب بعد الخصم
    final subtotal = s['subtotal_cents'] as int;
    if ((s['discount_cents'] as int) > 0 && subtotal > 0) value = (value * (s['total_cents'] as int) / subtotal).round();

    // المرتجع بيقلل الآجل الأول، والباقي بيرجع للعميل فلوس
    final due = (s['total_cents'] as int) - (s['returned_cents'] as int) - (s['paid_cents'] as int);
    final cashBack = (value - (due > 0 ? due : 0)).clamp(0, value);

    db.transaction(() {
      for (final (item, qty) in plan) {
        db.execute('UPDATE sale_items SET returned_qty = returned_qty + ? WHERE id = ?', [qty, item['id']]);
        if (item['product_id'] != null) {
          _moveStock(item['product_id'] as String, qty, 'return', refType: 'sale', refId: id, userId: u.id);
        }
        if (item['unit_id'] != null) {
          db.execute("UPDATE units SET status = 'in_stock', sale_id = NULL, sold_at = NULL, updated_at = ? WHERE id = ?", [nowIso(), item['unit_id']]);
          _broadcast('units');
        }
      }
      db.execute('UPDATE sales SET returned_cents = returned_cents + ?, paid_cents = paid_cents - ? WHERE id = ?', [value, cashBack, id]);
      if (cashBack > 0) {
        _cashMove('sale_refund', -cashBack, method, userId: u.id, refType: 'sale', refId: id, note: 'مرتجع فاتورة #${s['number']}');
      }
    });
    _audit(u.id, 'sale.return', 'sale', id, '#${s['number']} ${_money(value)}');
    _broadcast('products');
    _broadcast('sales');
    _broadcast('cash');
    return {..._saleDetail(id), 'refundCents': cashBack, 'returnValueCents': value};
  }

  // ================================================================ cash drawer

  /// يعيد هذا الإجراء الوردية المفتوحة، أو ينشئ وردية جديدة برصيد النقدية المتبقي في الخزنة من المرة السابقة.
  String _openSessionId(String? userId) {
    final open = db.selectOne('SELECT id FROM register_sessions WHERE closed_at IS NULL ORDER BY opened_at DESC LIMIT 1');
    if (open != null) return open['id'] as String;
    final last = db.selectOne('SELECT kept_cash_cents FROM register_sessions WHERE closed_at IS NOT NULL ORDER BY closed_at DESC LIMIT 1');
    final id = _uuid.v4();
    db.execute(
      'INSERT INTO register_sessions(id, branch_id, opened_by, opened_at, opening_cash_cents) VALUES(?, ?, ?, ?, ?)',
      [id, db.selectOne('SELECT id FROM branches WHERE is_local = 1 LIMIT 1')?['id'], userId, nowIso(), last?['kept_cash_cents'] ?? 0],
    );
    return id;
  }

  void _cashMove(String type, int amount, PaymentMethod method,
      {String? userId, String? refType, String? refId, String? category, String? note}) {
    db.execute(
      'INSERT INTO cash_moves(id, session_id, type, amount_cents, method, category, ref_type, ref_id, note, user_id, created_at) '
      'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [_uuid.v4(), _openSessionId(userId), type, amount, method.name, category, refType, refId, note, userId, nowIso()],
    );
  }

  Map<String, Object?> _sessionSummary(String sessionId, {bool withMoves = false}) {
    final s = db.selectOne(
      'SELECT r.*, o.name AS opened_by_name, c.name AS closed_by_name FROM register_sessions r '
      'LEFT JOIN users o ON o.id = r.opened_by LEFT JOIN users c ON c.id = r.closed_by WHERE r.id = ?',
      [sessionId],
    )!;
    final byMethod = <String, int>{for (final m in PaymentMethod.values) m.name: 0};
    final byType = <String, int>{};
    for (final r in db.select('SELECT type, method, SUM(amount_cents) AS s FROM cash_moves WHERE session_id = ? GROUP BY type, method', [sessionId])) {
      byMethod[r['method'] as String] = (byMethod[r['method']] ?? 0) + (r['s'] as int);
      byType[r['type'] as String] = (byType[r['type']] ?? 0) + (r['s'] as int);
    }
    final opening = s['opening_cash_cents'] as int;
    return {
      'id': s['id'],
      'openedAt': s['opened_at'],
      'openedBy': s['opened_by_name'],
      'closedAt': s['closed_at'],
      'closedBy': s['closed_by_name'],
      'openingCashCents': opening,
      'byMethod': byMethod,
      'byType': byType,
      'expectedCashCents': s['closed_at'] == null ? opening + byMethod['cash']! : s['expected_cash_cents'],
      'countedCashCents': s['counted_cash_cents'],
      'keptCashCents': s['kept_cash_cents'],
      'differenceCents': s['counted_cash_cents'] == null ? null : (s['counted_cash_cents'] as int) - (s['expected_cash_cents'] as int),
      'note': s['note'],
      // آخر الحركات بس: لو اليوم ما اتقفلش أسابيع، الحركات بتبقى بالآلاف وكانت بتتقل السيرفر كله
      if (withMoves) 'movesCount': db.selectOne('SELECT COUNT(*) AS c FROM cash_moves WHERE session_id = ?', [sessionId])!['c'],
      if (withMoves)
        'moves': db
            .select('SELECT m.*, u.name AS user_name FROM cash_moves m LEFT JOIN users u ON u.id = m.user_id WHERE m.session_id = ? '
                'ORDER BY m.created_at DESC LIMIT $_cashMovesShown', [sessionId])
            .map((m) => {
                  'id': m['id'],
                  'type': m['type'],
                  'amountCents': m['amount_cents'],
                  'method': m['method'],
                  'category': m['category'],
                  'refType': m['ref_type'],
                  'refId': m['ref_id'],
                  'note': m['note'],
                  'userName': m['user_name'],
                  'createdAt': m['created_at'],
                })
            .toList(),
    };
  }

  Object? _cashCurrent(Request req, AuthUser u) {
    final id = db.transaction(() => _openSessionId(u.id));
    return {'session': _sessionSummary(id, withMoves: true), 'expenseCategories': defaultExpenseCategories};
  }

  Future<Object?> _addCashMove(Request req, AuthUser u) async {
    final body = await _body(req);
    final type = body['type'];
    if (!const {'expense', 'deposit', 'withdraw'}.contains(type)) throw ApiError(400, 'نوع الحركة غير صحيح');
    final amount = _cents(body['amountCents'], 'المبلغ');
    if (amount <= 0) throw ApiError(400, 'يُرجى إدخال المبلغ');
    if (type == 'withdraw' && !u.isOwner) throw ApiError(403, 'السحب من الخزنة لصاحب المحل بس');
    final note = _optionalText(body, 'note');
    if (type == 'expense' && note == null && _optionalText(body, 'category') == null) throw ApiError(400, 'يُرجى تحديد بند المصروف');
    final id = db.transaction(() {
      _cashMove(type as String, type == 'deposit' ? amount : -amount, PaymentMethod.parse(body['method'] as String?),
          userId: u.id, category: _optionalText(body, 'category'), note: note);
      return _openSessionId(u.id);
    });
    _audit(u.id, 'cash.$type', 'cash', null, '${_money(amount)} ${note ?? body['category'] ?? ''}');
    _broadcast('cash');
    // الشاشة بتعيد تحميل الدرج لوحدها، فمش لازم نبعت الحركات كلها هنا
    return {'session': _sessionSummary(id)};
  }

  Future<Object?> _closeCash(Request req, AuthUser u) async {
    final body = await _body(req);
    final counted = _cents(body['countedCashCents'], 'النقدية الموجودة في الصندوق');
    final kept = body['keptCashCents'] == null ? counted : _cents(body['keptCashCents'], 'المبلغ المتبقي في الصندوق');
    if (kept > counted) throw ApiError(400, 'المبلغ المتبقي في الصندوق يتجاوز المبلغ الذي جرى إحصاؤه');
    final id = db.transaction(() => _openSessionId(u.id));
    final summary = _sessionSummary(id);
    final expected = summary['expectedCashCents'] as int;
    db.execute(
      'UPDATE register_sessions SET closed_by = ?, closed_at = ?, expected_cash_cents = ?, counted_cash_cents = ?, kept_cash_cents = ?, note = ? WHERE id = ?',
      [u.id, nowIso(), expected, counted, kept, _optionalText(body, 'note'), id],
    );
    final diff = counted - expected;
    _audit(u.id, 'cash.close', 'cash', id, 'متوقع ${_money(expected)} • اتعد ${_money(counted)}${diff != 0 ? ' • فرق ${_money(diff)}' : ''}');
    _broadcast('cash');
    return {'closed': _sessionSummary(id)};
  }

  Object? _cashSessions(Request req, AuthUser u) {
    final rows = db.select('SELECT id FROM register_sessions ORDER BY opened_at DESC LIMIT 60');
    return {'sessions': rows.map((r) => _sessionSummary(r['id'] as String)).toList()};
  }
}
