import 'dart:io';

import 'package:abdulmalik_erp/src/core/api_client.dart';
import 'package:abdulmalik_erp/src/server/api_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late AbdulmalikErpServer server;
  late ApiClient api;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fixtrack_reports');
    server = AbdulmalikErpServer(dataDir: dir.path, requestedPort: 0, cloudSync: false);
    await server.start();
    api = ApiClient('http://127.0.0.1:${server.port}');
    api.token = (await api.post('/api/setup', {'shopName': 'محل', 'ownerName': 'أحمد', 'username': 'owner', 'password': 'owner123'}))['token'] as String;
  });

  tearDown(() async {
    api.close();
    await server.stop();
    await dir.delete(recursive: true);
  });

  test('a full day adds up correctly', () async {
    // فني بعمولة 20% من ربح الصيانة
    final tech = (await api.post('/api/users', {'name': 'محمد', 'username': 'tech', 'password': 'tech1234', 'role': 'technician'}))['user'] as Map;
    await api.patch('/api/users/${tech['id']}', {'commissionType': 'percent', 'commissionValue': 2000});

    // مبيعات: 3 جرابات (تكلفة 30، بيع 75) + مرتجع جراب
    final cover = (await api.post('/api/products', {'name': 'جراب', 'costCents': 3000, 'priceCents': 7500, 'qty': 10}))['product'] as Map;
    final sale = await api.post('/api/sales', {
      'items': [{'productId': cover['id'], 'qty': 3}],
      'payments': [{'method': 'cash', 'amountCents': 22500}],
    });
    await api.post('/api/sales/${sale['sale']['id']}/return', {'items': [{'saleItemId': (sale['items'] as List).single['id'], 'qty': 1}]});

    // صيانة: جهاز بـ 1500 وقطعة تكلفتها 600، اتسلم
    final screen = (await api.post('/api/products', {'name': 'شاشة', 'costCents': 60000, 'priceCents': 90000, 'qty': 2}))['product'] as Map;
    final t = (await api.post('/api/tickets', {
      'customer': {'name': 'سارة', 'phone': '01001234567'},
      'brand': 'Samsung', 'model': 'A55', 'problems': ['الشاشة'], 'estimatedCents': 150000, 'technicianId': tech['id'],
    }))['ticket'] as Map;
    await api.post('/api/tickets/${t['id']}/parts', {'productId': screen['id'], 'qty': 1});
    await api.post('/api/tickets/${t['id']}/deliver', {'pin': t['pickupPin'], 'paymentCents': 150000});

    // خدمات: عمولة 10، ومصروف 50
    final w = (await api.post('/api/wallets', {'name': 'فودافون', 'kind': 'vodafone', 'balanceCents': 100000}))['wallet'] as Map;
    await api.post('/api/wallets/${w['id']}/txns', {'type': 'cash_in', 'amountCents': 20000, 'commissionCents': 1000});
    await api.post('/api/cash/moves', {'type': 'expense', 'amountCents': 5000, 'category': 'أكل وشرب'});

    final r = await api.get('/api/reports/summary');
    final sales = r['sales'] as Map;
    expect(sales['count'], 1);
    expect(sales['revenueCents'], 15000); // 22500 − 7500 مرتجع
    expect(sales['costCents'], 6000);
    expect(sales['profitCents'], 9000);
    expect((sales['topProducts'] as List).single['qty'], 2);

    final repairs = r['repairs'] as Map;
    expect(repairs['delivered'], 1);
    expect(repairs['revenueCents'], 150000);
    expect(repairs['partsCostCents'], 60000);
    expect(repairs['profitCents'], 90000);
    expect((repairs['topProblems'] as List).single['name'], 'الشاشة');

    final techRow = (r['technicians'] as List).singleWhere((x) => x['name'] == 'محمد');
    expect(techRow['laborCents'], 90000);
    expect(techRow['commissionCents'], 18000);

    expect(r['services']['commissionCents'], 1000);
    expect(r['expenses']['totalCents'], 5000);
    expect(r['netProfitCents'], 9000 + 90000 + 1000 - 5000);
    expect((r['daily'] as List).single['sales'], 15000);
    // المخزون: 8 جرابات × 30 + شاشة × 600
    expect(r['stock']['valueCents'], 8 * 3000 + 60000);
  });

  test('inventory report separates purchase, net sales, returns and nested category stock', () async {
    final product = (await api.post('/api/products', {
      'name': 'Galaxy A55 128GB أسود',
      'category': 'هواتف::Samsung::Galaxy A55',
      'qty': 5,
      'costCents': 10000,
      'priceCents': 15000,
    }))['product'] as Map;
    final productId = product['id'] as String;

    await api.post('/api/products/$productId/adjust', {
      'qtyChange': 4,
      'reason': 'purchase',
    });

    final sale = await api.post('/api/sales', {
      'items': [{'productId': productId, 'qty': 2}],
      'payments': [{'method': 'cash', 'amountCents': 30000}],
    });
    final saleId = sale['sale']['id'] as String;
    final saleItemId = (sale['items'] as List).single['id'] as String;
    await api.post('/api/sales/$saleId/return', {
      'items': [{'saleItemId': saleItemId, 'qty': 1}],
    });

    final report = await api.get('/api/reports/inventory');
    final rows = (report['items'] as List).cast<Map<String, dynamic>>();
    final row = rows.singleWhere((item) => item['id'] == productId);
    expect(row['categoryPath'], 'هواتف / Samsung / Galaxy A55');
    expect(row['incomingQty'], 4);
    expect(row['soldQty'], 1);
    expect(row['returnedQty'], 1);
    expect(row['currentQty'], 8);

    final totals = report['totals'] as Map;
    expect(totals['incomingQty'], 4);
    expect(totals['soldQty'], 1);
    expect(totals['returnedQty'], 1);
    expect(totals['currentQty'], 8);
  });

  test('reports are owner-only', () async {
    await api.post('/api/users', {'name': 'سارة', 'username': 'sara', 'password': 'sara1234', 'role': 'reception'});
    final rec = ApiClient(api.baseUrl);
    rec.token = (await rec.post('/api/auth/login', {'username': 'sara', 'password': 'sara1234'}))['token'] as String;
    try {
      await rec.get('/api/reports/summary');
      fail('should be forbidden');
    } on ApiException catch (e) {
      expect(e.status, 403);
    }
    try {
      await rec.get('/api/reports/inventory');
      fail('inventory report should be forbidden');
    } on ApiException catch (e) {
      expect(e.status, 403);
    }
    rec.close();
  });
}
