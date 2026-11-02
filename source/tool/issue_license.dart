import 'dart:convert';
import 'dart:io';

import 'package:abdulmalik_erp/src/core/license.dart';
import 'package:uuid/uuid.dart';

/// Issues an offline activation code using the owner-only Ed25519 private key.
///
/// Usage:
///   dart run tool/issue_license.dart DEVICE-CODE "Shop name" lifetime [DEVICES] [BRANCHES]
///   dart run tool/issue_license.dart DEVICE-CODE "Shop name" yearly 2027-12-31 [DEVICES] [BRANCHES]
///
/// Run from the source directory. The private key is read from ../signing and is
/// deliberately not bundled with the app or stored in this repository.
Future<void> main(List<String> args) async {
  if (args.length < 3 || args.length > 6) {
    stderr.writeln('Usage: dart run tool/issue_license.dart DEVICE "SHOP NAME" PLAN [YYYY-MM-DD] [DEVICES] [BRANCHES]');
    exitCode = 64;
    return;
  }

  final device = args[0].toUpperCase();
  if (!RegExp(r'^[A-Z2-9]{5}-[A-Z2-9]{5}$').hasMatch(device)) {
    stderr.writeln('Invalid device code. Expected XXXXX-XXXXX.');
    exitCode = 64;
    return;
  }

  final shop = args[1].trim();
  if (shop.isEmpty) {
    stderr.writeln('Shop name cannot be empty.');
    exitCode = 64;
    return;
  }

  final plan = args[2].toLowerCase();
  const plans = {'monthly', 'yearly', 'lifetime', 'custom'};
  if (!plans.contains(plan)) {
    stderr.writeln('Plan must be monthly, yearly, lifetime, or custom.');
    exitCode = 64;
    return;
  }

  final optionIndex = plan == 'lifetime' ? 3 : 4;
  if (args.length > optionIndex + 2) {
    stderr.writeln('Too many arguments.');
    exitCode = 64;
    return;
  }

  DateTime? expires;
  if (plan != 'lifetime') {
    if (args.length < 4) {
      stderr.writeln('An expiry date (YYYY-MM-DD) is required for non-lifetime plans.');
      exitCode = 64;
      return;
    }
    final date = DateTime.tryParse(args[3]);
    if (date == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(args[3])) {
      stderr.writeln('Invalid expiry date. Use YYYY-MM-DD.');
      exitCode = 64;
      return;
    }
    // Expire at the end of the supplied UTC calendar date.
    expires = DateTime.utc(date.year, date.month, date.day, 23, 59, 59);
  }

  final devices = args.length > optionIndex ? int.tryParse(args[optionIndex]) : 3;
  final branches = args.length > optionIndex + 1 ? int.tryParse(args[optionIndex + 1]) : 1;
  if (devices == null || devices < 1 || devices > 100 ||
      branches == null || branches < 1 || branches > 20) {
    stderr.writeln('Devices must be 1..100 and branches must be 1..20.');
    exitCode = 64;
    return;
  }

  final keyFile = File('../signing/license-private.key');
  if (!await keyFile.exists()) {
    stderr.writeln('Private key not found: ${keyFile.path}');
    stderr.writeln('Place your offline signing key in the repository-level signing folder.');
    exitCode = 66;
    return;
  }

  late final List<int> seed;
  try {
    seed = base64.decode((await keyFile.readAsString()).trim());
  } catch (_) {
    stderr.writeln('Private key file is not valid Base64.');
    exitCode = 65;
    return;
  }
  if (seed.length != 32) {
    stderr.writeln('Invalid Ed25519 private seed: expected 32 bytes.');
    exitCode = 65;
    return;
  }

  final license = LicenseData(
    id: const Uuid().v4(),
    shop: shop,
    device: device,
    plan: plan,
    expires: expires,
    devices: devices,
    branches: branches,
    issued: DateTime.now().toUtc(),
  );

  stdout.writeln(await signLicense(license, seed));
}
