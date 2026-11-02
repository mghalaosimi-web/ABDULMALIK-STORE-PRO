import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/locale.dart';
import '../../core/theme.dart';
import '../../server/discovery.dart';
import '../../widgets/common.dart';

/// الجهاز بيدوّر على سيرفر المحل في الواي فاي، أو المستخدم يكتب العنوان بإيده.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _address = TextEditingController();
  List<DiscoveredServer>? _found;
  bool _searching = false;
  String? _connectingTo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    List<DiscoveredServer> found;
    try {
      found = await discoverServers();
    } catch (_) {
      found = [];
    }
    if (!mounted) return;
    setState(() {
      _found = found;
      _searching = false;
    });
  }

  Future<void> _connect(String url) async {
    if (url.trim().isEmpty) {
      setState(() => _error = ref.read(localeProvider).languageCode == 'ar' ? 'يُرجى إدخال عنوان الخادم أولاً' : 'Enter the server address first');
      return;
    }
    setState(() {
      _connectingTo = url;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).connectTo(url);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _connectingTo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ar = ref.watch(localeProvider).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final found = _found ?? const [];

    return CenteredPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AbdulmalikErpLogo(size: 56),
          const SizedBox(height: 24),
          Text(ar ? 'الاتصال بخادم المحل' : 'Connect to shop server', style: text.titleLarge?.bold),
          const SizedBox(height: 4),
          Text(ar ? 'تأكد أن هذا الجهاز متصل بشبكة Wi-Fi نفسها وأن البرنامج مفتوح على الحاسوب الرئيسي.' : 'Make sure this device is on the shop Wi-Fi network and the app is running on the main PC.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text(ar ? 'الخوادم التي تم العثور عليها' : 'Discovered servers', style: text.titleSmall?.bold)),
              TextButton.icon(
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(ar ? 'بحث مرة أخرى' : 'Search again'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_searching)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(ar ? 'جارٍ البحث عن الخوادم في الشبكة...' : 'Searching for servers on the network...'),
                ]),
              ),
            )
          else if (found.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  ar
                      ? 'لم يتم العثور على خادم. تحقق من شبكة Wi-Fi أو أدخل العنوان أدناه (على الحاسوب: الإعدادات ← الاتصال).'
                      : 'No server found. Check Wi-Fi or enter the address below (on the PC: Settings → Connection).',
                  style: text.bodyMedium,
                ),
              ),
            )
          else
            for (final s in found)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.storefront_rounded, color: scheme.onPrimaryContainer),
                    ),
                    title: Text(s.shopName.isEmpty ? (ar ? 'محل جديد (لم يتم تسجيله بعد)' : 'New shop (not registered yet)') : s.shopName, style: text.titleSmall?.bold),
                    subtitle: Text([if (s.branchName.isNotEmpty) s.branchName, Uri.parse(s.url).host].join(' • ')),
                    trailing: _connectingTo == s.url
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: _connectingTo == null ? () => _connect(s.url) : null,
                  ),
                ),
              ),
          const SizedBox(height: 20),
          Text(ar ? 'أو أدخل العنوان يدوياً' : 'Or enter the address manually', style: text.titleSmall?.bold),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _address,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(hintText: '192.168.1.10', prefixIcon: Icon(Icons.lan_rounded)),
              onSubmitted: _connect,
            ),
          ),
          const SizedBox(height: 12),
          BusyButton(
            label: ar ? 'اتصال' : 'Connect',
            busy: _connectingTo == _address.text && _connectingTo != null,
            onPressed: _connectingTo == null ? () => _connect(_address.text) : null,
          ),
          if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(sessionProvider.notifier).resetConnection(),
            child: Text(ar ? 'رجوع' : 'Back'),
          ),
        ],
      ),
    );
  }
}
