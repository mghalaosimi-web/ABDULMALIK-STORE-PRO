/// Cloud integration is intentionally disabled until ABDULMALIK ERP has its own
/// Firebase project and credentials. The local SQLite/LAN workflow remains available.
const firebaseProjectId = '';
const firebaseApiKey = '';
const trackingSiteUrl = '';

/// مواعيد الاستلام الافتراضية عند عدم تحديد المحل لمواعيد مخصصة: جميع الأيام عدا الجمعة، من 12:00 إلى 22:00.
const defaultPickupHours = {
  'days': [0, 1, 2, 3, 4, 6], // 0 = الأحد ... 6 = السبت (5 = الجمعة)
  'from': '12:00',
  'to': '22:00',
  'slotMinutes': 30,
};
