/// قوالب الرسائل وقواعد إرسالها، دون الاعتماد على Flutter؛ ليتمكن الخادم من استخدامها.
library;

import 'ticket_status.dart';

enum MessageEvent {
  received('استلام الجهاز'),
  ready('الجهاز جاهز'),
  waitingParts('بانتظار قطع الغيار'),
  approval('طلب الموافقة على تكلفة إضافية'),
  dueChanged('تغيير الموعد المتوقع'),
  delivered('بعد التسليم'),
  reminder('تذكير بالاستلام'),
  custom('رسالة حرة');

  const MessageEvent(this.label);
  final String label;

  static MessageEvent parse(String? v) => values.firstWhere((e) => e.name == v, orElse: () => custom);

  /// الأحداث التي لها قاعدة إرسال تلقائية (جميع الأحداث باستثناء الرسالة الحرة).
  static List<MessageEvent> get automatic => values.where((e) => e != custom).toList();

  /// الحدث الذي يقع عند انتقال الجهاز إلى هذه المرحلة، إن وُجد.
  static MessageEvent? forStatus(TicketStatus s) => switch (s) {
        TicketStatus.ready => ready,
        TicketStatus.waitingParts => waitingParts,
        TicketStatus.waitingApproval => approval,
        TicketStatus.delivered => delivered,
        _ => null,
      };
}

/// طريقة الإرسال لكل حدث.
enum MessageRule {
  off('دون رسالة'),
  whatsapp('واتساب (عبر زر الإرسال)'),
  sms('رسائل نصية تلقائية');

  const MessageRule(this.label);
  final String label;

  static MessageRule parse(String? v) => values.firstWhere((r) => r.name == v, orElse: () => off);
}

const defaultMessageRules = {
  'received': 'whatsapp',
  'ready': 'whatsapp',
  'waitingParts': 'whatsapp',
  'approval': 'whatsapp',
  'dueChanged': 'off',
  'delivered': 'off',
  'reminder': 'whatsapp',
};

const defaultTemplates = {
  'received': 'مرحباً {customer} 👋\n'
      'استلمنا جهازك {device} في {shop}.\n'
      'رقم الإيصال: {number}\n'
      'رمز الاستلام: {pin} (ستحتاج إليه عند استلام الجهاز)\n'
      'الموعد المتوقع: {due}\n'
      'تابع حالة جهازك من هنا: {link}\n'
      'للاستفسار: {shop_phone}',
  'ready': 'مرحباً {customer}، جهازك {device} جاهز للاستلام ✅\n'
      'المبلغ المتبقي: {remaining}\n'
      'لا تنسَ رمز الاستلام: {pin}\n'
      '{shop} - {shop_phone}',
  'waitingParts': 'مرحباً {customer}، جهازك {device} في انتظار قطعة غيار.\n'
      'الموعد المتوقع الجديد: {due}\n'
      'نعتذر عن التأخير 🙏\n'
      '{shop}',
  'approval': 'مرحباً {customer}، أثناء فحص جهازك {device}، تبيّن للفني ما يلي:\n'
      '{approval_note}\n'
      'التكلفة الجديدة: {approval_total}\n'
      'يمكنك الموافقة أو الرفض من هنا: {link}\n'
      'أو أرسل ردك إلى {shop_phone}',
  'dueChanged': 'مرحباً {customer}، الموعد المتوقع لجهازك {device} أصبح {due}.\n'
      'تابع حالة جهازك من هنا: {link}\n'
      '{shop}',
  'delivered': 'شكراً لتعاملك مع {shop} 🙏\n'
      'تم تسليم جهازك {device}. إذا واجهت أي مشكلة، يُرجى التواصل معنا على {shop_phone}.',
  'reminder': 'مرحباً {customer}، جهازك {device} جاهز منذ {days} يوماً، ونحن بانتظارك لاستلامه ✅\n'
      'المبلغ المتبقي: {remaining}\n'
      'لا تنسَ رمز الاستلام: {pin}\n'
      '{shop} - {shop_phone}',
  'custom': 'مرحباً {customer}،\n\n{shop}',
};

/// المتغيرات المتاحة للاستخدام في القوالب مع شرحها.
const templateVariables = {
  'customer': 'اسم العميل',
  'device': 'الجهاز',
  'number': 'رقم الإيصال',
  'pin': 'رمز الاستلام',
  'status': 'حالة الجهاز الحالية',
  'due': 'الموعد المتوقع',
  'total': 'التكلفة الإجمالية',
  'paid': 'المبلغ المدفوع',
  'remaining': 'المبلغ المتبقي',
  'approval_total': 'التكلفة الجديدة (طلب الموافقة)',
  'approval_note': 'سبب التكلفة الإضافية',
  'pickup': 'موعد الاستلام المحجوز',
  'days': 'عدد الأيام منذ جاهزية الجهاز',
  'link': 'رابط متابعة الجهاز',
  'shop': 'اسم المحل',
  'shop_phone': 'رقم هاتف المحل',
};

/// يملأ القالب بالقيم. يُحذف أي سطر يحتوي على متغير لا تتوفر له قيمة
/// (مثلاً إذا لم يتوفر رابط للتتبع، سطر "تابع حالة جهازك" فلن يظهر).
String renderTemplate(String template, Map<String, String?> values) {
  final lines = <String>[];
  final pattern = RegExp(r'\{([a-z_]+)\}');
  for (final line in template.split('\n')) {
    var missing = false;
    final rendered = line.replaceAllMapped(pattern, (m) {
      final key = m.group(1)!;
      if (!values.containsKey(key)) return m.group(0)!;
      final v = values[key];
      if (v == null || v.trim().isEmpty) {
        missing = true;
        return '';
      }
      return v;
    });
    if (!missing) lines.add(rendered);
  }
  return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// يحوّل الرقم المحلي إلى الصيغة الدولية المناسبة لواتساب؛ يدعم السعودية ومصر للأرقام القديمة.
String whatsappNumber(String phone) {
  final d = normalizePhone(phone);
  if (d.startsWith('05') && d.length == 10) return '966${d.substring(1)}';
  if (d.startsWith('01') && d.length == 11) return '20${d.substring(1)}';
  return d;
}
