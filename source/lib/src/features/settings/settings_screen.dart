import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_config.dart';
import '../../core/locale.dart';
import '../../core/app_info.dart';
import '../../core/firebase_config.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/shop.dart';
import '../../core/theme.dart';
import '../../server/api_server.dart' show serverPort;
import '../../server/discovery.dart';
import '../../widgets/common.dart';
import '../messages/sms_gateway.dart';
import '../receipts/print_service.dart';
import 'audit_screen.dart';
import 'backup_screen.dart';
import 'logs_screen.dart';
import 'message_settings_screen.dart';
import 'shop_settings_screen.dart';
import '../home/about_screen.dart';

final _localIpsProvider = FutureProvider<List<String>>((ref) => localIpAddresses());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value!;
    final user = session.user!;
    final config = ref.read(appConfigProvider);
    final isServer = config.mode == AppMode.server;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final ar = locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'الإعدادات' : 'Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          SectionTitle(ar ? 'حسابي' : 'My account'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(user.name),
                subtitle: Text('${user.role.label} • @${user.username}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: Text(ar ? 'تغيير كلمة المرور' : 'Change password'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => showDialog<void>(context: context, builder: (_) => const _ChangePasswordDialog()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(ar ? 'تسجيل خروج' : 'Log out'),
                onTap: () => ref.read(sessionProvider.notifier).logout(),
              ),
            ]),
          ),
          SectionTitle(ar ? 'الاتصال' : 'Connection'),
          Card(
            child: Column(children: [
              ListTile(
                leading: Icon(isServer ? Icons.dns_rounded : Icons.wifi_rounded),
                title: Text(isServer ? (ar ? 'هذا الجهاز هو خادم المحل' : 'This PC is the shop server') : (ar ? 'متصل بخادم المحل' : 'Connected to shop server')),
                subtitle: Text(isServer ? (ar ? 'يجب إبقاء البرنامج مفتوحاً على هذا الجهاز حتى تتمكن الأجهزة الأخرى من الاتصال' : 'Keep this app running on this PC so other devices can connect') : session.api!.baseUrl,
                    textDirection: isServer ? null : TextDirection.ltr, textAlign: TextAlign.right),
              ),
              if (isServer) ...[
                const Divider(height: 1),
                const _ServerAddresses(),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: Text(isServer ? (ar ? 'تغيير طريقة تشغيل الجهاز' : 'Change device mode') : (ar ? 'تغيير السيرفر' : 'Change server')),
                subtitle: isServer ? Text(ar ? 'ستبقى بيانات المحل محفوظة على هذا الجهاز' : 'Shop data will remain on this PC') : null,
                onTap: () async {
                  final ok = await _confirm(context,
                      isServer
                          ? 'إذا غيّرت هذا الإعداد، فستنقطع الأجهزة المتصلة بهذا الحاسوب حتى تختار خادماً آخر. هل أنت متأكد؟'
                          : 'سيتم تسجيل خروجك والعودة إلى شاشة اختيار الخادم. هل أنت متأكد؟');
                  if (ok) await ref.read(sessionProvider.notifier).resetConnection();
                },
              ),
            ]),
          ),
          const SectionTitle('اللغة / Language'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {locale.languageCode},
                onSelectionChanged: (selection) =>
                    ref.read(localeProvider.notifier).setLanguage(selection.first),
              ),
            ),
          ),
          SectionTitle(ar ? 'الشكل' : 'Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(value: ThemeMode.system, label: Text(ar ? 'تلقائي' : 'System'), icon: Icon(Icons.brightness_auto_rounded)),
                  ButtonSegment(value: ThemeMode.light, label: Text(ar ? 'فاتح' : 'Light'), icon: Icon(Icons.light_mode_rounded)),
                  ButtonSegment(value: ThemeMode.dark, label: Text(ar ? 'غامق' : 'Dark'), icon: Icon(Icons.dark_mode_rounded)),
                ],
                selected: {themeMode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ),
          ),
          if (user.isOwner) ...[
            SectionTitle(ar ? 'المحل' : 'Shop'),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: Text(ar ? 'بيانات المحل والإيصال' : 'Shop and receipt settings'),
                  subtitle: Text(ar ? 'الشعار، ورقم الهاتف، والعنوان، ومقاس الورق، والشروط' : 'Logo, phone, address, paper size and receipt terms'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ShopSettingsScreen())),
                ),
                const Divider(height: 1),
                if (firebaseApiKey.isNotEmpty) const _CloudStatusTile(),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_rounded),
                  title: Text(ar ? 'النسخ الاحتياطي' : 'Backups'),
                  subtitle: Text(ar ? 'نسخ احتياطية يومية واستعادة نسخة سابقة' : 'Daily backups and restore'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const BackupScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.forum_rounded),
                  title: Text(ar ? 'رسائل العملاء' : 'Customer messages'),
                  subtitle: Text(ar ? 'إمتى تتبعت رسالة، واتساب ولا SMS، ونص كل رسالة' : 'Schedule, channel and message templates'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MessageSettingsScreen())),
                ),
              ]),
            ),
          ],
          SectionTitle(ar ? 'هذا الجهاز' : 'This device'),
          const _DeviceSettingsCard(),
          if (user.isOwner) ...[
            SectionTitle(ar ? 'المتابعة' : 'Activity'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(ar ? 'سجل النشاط' : 'Activity log'),
                subtitle: Text(ar ? 'من نفّذ الإجراء؟ وما الإجراء؟ ومتى؟' : 'Who did what and when'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AuditScreen())),
              ),
            ),
          ],
          SectionTitle(ar ? 'معلومات المشروع' : 'Project information'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: Text(ar ? 'عن المشروع والفريق' : 'About the project and team'),
              subtitle: Text(ar
                  ? 'نبذة المشروع، اللجنة الأكاديمية والاستشارية، فريق التطوير والهيكل التنظيمي'
                  : 'Project overview, academic and advisory board, development team and organization'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              ),
            ),
          ),
          SectionTitle(ar ? 'التواصل وتطوير النظام' : 'Support and product development'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.business_rounded),
                title: const Text('العصيمي للبرمجيات والحلول التقنية المتطورة'),
                subtitle: const Text('خدمات التطوير الرقمي'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                title: Text(ar ? 'التواصل عبر واتساب' : 'Contact via WhatsApp'),
                subtitle: const Text('+967 776 778 675', textDirection: TextDirection.ltr),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => launchUrl(Uri.parse('https://wa.me/967776778675'), mode: LaunchMode.externalApplication),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.code_rounded),
                title: Text(ar ? 'عن المطور' : 'About the developer'),
                subtitle: const Text('m.gh.al'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('m.gh.al — مطور برمجيات'),
                    content: const SingleChildScrollView(
                      child: Text('مطور برمجيات متخصص في تطوير الحلول التقنية المتكاملة، وتصميم وبناء الأنظمة الإدارية والتجارية المتقدمة، مع اهتمام بتطوير تطبيقات الويب والأنظمة المكتبية وقواعد البيانات. أعمل في مجال تطوير البرمجيات الشامل (Full-Stack Development)، وأركز على بناء حلول احترافية تجمع بين الأداء والاستقرار والأمان وسهولة الاستخدام.\n\nمجالات العمل: أنظمة ERP، وتطوير الواجهات الأمامية والخلفية، وNext.js، وNode.js، وواجهات API، وقواعد البيانات، وتطبيقات سطح المكتب، وهندسة البرمجيات.'),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
                  ),
                ),
              ),
            ]),
          ),
          SectionTitle(ar ? 'التشخيص' : 'Diagnostics'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(ar ? 'سجل الأعطال' : 'Diagnostic log'),
              subtitle: Text(ar ? 'إذا توقف البرنامج عن الاستجابة أو ظهر خطأ، يمكنك إرسال التفاصيل إلى مطوّر البرنامج من هنا' : 'Review app errors and diagnostic details'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LogsScreen())),
            ),
          ),
          if (trackingSiteUrl.isNotEmpty) ...[
            const SectionTitle('المساعدة'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book_rounded),
                title: const Text('دليل الاستخدام'),
                subtitle: const Text('شرح جميع وظائف البرنامج خطوة بخطوة'),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => launchUrl(Uri.parse('$trackingSiteUrl/guide'), mode: LaunchMode.externalApplication),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Text('$appName $appVersion',
                style: Theme.of(context).textTheme.bodySmall, textDirection: TextDirection.ltr),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('أيوه')),
          ],
        ),
      ) ??
      false;
}

class _ServerAddresses extends ConsumerWidget {
  const _ServerAddresses();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ips = ref.watch(_localIpsProvider).value ?? const [];
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('عنوان الخادم للأجهزة الأخرى', style: text.titleSmall?.bold),
          const SizedBox(height: 4),
          Text('تعثر الأجهزة المحمولة على الخادم تلقائياً. إذا لم يظهر، فأدخل العنوان التالي في الجهاز المحمول:', style: text.bodySmall),
          const SizedBox(height: 8),
          if (ips.isEmpty) const Text('الجهاز غير متصل بالشبكة'),
          for (final ip in ips)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SelectableText('$ip:$serverPort', textDirection: TextDirection.ltr, style: text.titleMedium?.semiBold),
                  IconButton(
                    tooltip: 'نسخ',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ip));
                      showMessage(context, 'تم نسخ العنوان');
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider).value!.api!.post('/api/auth/password', {
        'currentPassword': _current.text,
        'newPassword': _new.text,
      });
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(context, 'تم تغيير كلمة المرور وتسجيل الخروج من بقية الأجهزة.');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير كلمة المرور'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _new,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                validator: (v) => (v ?? '').length < 6 ? '6 حروف أو أرقام على الأقل' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة'),
                validator: (v) => v != _new.text ? 'القيمتان غير متطابقتين' : null,
              ),
              if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        SizedBox(width: 120, child: BusyButton(label: 'حفظ', busy: _busy, onPressed: _save)),
      ],
    );
  }
}

/// إعدادات خاصة بهذا الجهاز: طابعة الإيصالات وبوابة الرسائل النصية.
class _DeviceSettingsCard extends ConsumerStatefulWidget {
  const _DeviceSettingsCard();

  @override
  ConsumerState<_DeviceSettingsCard> createState() => _DeviceSettingsCardState();
}

class _DeviceSettingsCardState extends ConsumerState<_DeviceSettingsCard> {
  @override
  Widget build(BuildContext context) {
    final config = ref.read(appConfigProvider);
    final gateway = ref.watch(smsGatewayProvider);
    final printer = config.receiptPrinterName;

    return Card(
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.print_rounded),
          title: const Text('طابعة الوصولات'),
          subtitle: Text(printer != null
              ? 'تتم الطباعة تلقائياً على: $printer'
              : AppConfig.canHostServer
                  ? 'غير محددة؛ سيُطلب منك الاختيار في كل مرة'
                  : 'يستخدم شاشة الطباعة في الجهاز المحمول. لطابعات Bluetooth، ثبّت تطبيقاً للطباعة مثل RawBT.'),
          trailing: AppConfig.canHostServer
              ? Wrap(children: [
                  if (printer != null)
                    TextButton(
                      onPressed: () async {
                        await config.setReceiptPrinter(null, null);
                        setState(() {});
                      },
                      child: const Text('إلغاء'),
                    ),
                  FilledButton.tonal(
                    onPressed: () async {
                      await pickReceiptPrinter(context, ref);
                      if (mounted) setState(() {});
                    },
                    child: Text(printer == null ? 'اختيار' : 'تغيير'),
                  ),
                ])
              : null,
        ),
        if (SmsNative.supported) ...[
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.sms_rounded),
            title: const Text('بوابة SMS'),
            subtitle: Text(gateway.active
                ? 'يرسل هذا الهاتف رسائل العملاء باستخدام شريحته • اتبعت ${gateway.sent}${gateway.failed > 0 ? ' • فشل ${gateway.failed}' : ''}'
                    '${gateway.lastError != null ? '\nآخر خطأ: ${gateway.lastError}' : ''}\nيُرجى إبقاء التطبيق مفتوحاً لمتابعة الإرسال.'
                : 'فعّلها على جهاز محمول واحد في المحل ليكون مسؤولاً عن إرسال الرسائل النصية تلقائياً'),
            isThreeLine: gateway.active,
            value: gateway.active,
            onChanged: (v) async {
              try {
                await ref.read(smsGatewayProvider.notifier).setEnabled(v);
              } catch (e) {
                if (context.mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''), error: true);
              }
            },
          ),
        ],
      ]),
    );
  }
}

/// حالة المزامنة مع صفحة التتبع التي يصل إليها العملاء عبر رمز الاستجابة السريعة.
class _CloudStatusTile extends ConsumerStatefulWidget {
  const _CloudStatusTile();

  @override
  ConsumerState<_CloudStatusTile> createState() => _CloudStatusTileState();
}

class _CloudStatusTileState extends ConsumerState<_CloudStatusTile> {
  bool _busy = false;

  Future<void> _sync() async {
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider).value!.api!.send('POST', '/api/cloud/sync', timeout: const Duration(seconds: 60));
      ref.invalidate(shopProvider);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopProvider).value;
    final scheme = Theme.of(context).colorScheme;
    final error = shop?.cloudError;
    final last = shop?.cloudLastSync;
    return ListTile(
      leading: Icon(Icons.cloud_sync_rounded, color: error != null ? scheme.error : const Color(0xFF16A34A)),
      title: const Text('صفحة متابعة العملاء (QR)'),
      subtitle: Text([
        if (error != null) 'آخر محاولة: $error' else if (last != null) 'آخر مزامنة ${timeAgo(last)}' else 'لم تتم المزامنة بعد',
        if ((shop?.cloudPending ?? 0) > 0) 'بانتظار الإرسال: ${shop!.cloudPending} جهاز',
      ].join(' • ')),
      trailing: _busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(tooltip: 'مزامنة الآن', icon: const Icon(Icons.sync_rounded), onPressed: _sync),
    );
  }
}
