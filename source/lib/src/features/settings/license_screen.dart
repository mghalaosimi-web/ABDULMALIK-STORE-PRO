import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/format.dart';
import '../../core/locale.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/form_fields.dart';
import '../messages/message_dialog.dart';
import '../tickets/providers.dart';

String _remainingDaysLabel(int days) {
  if (days == 1) return 'يوم واحد';
  if (days == 2) return 'يومين';
  if (days >= 3 && days <= 10) return '$days أيام';
  return '$days يوماً';
}

const _planLabelsAr = {'trial': 'تجربة مجانية', 'monthly': 'شهري', 'yearly': 'سنوي', 'lifetime': 'مدى الحياة', 'custom': 'اشتراك'};
const _planLabelsEn = {'trial': 'Free trial', 'monthly': 'Monthly', 'yearly': 'Yearly', 'lifetime': 'Lifetime', 'custom': 'Custom'};

/// شريط يظهر أعلى الشاشة الرئيسية عند اقتراب انتهاء الفترة التجريبية أو الاشتراك أو انتهائهما.
class LicenseBanner extends ConsumerWidget {
  const LicenseBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(licenseProvider).value;
    final ar = ref.watch(localeProvider).languageCode == 'ar';
    if (s == null) return const SizedBox.shrink();
    final state = s['state'] as String;
    final days = s['daysLeft'] as int?;
    final scheme = Theme.of(context).colorScheme;
    String? text;
    var color = brandOrange;
    if (state == 'expired') {
      text = s['plan'] == 'trial' ? (ar ? 'انتهت الفترة التجريبية المجانية. يرجى تفعيل البرنامج لمتابعة تسجيل عمليات جديدة.' : 'The free trial has ended. Activate the app to continue creating new records.') : (ar ? 'انتهت صلاحية الاشتراك. يرجى تجديده لمتابعة تسجيل عمليات جديدة.' : 'The license has expired. Renew it to continue creating new records.');
      color = scheme.error;
    } else if (state == 'tampered') {
      text = ar ? 'تاريخ الحاسوب غير صحيح. يرجى ضبط التاريخ والوقت حتى يعمل البرنامج.' : 'The computer clock appears incorrect. Correct the date and time.';
      color = scheme.error;
    } else if (state == 'trial') {
      text = ar ? 'تجربة مجانية: يتبقى ${_remainingDaysLabel(days ?? 0)}' : 'Free trial: ${days ?? 0} days remaining';
      color = brandBlue;
    } else if (days != null && days <= 7) {
      text = ar ? 'تنتهي صلاحية الاشتراك خلال ${_remainingDaysLabel(days)}' : 'License expires in $days days';
    }
    if (text == null) return const SizedBox.shrink();
    final isOwner = ref.watch(sessionProvider).value?.user?.isOwner ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isOwner ? () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LicenseScreen())) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(state == 'trial' ? Icons.hourglass_bottom_rounded : Icons.workspace_premium_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: TextStyle(color: color).semiBold)),
              if (isOwner) Text(ar ? 'التفعيل' : 'Activate', style: TextStyle(color: color).bold),
            ]),
          ),
        ),
      ),
    );
  }
}

class LicenseScreen extends ConsumerStatefulWidget {
  const LicenseScreen({super.key});

  @override
  ConsumerState<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends ConsumerState<LicenseScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider).value!.api!.post('/api/license', {'code': _code.text.trim()});
      ref.invalidate(licenseProvider);
      _code.clear();
      if (mounted) showMessage(context, ref.read(localeProvider).languageCode == 'ar' ? 'اتيرجى تفعيل البرنامج ✅ شكراً!' : 'License activated successfully!');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(licenseProvider);
    final ar = ref.watch(localeProvider).languageCode == 'ar';
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'الاشتراك' : 'License')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: ErrorBanner(errorText(e))),
        data: (s) {
          final state = s['state'] as String;
          final exp = parseDate(s['expiresAt']);
          final device = s['deviceCode'] as String;
          final (label, color) = switch (state) {
            'active' => (ar ? 'مفعّل ✅' : 'Active ✅', const Color(0xFF16A34A)),
            'trial' => (ar ? 'تجربة مجانية' : 'Free trial', brandBlue),
            'tampered' => (ar ? 'تاريخ الجهاز غير صحيح' : 'System clock error', Theme.of(context).colorScheme.error),
            _ => (ar ? 'منتهي' : 'Expired', Theme.of(context).colorScheme.error),
          };
          final planLabels = ar ? _planLabelsAr : _planLabelsEn;
          return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label, style: text.headlineSmall?.bold.copyWith(color: color)),
                        const SizedBox(height: 6),
                        Text(ar ? 'النوع: ${planLabels[s['plan']] ?? s['plan']}' : 'Plan: ${planLabels[s['plan']] ?? s['plan']}'),
                        Text(exp == null ? (ar ? 'مدى الحياة' : 'Lifetime') : '${state == 'expired' ? (ar ? 'انتهت الصلاحية' : 'Expired') : (ar ? 'حتى' : 'Until')} ${formatDate(exp)}'
                            '${s['daysLeft'] != null && state != 'expired' ? (ar ? ' (المتبقي ${_remainingDaysLabel(s['daysLeft'] as int)})' : ' (${s['daysLeft']} days left)') : ''}'),
                        Text(ar ? 'عدد الأجهزة المسموح: ${s['devices']}' : 'Allowed devices: ${s['devices']}'),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(title: ar ? 'رمز الجهاز' : 'Device code', icon: Icons.fingerprint_rounded, children: [
                    Text(ar ? 'أرسل هذا الرمز إلى مطوّر البرنامج للحصول على رمز التفعيل:' : 'Send this code to the software owner to issue your activation key:'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: SelectableText(device, textDirection: TextDirection.ltr, style: text.headlineSmall?.bold.copyWith(letterSpacing: 3)),
                      ),
                      IconButton(
                        tooltip: ar ? 'نسخ' : 'Copy',
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: device));
                          showMessage(context, ar ? 'تم نسخ رمز الجهاز' : 'Device code copied');
                        },
                      ),
                    ]),
                    if (supportWhatsApp.isNotEmpty)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                        onPressed: () => openWhatsApp(supportWhatsApp, activationMessage(s)),
                        icon: const Icon(Icons.chat_rounded),
                        label: Text(ar ? 'ابعته واتساب لصاحب البرنامج' : 'Send to support on WhatsApp'),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  SectionCard(title: ar ? 'رمز التفعيل' : 'Activation code', icon: Icons.key_rounded, children: [
                    TextField(
                      controller: _code,
                      minLines: 3,
                      maxLines: 5,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(hintText: ar ? 'الصق رمز التفعيل هنا (يبدأ بـ AERP1.)' : 'Paste your activation code here (starts with AERP1.)'),
                    ),
                    if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
                    const SizedBox(height: 12),
                    BusyButton(label: ar ? 'تفعيل' : 'Activate', icon: Icons.verified_rounded, busy: _busy, onPressed: _activate),
                  ]),
                  const SizedBox(height: 12),
                  Text(ar ? 'عند انتهاء الاشتراك، تظل بياناتك محفوظة، ويمكنك تسليم الأجهزة الحالية والاطلاع على التقارير. يتوقف فقط تسجيل العمليات الجديدة.' : 'If the license expires, your existing data remains available. You can finish current work and view reports, but cannot create new records.',
                      style: text.bodySmall),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

/// رسالة طلب التفعيل التي تُرسل إلى مسؤول البرنامج عبر واتساب.
String activationMessage(Map<String, dynamic> s) {
  String? v(String k) {
    final x = (s[k] as String?)?.trim();
    return x == null || x.isEmpty ? null : x;
  }

  return [
    'طلب تفعيل ABDULMALIK ERP',
    if (v('shopName') != null) 'المحل: ${v('shopName')}',
    if (v('branchName') != null && v('branchName') != 'الفرع الرئيسي') 'الفرع: ${v('branchName')}',
    if (v('ownerName') != null) 'صاحب المحل: ${v('ownerName')}',
    if (v('shopPhone') != null) 'رقم الهاتف: ${v('shopPhone')}',
    'رمز الجهاز: ${s['deviceCode']}',
  ].join('\n');
}
