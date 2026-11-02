/// أكواد التفعيل. الملف ده من غير Flutter لأن السيرفر وبرنامج توليد الأكواد يستخدموه.
///
/// يتكوّن الرمز من بيانات الاشتراك (JSON) وتوقيع Ed25519 باستخدام المفتاح الخاص المحفوظ لدى مالك البرنامج فقط.
/// يحتوي البرنامج على المفتاح العام للتحقق من صحة الرمز، ولا يتيح إنشاء رموز جديدة.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

const licensePublicKey = 'JqpIQ3klwMJMsUGqoJzVF1YZF/hR2hEWWwTp2t/TNzc=';
const trialDays = 14;

class LicenseData {
  LicenseData({
    required this.id,
    required this.shop,
    required this.device,
    required this.plan,
    required this.expires,
    required this.devices,
    required this.branches,
    required this.issued,
  });

  factory LicenseData.fromJson(Map<String, dynamic> j) => LicenseData(
        id: j['id'] as String,
        shop: j['shop'] as String? ?? '',
        device: j['dev'] as String,
        plan: j['plan'] as String? ?? 'custom',
        expires: j['exp'] == null ? null : DateTime.parse(j['exp'] as String),
        devices: j['devs'] as int? ?? 3,
        branches: j['br'] as int? ?? 1,
        issued: DateTime.parse(j['iat'] as String),
      );

  final String id;
  final String shop;

  /// رمز الجهاز المرتبط برمز التفعيل.
  final String device;

  /// monthly / yearly / lifetime / custom
  final String plan;

  /// null = مدى الحياة
  final DateTime? expires;

  /// أقصى عدد أجهزة (الهواتف المحمولة وكمبيوترات) تتصل بالسيرفر ده.
  final int devices;
  final int branches;
  final DateTime issued;

  Map<String, Object?> toJson() => {
        'v': 1,
        'id': id,
        'shop': shop,
        'dev': device,
        'plan': plan,
        'exp': expires?.toUtc().toIso8601String(),
        'devs': devices,
        'br': branches,
        'iat': issued.toUtc().toIso8601String(),
      };

  bool get lifetime => expires == null;
}

class LicenseException implements Exception {
  LicenseException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// "كود الجهاز" اللي المحل بيبعته لصاحب البرنامج: 10 حروف من بصمة السيرفر (XXXXX-XXXXX).
String deviceCodeFor(String serverId) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final digest = sha256.convert(utf8.encode('abdulmalik-erp-device:$serverId')).bytes;
  final chars = [for (var i = 0; i < 10; i++) alphabet[digest[i] % alphabet.length]].join();
  return '${chars.substring(0, 5)}-${chars.substring(5)}';
}

String _b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');
List<int> _unb64(String s) => base64Url.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));

/// يستخدمها برنامج إنشاء الرموز فقط، لاحتوائه على المفتاح الخاص.
Future<String> signLicense(LicenseData data, List<int> privateSeed) async {
  final payload = utf8.encode(jsonEncode(data.toJson()));
  final pair = await Ed25519().newKeyPairFromSeed(privateSeed);
  final sig = await Ed25519().sign(payload, keyPair: pair);
  return 'AERP1.${_b64(payload)}.${_b64(sig.bytes)}';
}

/// بيتأكد من التوقيع ومن إن الكود لنفس الجهاز. بيرمي LicenseException برسالة للمستخدم.
Future<LicenseData> verifyLicense(String code, {required String deviceCode, String publicKey = licensePublicKey}) async {
  final parts = code.trim().replaceAll(RegExp(r'\s'), '').split('.');
  if (parts.length != 3 || parts[0] != 'AERP1') throw LicenseException('رمز التفعيل غير صحيح');
  final List<int> payload, sig;
  try {
    payload = _unb64(parts[1]);
    sig = _unb64(parts[2]);
  } catch (_) {
    throw LicenseException('رمز التفعيل غير صحيح');
  }
  final ok = await Ed25519().verify(
    payload,
    signature: Signature(sig, publicKey: SimplePublicKey(base64.decode(publicKey), type: KeyPairType.ed25519)),
  );
  if (!ok) throw LicenseException('رمز التفعيل غير صحيح؛ التوقيع غير مطابق.');
  final data = LicenseData.fromJson(jsonDecode(utf8.decode(payload)) as Map<String, dynamic>);
  if (data.device != deviceCode) throw LicenseException('هذا الرمز مخصص لجهاز آخر (رمز جهازك: $deviceCode)');
  return data;
}
