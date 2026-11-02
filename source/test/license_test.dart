import 'dart:io';

import 'package:abdulmalik_erp/src/core/api_client.dart';
import 'package:abdulmalik_erp/src/server/api_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('open edition', () {
    late Directory dir;
    late AbdulmalikErpServer server;
    late ApiClient api;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('abdulmalik_erp_open');
      server = AbdulmalikErpServer(dataDir: dir.path, requestedPort: 0, cloudSync: false);
      await server.start();
      api = ApiClient('http://127.0.0.1:${server.port}');
      api.token = (await api.post('/api/setup', {
        'shopName': 'محل', 'ownerName': 'أحمد', 'username': 'owner', 'password': 'owner123',
      }))['token'] as String;
    });

    tearDown(() async {
      api.close();
      await server.stop();
      await dir.delete(recursive: true);
    });

    Future<void> intake() => api.post('/api/tickets', {
      'customer': {'name': 'سارة', 'phone': '01001234567'},
      'brand': 'Samsung', 'model': 'A55', 'problems': ['الشاشة'],
    });

    test('new shop is open with no expiry and new work is never blocked', () async {
      final status = await api.get('/api/license');
      expect(status['state'], 'active');
      expect(status['plan'], 'open');
      expect(status['expiresAt'], isNull);
      expect(status['devices'], 999);
      await intake();
      server.db.setSetting('trial_started', DateTime.now().toUtc().subtract(const Duration(days: 900)).toIso8601String());
      server.db.setSetting('license_clock', DateTime.now().toUtc().add(const Duration(days: 900)).toIso8601String());
      expect((await api.get('/api/license'))['state'], 'active');
      await intake();
      expect(((await api.get('/api/tickets', query: {'scope': 'all'}))['tickets'] as List).length, 2);
    });

    test('clock changes do not restrict the open edition', () async {
      server.db.setSetting('license_clock', DateTime.now().toUtc().add(const Duration(days: 10)).toIso8601String());
      expect((await api.get('/api/license'))['state'], 'active');
      await intake();
    });
  });
}
