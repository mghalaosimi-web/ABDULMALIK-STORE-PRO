import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/core/app_config.dart';
import 'src/core/app_info.dart';
import 'src/core/diagnostics.dart';
import 'src/core/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  Intl.defaultLocale = config.language;
  await _startDiagnostics();
  runApp(ProviderScope(
    // الأخطاء بنعرضها للمستخدم بنفسنا، فلا نريد من Riverpod إعادة المحاولة تلقائياً
    retry: (_, _) => null,
    overrides: [appConfigProvider.overrideWithValue(config)],
    child: const AbdulmalikErpApp(),
  ));
}

/// سجل المشاكل ومراقب التعليق (لو حاجة فيهم فشلت، البرنامج بيكمل عادي).
Future<void> _startDiagnostics() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final log = DiagLog.app = DiagLog.openIn(dir.path, 'app');
    log.write('INFO', 'تشغيل $appName $appVersion على ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      log.error(details.exception, details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (e, st) {
      log.error(e, st);
      return true;
    };
    WidgetsBinding.instance.addObserver(_Lifecycle());
    // لا يتجاوز حجم الصور المخزنة في الذاكرة 64 ميغابايت مهما طالت مدة تشغيل البرنامج
    PaintingBinding.instance.imageCache
      ..maximumSizeBytes = 64 << 20
      ..maximumSize = 300;
    await FreezeWatchdog.start(log.path);
  } catch (_) {}
}

/// البرنامج متصغّر أو الهاتف قافل الشاشة: لا يُعد ذلك تجمّداً للتطبيق.
class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      FreezeWatchdog.paused(state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached);
}
