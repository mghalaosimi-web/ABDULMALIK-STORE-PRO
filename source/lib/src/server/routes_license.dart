part of 'api_server.dart';

/// الإصدار المفتوح: جميع وظائف النظام متاحة دون انتهاء أو قيود أجهزة.
extension _LicenseRoutes on AbdulmalikErpServer {
  void _registerLicenseRoutes(Router r) {
    r.get('/api/license', _authed((req, u) async => _licenseStatus()));
  }

  Future<Map<String, Object?>> _licenseStatus() async {
    final shop = db.selectOne('SELECT name, phone FROM shop LIMIT 1');
    final branch = db.selectOne('SELECT name FROM branches WHERE is_local = 1 LIMIT 1');
    final owner = db.selectOne("SELECT name FROM users WHERE role = 'owner' AND active = 1 ORDER BY created_at LIMIT 1");
    return {
      'state': 'active',
      'plan': 'open',
      'shop': shop?['name'],
      'shopName': shop?['name'],
      'shopPhone': shop?['phone'],
      'branchName': branch?['name'],
      'ownerName': owner?['name'],
      'expiresAt': null,
      'daysLeft': null,
      'devices': 999,
      'branches': 999,
      'licenseId': null,
      'tampered': false,
    };
  }

  /// لا توجد قيود ترخيص في الإصدار المفتوح.
  Future<void> _requireLicense() async {}

  /// لا توجد حدود لعدد الأجهزة في الإصدار المفتوح.
  Future<void> _checkDeviceLimit(String? deviceName) async {}
}
