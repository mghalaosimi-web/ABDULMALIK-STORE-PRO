import 'package:intl/intl.dart';

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';
const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

/// Converts Arabic-Indic and Persian digits to Latin digits for consistent identifiers.
String latinDigits(String s) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = _arabicDigits.indexOf(ch);
    final p = _persianDigits.indexOf(ch);
    b.write(i >= 0 ? '$i' : p >= 0 ? '$p' : ch);
  }
  return b.toString();
}

/// يقبل رقم الهوية الوطنية أو الإقامة السعودية، مع دعم أرقام الهوية المصرية القديمة المحفوظة سابقاً.
bool isValidNationalId(String input) {
  final digits = latinDigits(input).trim();
  return RegExp(r'^[12]\d{9}$').hasMatch(digits) ||
      RegExp(r'^[23]\d{13}$').hasMatch(digits);
}

String get _locale => Intl.defaultLocale == 'en' ? 'en' : 'ar';
final _moneyFormat = NumberFormat('#,##0.##', 'en');

String money(int cents) => _locale == 'en'
    ? 'SAR ${_moneyFormat.format(cents / 100)}'
    : '${_moneyFormat.format(cents / 100)} ر.س';

/// Parses amounts such as 2,500, ٢٥٠٠, or 2500.5 into minor currency units.
int? parseMoney(String input) {
  final cleaned = latinDigits(input).replaceAll(',', '').replaceAll('٬', '').replaceAll('ج.م', '').replaceAll('ر.س', '').replaceAll('SAR', '').replaceAll(' ', '').replaceAll('٫', '.');
  if (cleaned.isEmpty) return 0;
  final v = double.tryParse(cleaned);
  if (v == null || v < 0) return null;
  return (v * 100).round();
}

String moneyInput(int cents) {
  final v = cents / 100;
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

String formatDate(DateTime d) => DateFormat('d MMMM yyyy', _locale).format(d);
String formatTime(DateTime d) => DateFormat('h:mm a', _locale).format(d);
String formatDateTime(DateTime d) =>
    _locale == 'en' ? '${formatDay(d)}, ${formatTime(d)}' : '${formatDay(d)}، ${formatTime(d)}';

String formatDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (_locale == 'en') {
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
  } else {
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff == -1) return 'أمس';
  }
  final pattern = d.year == now.year ? 'EEEE d MMMM' : 'd MMMM yyyy';
  return DateFormat(pattern, _locale).format(d);
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return _locale == 'en' ? 'Just now' : 'الآن';
  if (diff.inMinutes < 60) {
    final n = diff.inMinutes;
    return _locale == 'en' ? '${n}m ago' : 'من ${_count(n, 'دقيقة', 'دقيقتين', 'دقائق')}';
  }
  if (diff.inHours < 24) {
    final n = diff.inHours;
    return _locale == 'en' ? '${n}h ago' : 'من ${_count(n, 'ساعة', 'ساعتين', 'ساعات')}';
  }
  if (diff.inDays < 30) {
    final n = diff.inDays;
    return _locale == 'en' ? '${n}d ago' : 'من ${_count(n, 'يوم', 'يومين', 'أيام')}';
  }
  return formatDate(d);
}

String _count(int n, String one, String two, String many) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n <= 10) return '$n $many';
  return '$n $one';
}

DateTime? parseDate(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
