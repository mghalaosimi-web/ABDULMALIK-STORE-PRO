import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/session.dart';
import '../../core/locale.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// تسجيل المحل لأول مرة على السيرفر: بيانات المحل وحساب صاحب المحل.
class CreateShopScreen extends ConsumerStatefulWidget {
  const CreateShopScreen({super.key});

  @override
  ConsumerState<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends ConsumerState<CreateShopScreen> {
  final _form = GlobalKey<FormState>();
  final _shopName = TextEditingController();
  final _shopPhone = TextEditingController();
  final _shopAddress = TextEditingController();
  final _branchName = TextEditingController(text: 'الفرع الرئيسي');
  final _ownerName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_shopName, _shopPhone, _shopAddress, _branchName, _ownerName, _username, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).completeSetup({
        'shopName': _shopName.text,
        'shopPhone': _shopPhone.text,
        'shopAddress': _shopAddress.text,
        'branchName': _branchName.text,
        'ownerName': _ownerName.text,
        'username': _username.text,
        'password': _password.text,
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v, String label) => (v == null || v.trim().isEmpty) ? (ref.read(localeProvider).languageCode == 'ar' ? 'يرجى إدخال $label' : 'Please enter $label') : null;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ar = ref.watch(localeProvider).languageCode == 'ar';
    if (_branchName.text == 'الفرع الرئيسي' || _branchName.text == 'Main branch') {
      _branchName.text = ar ? 'الفرع الرئيسي' : 'Main branch';
    }
    final isServer = ref.read(appConfigProvider).mode == AppMode.server;

    if (!isServer) {
      return CenteredPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AbdulmalikErpLogo(size: 56),
            const SizedBox(height: 24),
            Text(ar ? 'الخادم لم يجهز بعد' : 'The server is not ready yet', style: text.titleLarge?.bold, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(ar ? 'سجّل بيانات المحل أولاً من برنامج الحاسوب الذي يعمل كخادم، ثم ارجع إلى هنا.' : 'Register the shop first from the computer running as the server, then return here.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => ref.read(sessionProvider.notifier).retry(), child: Text(ar ? 'حاول مرة أخرى' : 'Try again')),
            TextButton(
              onPressed: () => ref.read(sessionProvider.notifier).resetConnection(),
              child: Text(ar ? 'اختيار خادم آخر' : 'Choose another server'),
            ),
          ],
        ),
      );
    }

    return CenteredPanel(
      maxWidth: 560,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AbdulmalikErpLogo(size: 56),
            const SizedBox(height: 24),
            Text(ar ? 'أهلاً بك! لنُسجّل بيانات المحل' : 'Welcome! Set up your shop', style: text.titleLarge?.bold),
            const SizedBox(height: 4),
            Text(ar ? 'ستظهر هذه البيانات في الفواتير ورسائل العملاء، ويمكنك تعديلها لاحقاً من الإعدادات.' : 'These details appear on receipts and customer messages. You can edit them later in Settings.'),
            SectionTitle(ar ? 'بيانات المحل' : 'Shop details'),
            TextFormField(
              controller: _shopName,
              decoration: InputDecoration(labelText: ar ? 'اسم المحل *' : 'Shop name *', prefixIcon: Icon(Icons.storefront_rounded)),
              validator: (v) => _required(v, ar ? 'اسم المحل' : 'shop name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shopPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: ar ? 'رقم هاتف المحل' : 'Shop phone', prefixIcon: Icon(Icons.call_rounded)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shopAddress,
              decoration: InputDecoration(labelText: ar ? 'العنوان' : 'Address', prefixIcon: Icon(Icons.place_rounded)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _branchName,
              decoration: InputDecoration(labelText: ar ? 'اسم الفرع' : 'Branch name', prefixIcon: Icon(Icons.account_tree_rounded)),
            ),
            const SizedBox(height: 8),
            SectionTitle(ar ? 'حساب صاحب المحل' : 'Shop owner account'),
            TextFormField(
              controller: _ownerName,
              decoration: InputDecoration(labelText: ar ? 'اسم صاحب المحل *' : 'Your name *', prefixIcon: Icon(Icons.person_rounded)),
              validator: (v) => _required(v, ar ? 'اسمك' : 'your name'),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                controller: _username,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: ar ? 'اسم المستخدم (بالإنجليزي) *' : 'Username (English) *',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) => RegExp(r'^[a-zA-Z0-9_.]{3,30}$').hasMatch(v?.trim() ?? '')
                    ? null
                     : (ar ? 'من 3 إلى 30 حرفاً إنجليزياً أو رقماً أو شرطة سفلية' : 'Use 3–30 English letters, numbers or underscores'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: ar ? 'كلمة المرور *' : 'Password *',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (v) => (v ?? '').length < 6 ? (ar ? '6 حروف أو أرقام على الأقل' : 'Use at least 6 characters') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: !_showPassword,
              decoration: InputDecoration(labelText: ar ? 'تأكيد كلمة المرور *' : 'Confirm password *', prefixIcon: Icon(Icons.lock_outline_rounded)),
              validator: (v) => v != _password.text ? (ar ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match') : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
            const SizedBox(height: 20),
            BusyButton(label: ar ? 'تسجيل المحل والبدء' : 'Create shop and continue', busy: _busy, onPressed: _submit),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => ref.read(sessionProvider.notifier).resetConnection(),
              child: Text(ar ? 'رجوع' : 'Back'),
            ),
          ],
        ),
      ),
    );
  }
}
