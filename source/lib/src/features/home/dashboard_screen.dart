import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/locale.dart';
import '../../core/theme.dart';
import '../../core/ticket_models.dart';
import '../../widgets/common.dart';
import '../../widgets/ticket_widgets.dart';
import '../../core/messages.dart';
import '../messages/message_dialog.dart';
import '../tickets/providers.dart';
import '../tickets/tickets_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openList(BuildContext context, String scope) => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => TicketsScreen(initialScope: scope, standalone: true)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value!;
    final user = session.user!;
    final info = session.info!;
    final text = Theme.of(context).textTheme;
    final ar = ref.watch(localeProvider).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final isServer = ref.read(appConfigProvider).mode == AppMode.server;
    final stats = ref.watch(dashboardProvider);
    final s = stats.value;
    final canIntake = user.role != Role.technician;
    final greeting = ar ? (DateTime.now().hour < 12 ? 'صباح الخير' : 'مساء الخير') : (DateTime.now().hour < 12 ? 'Good morning' : 'Good evening');

    return Scaffold(
      appBar: AppBar(title: Text(ar ? '$greeting، ${user.name.split(' ').first} 👋' : '$greeting, ${user.name.split(' ').first} 👋')),
      floatingActionButton: canIntake
          ? FloatingActionButton.extended(
              onPressed: () => openIntake(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(ar ? 'استلام جهاز' : 'New repair'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.storefront_rounded, color: scheme.onPrimaryContainer, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(info.shopName ?? '', style: text.titleLarge?.bold),
                          Text(info.branchName ?? '', style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    _ConnectionChip(isServer: isServer),
                  ],
                ),
              ),
            ),
            if (stats.hasError) ...[const SizedBox(height: 12), ErrorBanner(errorText(stats.error!))],
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final columns = c.maxWidth >= 900 ? 4 : 2;
              final cards = [
                _StatCard(icon: Icons.move_to_inbox_rounded, label: ar ? 'أجهزة استُلمت اليوم' : 'Received today', value: s?.receivedToday, color: brandBlue, onTap: () => _openList(context, 'active')),
                _StatCard(icon: Icons.build_circle_rounded, label: ar ? 'قيد الإصلاح' : 'In progress', value: s?.inProgress, color: const Color(0xFF7C3AED), onTap: () => _openList(context, 'open')),
                _StatCard(icon: Icons.check_circle_rounded, label: ar ? 'بانتظار الاستلام' : 'Ready for pickup', value: s?.awaitingPickup, color: const Color(0xFF16A34A), onTap: () => _openList(context, 'pickup')),
                _StatCard(icon: Icons.warning_amber_rounded, label: ar ? 'متأخر' : 'Overdue', value: s?.overdue, color: brandOrange, onTap: () => _openList(context, 'overdue')),
              ];
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: c.maxWidth / columns / 88,
                children: cards,
              );
            }),
            if ((s?.pickupsToday ?? 0) > 0) ...[
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.event_available_rounded, color: Color(0xFF16A34A)),
                  title: Text(ar ? '${s!.pickupsToday} عميل حجز موعداً للاستلام اليوم' : '${s!.pickupsToday} customers scheduled to pick up today'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => _openList(context, 'pickupToday'),
                ),
              ),
            ],
            if (s?.salesTodayCents != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.point_of_sale_rounded, color: brandBlue),
                  title: Text(ar ? 'مبيعات اليوم' : 'Sales today'),
                  subtitle: Text(ar ? '${s!.salesTodayCount ?? 0} فاتورة' : '${s!.salesTodayCount ?? 0} invoices'
                      '${s.lowStockCount > 0 ? ' • ${s.lowStockCount} ${ar ? 'صنف أوشك على النفاد' : 'items low in stock'}' : ''}'),
                  trailing: Text(money(s.salesTodayCents!), style: text.titleLarge?.bold),
                ),
              ),
            ],
            if (s?.collectedTodayCents != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF16A34A)),
                  title: Text(ar ? 'المبالغ المحصّلة اليوم' : 'Collected today'),
                  subtitle: Text('سُلّمت للعملاء ${s!.deliveredToday} ${s.deliveredToday == 1 ? (ar ? 'جهاز' : 'device') : (ar ? 'أجهزة' : 'devices')}'),
                  trailing: Text(money(s.collectedTodayCents!), style: text.titleLarge?.bold),
                ),
              ),
            ],
            if (canIntake) const _RemindersSection(),
            _TicketPreview(title: ar ? 'عمليات الاستلام اليوم' : 'Today’s pickups', scope: 'pickupToday', onMore: () => _openList(context, 'pickupToday')),
            _TicketPreview(title: ar ? 'متأخر' : 'Overdue', scope: 'overdue', onMore: () => _openList(context, 'overdue')),
            _TicketPreview(title: ar ? 'بانتظار الاستلام' : 'Ready for pickup', scope: 'pickup', onMore: () => _openList(context, 'pickup')),
            _TicketPreview(title: user.role == Role.technician ? (ar ? 'الأجهزة المسندة إليّ' : 'My assigned repairs') : (ar ? 'آخر الأجهزة' : 'Recent repairs'), scope: 'open', onMore: () => _openList(context, 'open')),
          ],
        ),
      ),
    );
  }
}

class _TicketPreview extends ConsumerWidget {
  const _TicketPreview({required this.title, required this.scope, required this.onMore});
  final String title;
  final String scope;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(ticketsProvider((scope: scope, q: ''))).value ?? const <Ticket>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SectionTitle('$title (${list.length})')),
          if (list.length > 4) TextButton(onPressed: onMore, child: Text(ref.watch(localeProvider).languageCode == 'ar' ? 'عرض الكل' : 'View all')),
        ]),
        for (final t in list.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TicketCard(ticket: t, onTap: () => openTicket(context, t.id)),
          ),
      ],
    );
  }
}

class _ConnectionChip extends ConsumerWidget {
  const _ConnectionChip({required this.isServer});
  final bool isServer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(localeProvider).languageCode == 'ar';
    const green = Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 10, color: green),
          const SizedBox(width: 6),
          Text(isServer ? (ar ? 'الخادم يعمل' : 'Server running') : (ar ? 'متصل بالسيرفر' : 'Connected to server'), style: const TextStyle(color: green).semiBold),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final int? value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value?.toString() ?? '–', style: text.headlineSmall?.bold),
                    Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// أجهزة جاهزة من كذا يوم ومحدش جه استلمها: زرار واحد يبعت تذكير واتساب.
class _RemindersSection extends ConsumerWidget {
  const _RemindersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(remindersProvider).value ?? const <Ticket>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 12),
      SectionTitle('عملاء يلزم تذكيرهم بالاستلام (${list.length})'),
      for (final t in list.take(6))
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0x1AFF7A1A), child: Icon(Icons.notifications_active_rounded, color: brandOrange)),
            title: Text('#${t.number} • ${t.deviceName} • ${t.customerName}'),
            subtitle: Text('جاهز من ${t.daysWaiting ?? 0} يوم${t.remainingCents > 0 ? ' • باقي ${money(t.remainingCents)}' : ''}'),
            trailing: FilledButton.tonalIcon(
              onPressed: () => showMessageDialog(context, t.id, MessageEvent.reminder),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('ذكّره'),
            ),
            onTap: () => openTicket(context, t.id),
          ),
        ),
    ]);
  }
}
