import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/session.dart';
import '../../core/locale.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// أول شاشة بعد التثبيت: هل سيعمل هذا الجهاز خادماً للمحل أم سيتصل بخادم قائم؟
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final controller = ref.read(sessionProvider.notifier);
    final locale = ref.watch(localeProvider);
    final ar = locale.languageCode == 'ar';

    return CenteredPanel(
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AbdulmalikErpLogo(size: 72),
          const SizedBox(height: 8),
          Text(ar ? 'نظام إدارة محل صيانة وبيع الهواتف' : 'Phone repair and retail shop management',
              textAlign: TextAlign.center, style: text.bodyLarge),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ar', label: Text('العربية')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (s) => ref.read(localeProvider.notifier).setLanguage(s.first),
          ),
          const SizedBox(height: 24),
          Text(ar ? 'كيف سيُستخدم هذا الجهاز؟' : 'How will this device be used?', style: text.titleLarge?.bold),
          const SizedBox(height: 12),
          if (AppConfig.canHostServer) ...[
            _ModeCard(
              isArabic: ar,
              icon: Icons.dns_rounded,
              title: ar ? 'هذا الجهاز هو الخادم الرئيسي للمحل' : 'This device will be the shop server',
              subtitle: ar ? 'ستُحفظ بيانات المحل على هذا الحاسوب، ويمكن للأجهزة الأخرى الاتصال به. اختر هذا الخيار إذا كان أول جهاز في المحل.' : 'Shop data will be stored on this computer. Other devices can connect to it. Choose this if this is the first device.',
              recommended: true,
              onTap: () => controller.chooseMode(AppMode.server),
            ),
            const SizedBox(height: 12),
          ],
          _ModeCard(
            isArabic: ar,
            icon: Icons.wifi_rounded,
            title: ar ? 'الاتصال بخادم المحل' : 'Connect to an existing shop server',
            subtitle: ar ? 'يوجد حاسوب آخر يعمل كخادم للمحل، وتريد ربط هذا الجهاز به عبر شبكة Wi-Fi نفسها.' : 'Another computer already runs the shop server. Connect this device over the same Wi-Fi network.',
            onTap: () => controller.chooseMode(AppMode.client),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.isArabic,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
  });

  final bool isArabic;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title, style: text.titleMedium?.bold),
                        if (recommended)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: brandOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(isArabic ? 'موصى به' : 'Recommended', style: text.labelSmall?.bold.copyWith(color: brandOrange)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
