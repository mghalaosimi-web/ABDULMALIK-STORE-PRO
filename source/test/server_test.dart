import 'dart:io';

import 'package:abdulmalik_erp/src/core/api_client.dart';
import 'package:abdulmalik_erp/src/server/api_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late AbdulmalikErpServer server;
  late ApiClient api;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fixtrack_test');
    server = AbdulmalikErpServer(dataDir: dir.path, requestedPort: 0, cloudSync: false);
    await server.start();
    api = ApiClient('http://127.0.0.1:${server.port}');
  });

  tearDown(() async {
    api.close();
    await server.stop();
    await dir.delete(recursive: true);
  });

  Future<String> setupShop() async {
    final res = await api.post('/api/setup', {
      'shopName': 'محل النور',
      'ownerName': 'أحمد',
      'username': 'Ahmed',
      'password': 'secret123',
    });
    return res['token'] as String;
  }

  Future<void> expectApiError(Future<Object?> f, int status) async {
    try {
      await f;
      fail('expected ApiException $status');
    } on ApiException catch (e) {
      expect(e.status, status, reason: e.message);
    }
  }

  test('websocket token is carried only in Authorization header', () {
    final client = ApiClient('http://127.0.0.1:${server.port}');
    client.token = 'sensitive-session-token';
    final uri = client.webSocketUri();
    expect(uri.query, isEmpty);
    expect(uri.toString(), isNot(contains('sensitive-session-token')));
    expect(client.webSocketHeaders()['authorization'], 'Bearer sensitive-session-token');
    client.close();
  });

  test('info reports setup state', () async {
    var info = await api.get('/api/info');
    expect(info['app'], 'abdulmalik_erp');
    expect(info['setupDone'], false);
    await setupShop();
    info = await api.get('/api/info');
    expect(info['setupDone'], true);
    expect(info['shopName'], 'محل النور');
    expect(info['branchName'], 'الفرع الرئيسي');
  });

  test('session token in URL query is rejected', () async {
    final token = await setupShop();
    final uri = Uri.parse(api.baseUrl).replace(
      path: '/api/auth/me',
      queryParameters: {'token': token},
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      expect(response.statusCode, 401);
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  });

  test('setup only works once', () async {
    await setupShop();
    await expectApiError(setupShop(), 409);
  });

  test('login, me, logout', () async {
    await setupShop();
    await expectApiError(api.post('/api/auth/login', {'username': 'ahmed', 'password': 'wrong'}), 401);

    // اسم المستخدم مش حساس لحالة الحروف
    final res = await api.post('/api/auth/login', {'username': 'AHMED', 'password': 'secret123'});
    api.token = res['token'] as String;
    final me = await api.get('/api/auth/me');
    expect(me['user']['role'], 'owner');

    await api.post('/api/auth/logout');
    await expectApiError(api.get('/api/auth/me'), 401);
  });

  test('login is throttled after repeated failures', () async {
    await setupShop();
    for (var i = 0; i < 5; i++) {
      await expectApiError(api.post('/api/auth/login', {'username': 'ahmed', 'password': 'nope'}), 401);
    }
    await expectApiError(api.post('/api/auth/login', {'username': 'ahmed', 'password': 'secret123'}), 429);
  });

  test('owner manages users; technician cannot', () async {
    api.token = await setupShop();
    final created = await api.post('/api/users', {
      'name': 'محمد',
      'username': 'mohamed',
      'password': 'tech1234',
      'role': 'technician',
    });
    final techId = created['user']['id'] as String;
    await expectApiError(
      api.post('/api/users', {'name': 'x', 'username': 'mohamed', 'password': 'tech1234', 'role': 'technician'}),
      409,
    );

    final list = await api.get('/api/users');
    expect((list['users'] as List).length, 2);

    final tech = ApiClient(api.baseUrl);
    final login = await tech.post('/api/auth/login', {'username': 'mohamed', 'password': 'tech1234'});
    tech.token = login['token'] as String;
    await expectApiError(tech.get('/api/users'), 403);

    // إيقاف الحساب بيخرجه من الأجهزة فوراً
    await api.patch('/api/users/$techId', {'active': false});
    await expectApiError(tech.get('/api/auth/me'), 401);
    await expectApiError(tech.post('/api/auth/login', {'username': 'mohamed', 'password': 'tech1234'}), 403);
    tech.close();
  });

  test('last owner cannot be demoted or deactivated', () async {
    api.token = await setupShop();
    final me = await api.get('/api/auth/me');
    final id = me['user']['id'] as String;
    await expectApiError(api.patch('/api/users/$id', {'role': 'reception'}), 400);
    await expectApiError(api.patch('/api/users/$id', {'active': false}), 400);
  });

  test('changing password keeps current session and revokes others', () async {
    final first = await setupShop();
    final other = ApiClient(api.baseUrl);
    other.token = (await other.post('/api/auth/login', {'username': 'ahmed', 'password': 'secret123'}))['token'] as String;

    api.token = first;
    await expectApiError(api.post('/api/auth/password', {'currentPassword': 'bad', 'newPassword': 'newpass1'}), 400);
    await api.post('/api/auth/password', {'currentPassword': 'secret123', 'newPassword': 'newpass1'});
    await api.get('/api/auth/me');
    await expectApiError(other.get('/api/auth/me'), 401);
    other.close();
  });

  test('audit log records actions', () async {
    api.token = await setupShop();
    await api.post('/api/users', {'name': 'سارة', 'username': 'sara', 'password': 'pass1234', 'role': 'reception'});
    final audit = await api.get('/api/audit');
    final actions = (audit['entries'] as List).map((e) => e['action']).toList();
    expect(actions, containsAll(['shop.setup', 'user.create']));
  });

  test('data survives a restart', () async {
    await setupShop();
    await server.stop();
    server = AbdulmalikErpServer(dataDir: dir.path, requestedPort: 0, cloudSync: false);
    await server.start();
    api.close();
    api = ApiClient('http://127.0.0.1:${server.port}');
    final res = await api.post('/api/auth/login', {'username': 'ahmed', 'password': 'secret123'});
    expect(res['user']['name'], 'أحمد');
  });
}
