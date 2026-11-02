/// مراحل الصيانة. هذا الملف مستقل عن Flutter ليستخدمه كل من الخادم والتطبيق.
enum TicketStatus {
  received('تم الاستلام'),
  diagnosing('قيد الفحص'),
  waitingApproval('في انتظار موافقة العميل'),
  waitingParts('في انتظار قطع الغيار'),
  repairing('قيد الإصلاح'),
  testing('اختبار'),
  ready('جاهز للاستلام'),
  delivered('تم التسليم'),
  cancelled('مرفوض / ملغى'),
  unrepairable('غير قابل للإصلاح');

  const TicketStatus(this.label);
  final String label;

  static TicketStatus? tryParse(String? v) {
    for (final s in values) {
      if (s.name == v) return s;
    }
    return null;
  }

  static TicketStatus parse(String? v) => tryParse(v) ?? received;

  /// المراحل الأساسية بالترتيب (التي تظهر في المخطط الزمني).
  static const flow = [received, diagnosing, repairing, testing, ready, delivered];

  /// الجهاز ما زال في المحل ويتطلب إجراءً.
  bool get isOpen => !{ready, delivered, cancelled, unrepairable}.contains(this);

  /// الجهاز مستني العميل ييجي يستلمه.
  bool get awaitingPickup => {ready, cancelled, unrepairable}.contains(this);

  /// المرحلة التالية منطقياً (للزر "المرحلة التالية").
  TicketStatus? get next => switch (this) {
        received => diagnosing,
        diagnosing => repairing,
        waitingApproval => repairing,
        waitingParts => repairing,
        repairing => testing,
        testing => ready,
        _ => null,
      };
}

const problemOptions = [
  'الشاشة',
  'البطارية',
  'الشحن',
  'سوفتوير',
  'دخول مياه',
  'السماعة / الصوت',
  'المايك',
  'الكاميرا',
  'البصمة / الفيس',
  'الشبكة / الواي فاي',
  'الزراير',
  'الغطاء الخلفي / الهيكل',
  'لا يعمل نهائياً',
];

const conditionOptions = [
  'خدوش',
  'شاشة مكسورة',
  'ضهر مكسور',
  'آثار مياه',
  'جسم معووج',
  'سبق فتحه',
];

const accessoryOptions = [
  'شاحن',
  'كابل',
  'جراب',
  'شريحة',
  'كارت ميموري',
  'العلبة',
  'سماعة',
];

enum LockType {
  none('لا يوجد'),
  pin('رقم سري'),
  pattern('نمط'),
  password('كلمة مرور');

  const LockType(this.label);
  final String label;

  static LockType parse(String? v) => values.firstWhere((t) => t.name == v, orElse: () => none);
}

enum PaymentMethod {
  cash('نقداً'),
  vodafoneCash('فودافون كاش'),
  instapay('إنستاباي'),
  card('فيزا'),
  other('أخرى');

  const PaymentMethod(this.label);
  final String label;

  static PaymentMethod parse(String? v) => values.firstWhere((m) => m.name == v, orElse: () => cash);
}

enum PaymentKind {
  deposit('عربون'),
  payment('دفعة'),
  refund('مرتجع');

  const PaymentKind(this.label);
  final String label;

  static PaymentKind parse(String? v) => values.firstWhere((k) => k.name == v, orElse: () => payment);
}

/// يوحّد تنسيق رقم الهاتف لتسهيل البحث، مع تحويل الأرقام إلى الصيغة اللاتينية وإزالة رمز الدولة.
String normalizePhone(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final ch in input.split('')) {
    final a = arabic.indexOf(ch);
    final p = persian.indexOf(ch);
    if (a >= 0) {
      b.write(a);
    } else if (p >= 0) {
      b.write(p);
    } else if (RegExp(r'[0-9]').hasMatch(ch)) {
      b.write(ch);
    }
  }
  var digits = b.toString();
  if (digits.startsWith('00')) digits = digits.substring(2);

  // توحيد أرقام السعودية إلى الصيغة المحلية، مع الإبقاء على دعم الأرقام المصرية القديمة.
  if (digits.startsWith('966') && digits.length == 12) {
    digits = '0${digits.substring(3)}';
  } else if (digits.startsWith('20') && digits.length == 12) {
    digits = '0${digits.substring(2)}';
  } else if (digits.length == 9 && digits.startsWith('5')) {
    digits = '0$digits';
  }
  return digits;
}
