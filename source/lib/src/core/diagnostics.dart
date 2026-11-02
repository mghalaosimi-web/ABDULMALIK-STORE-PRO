import 'dart:async';
import 'dart:io';
import 'dart:isolate';

/// سجل المشكلات: ملف نصي صغير في مجلد البرنامج (logs). عند تجاوز حجمه 1 ميجابايت، يُنقل إلى ملف النسخة السابقة (.1).
/// لا يعتمد على Flutter، ليتمكن الخادم (الذي يعمل في Isolate مستقل) من استخدامه أيضاً.
class DiagLog {
  DiagLog(this.path);
  final String path;

  static DiagLog? app;

  static DiagLog openIn(String dataDir, String name) {
    final dir = Directory('$dataDir${Platform.pathSeparator}logs')..createSync(recursive: true);
    return DiagLog('${dir.path}${Platform.pathSeparator}$name.log');
  }

  static String logsDir(String dataDir) => '$dataDir${Platform.pathSeparator}logs';

  void write(String level, String message) {
    try {
      final f = File(path);
      if (f.existsSync() && f.lengthSync() > 1024 * 1024) {
        final old = File('$path.1');
        if (old.existsSync()) old.deleteSync();
        f.renameSync(old.path);
      }
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final stamp = '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
      File(path).writeAsStringSync('$stamp [$level] $message\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // السجل عمره ما يوقّع البرنامج
    }
  }

  void error(Object e, [StackTrace? st]) {
    final stack = st?.toString().split('\n').where((l) => l.trim().isNotEmpty).take(8).join('\n    ');
    write('ERROR', '$e${stack == null ? '' : '\n    $stack'}');
  }
}

/// مراقب التعليق: Isolate صغير شغال لوحده بيستنى "نبضة" من الشاشة كل ثانية.
/// إذا توقفت الشاشة لمدة 4 ثوانٍ أو أكثر، يُسجّل وقت التوقف ومدته وآخر إجراء نُفّذ قبله.
class FreezeWatchdog {
  static SendPort? _port;
  static String _last = 'فتح البرنامج';
  static Timer? _beat;

  /// آخر إجراء نفّذه المستخدم (مثل فتح شاشة أو إرسال طلب إلى الخادم).
  static void action(String what) => _last = what;

  static Future<void> start(String logPath) async {
    if (_port != null) return;
    final ready = ReceivePort();
    await Isolate.spawn(_watch, [ready.sendPort, logPath], debugName: 'freeze-watchdog');
    _port = await ready.first as SendPort;
    _beat = Timer.periodic(const Duration(seconds: 1), (_) => _port?.send(_last));
  }

  /// تصغير البرنامج أو إغلاق شاشة الهاتف لا يُعدّ توقفاً عن الاستجابة.
  static void paused(bool value) => _port?.send(value ? '\u0000pause' : '\u0000resume');

  static void stop() {
    _beat?.cancel();
    _port = null;
  }
}

void _watch(List<Object> args) {
  final out = args[0] as SendPort;
  final log = DiagLog(args[1] as String);
  final inbox = ReceivePort();
  out.send(inbox.sendPort);
  var lastBeat = DateTime.now();
  var lastAction = '';
  var paused = false;
  DateTime? frozenSince;

  inbox.listen((m) {
    final now = DateTime.now();
    if (m == '\u0000pause') {
      paused = true;
      return;
    }
    if (m == '\u0000resume') {
      paused = false;
      lastBeat = now;
      return;
    }
    if (frozenSince != null) {
      log.write('FREEZE', 'عادت الشاشة إلى العمل بعد توقف دام ${now.difference(frozenSince!).inSeconds} ثانية. آخر إجراء قبل التوقف: $lastAction');
      frozenSince = null;
    }
    lastBeat = now;
    lastAction = m as String;
  });

  Timer.periodic(const Duration(seconds: 1), (_) {
    if (paused || frozenSince != null) return;
    final gap = DateTime.now().difference(lastBeat);
    if (gap.inSeconds >= 4) {
      frozenSince = lastBeat;
      log.write('FREEZE', 'الشاشة متوقفة عن الاستجابة منذ ${gap.inSeconds} ثانية. آخر إجراء: $lastAction');
    }
  });
}
