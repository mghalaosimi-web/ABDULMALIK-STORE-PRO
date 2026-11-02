import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/locale.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../branches/branches_screen.dart';
import '../customers/customers_screen.dart';
import '../inventory/products_screen.dart';
import '../messages/sms_gateway.dart';
import '../phones/phones_screen.dart';
import '../pos/cash_screen.dart';
import '../pos/pos_screen.dart';
import '../pos/sales_screen.dart';
import '../purchases/purchases_screen.dart';
import '../reports/reports_screen.dart';
import '../services/services_screen.dart';
import '../settings/settings_screen.dart';
import '../tickets/tickets_screen.dart';
import '../users/users_screen.dart';
import 'dashboard_screen.dart';

class _Destination {
  const _Destination(
    this.label,
    this.icon,
    this.selectedIcon,
    this.builder, {
    this.roles,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;

  /// لو null يبقى متاح لكل الصلاحيات.
  final Set<Role>? roles;
}

const _staff = {Role.owner, Role.reception};

List<_Destination> _destinations(bool ar) => [
  _Destination(
    ar ? 'الرئيسية' : 'Dashboard',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard_rounded,
    () => const DashboardScreen(),
  ),
  _Destination(
    ar ? 'أمين الصندوق' : 'Cashier',
    Icons.point_of_sale_outlined,
    Icons.point_of_sale_rounded,
    () => const PosScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'الصيانة' : 'Repairs',
    Icons.phone_android_outlined,
    Icons.phone_android_rounded,
    () => const TicketsScreen(),
  ),
  _Destination(
    ar ? 'المخزون' : 'Inventory',
    Icons.inventory_2_outlined,
    Icons.inventory_2_rounded,
    () => const ProductsScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'الأكسسوارات' : 'Accessories',
    Icons.headphones_outlined,
    Icons.headphones_rounded,
    () => const ProductsScreen(accessories: true),
    roles: _staff,
  ),
  _Destination(
    ar ? 'الفواتير' : 'Invoices',
    Icons.receipt_long_outlined,
    Icons.receipt_long_rounded,
    () => const SalesScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'الهواتف المحمولة' : 'Phones',
    Icons.phone_iphone_outlined,
    Icons.phone_iphone_rounded,
    () => const PhonesScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'المحافظ' : 'Wallets',
    Icons.account_balance_outlined,
    Icons.account_balance_rounded,
    () => const ServicesScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'المشتريات' : 'Purchases',
    Icons.local_shipping_outlined,
    Icons.local_shipping_rounded,
    () => const PurchasesScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'الخزنة' : 'Cash drawer',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet_rounded,
    () => const CashScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'العملاء' : 'Customers',
    Icons.people_outline_rounded,
    Icons.people_rounded,
    () => const CustomersScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'الفروع' : 'Branches',
    Icons.hub_outlined,
    Icons.hub_rounded,
    () => const BranchesScreen(),
    roles: _staff,
  ),
  _Destination(
    ar ? 'التقارير' : 'Reports',
    Icons.insights_outlined,
    Icons.insights_rounded,
    () => const ReportsScreen(),
    roles: {Role.owner},
  ),
  _Destination(
    ar ? 'الموظفين' : 'Staff',
    Icons.badge_outlined,
    Icons.badge_rounded,
    () => const UsersScreen(),
    roles: {Role.owner},
  ),
  _Destination(
    ar ? 'الإعدادات' : 'Settings',
    Icons.settings_outlined,
    Icons.settings_rounded,
    () => const SettingsScreen(),
  ),
];

/// الهيكل الأساسي بعد الدخول: قائمة جانبية على الشاشات الكبيرة، وشريط تحت على الهاتف.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value!.user!;
    // بوابة الـ SMS (لو متفعّلة على هذا الهاتف) بتشتغل طول ما البرنامج مفتوح
    ref.watch(smsGatewayProvider);
    final ar = ref.watch(localeProvider).languageCode == 'ar';
    final items = _destinations(ar)
        .where((d) => d.roles == null || d.roles!.contains(user.role))
        .toList();
    final index = _index.clamp(0, items.length - 1);
    final page = KeyedSubtree(
      key: ValueKey(items[index].label),
      child: items[index].builder(),
    );
    final wide = MediaQuery.sizeOf(context).width >= 840;

    if (!wide) {
      // الهاتف بيشيل 5 أزرار بالكتير تحت؛ الباقي في "المزيد"
      final primary = items.length <= 5 ? items : items.take(4).toList();
      final more = items.length <= 5
          ? const <_Destination>[]
          : items.skip(4).toList();
      final inMore = index >= primary.length;
      return Scaffold(
        body: page,
        bottomNavigationBar: NavigationBar(
          selectedIndex: inMore ? primary.length : index,
          onDestinationSelected: (i) async {
            if (i < primary.length) return setState(() => _index = i);
            final picked = await showModalBottomSheet<int>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var k = 0; k < more.length; k++)
                      ListTile(
                        leading: Icon(more[k].icon),
                        title: Text(more[k].label),
                        selected: index == primary.length + k,
                        onTap: () => Navigator.pop(context, primary.length + k),
                      ),
                  ],
                ),
              ),
            );
            if (picked != null) setState(() => _index = picked);
          },
          destinations: [
            for (final d in primary)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            if (more.isNotEmpty)
              NavigationDestination(
                icon: const Icon(Icons.more_horiz_rounded),
                label: inMore ? items[index].label : (ar ? 'المزيد' : 'More'),
              ),
          ],
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          Material(
            color: scheme.surfaceContainerLowest,
            child: SizedBox(
              width: 240,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(
                        children: [
                          AbdulmalikErpLogo(size: 30, showName: false),
                          SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: _BrandName(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 1,
                              ),
                              child: ListTile(
                                dense: true,
                                visualDensity: const VisualDensity(
                                  vertical: -1,
                                ),
                                selected: i == index,
                                selectedTileColor: scheme.primaryContainer,
                                selectedColor: scheme.onPrimaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Icon(
                                  i == index
                                      ? items[i].selectedIcon
                                      : items[i].icon,
                                ),
                                title: Text(
                                  items[i].label,
                                  style:
                                      (i == index
                                              ? const TextStyle().semiBold
                                              : const TextStyle())
                                          .copyWith(fontSize: 15),
                                ),
                                onTap: () => setState(() => _index = i),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _UserFooter(user: user),
                  ],
                ),
              ),
            ),
          ),
          VerticalDivider(
            width: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          Expanded(child: page),
        ],
      ),
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'ABDULMALIK ',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const TextSpan(
              text: 'ERP',
              style: TextStyle(color: brandOrange),
            ),
          ],
        ),
        style: Theme.of(context).textTheme.titleLarge?.bold,
      ),
    );
  }
}

class _UserFooter extends ConsumerWidget {
  const _UserFooter({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ar = ref.watch(localeProvider).languageCode == 'ar';
    final roleLabel = ar
        ? user.role.label
        : switch (user.role) {
            Role.owner => 'Owner',
            Role.reception => 'Reception',
            Role.technician => 'Technician',
          };
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Text(
            user.name.characters.first,
            style: TextStyle(color: scheme.onSecondaryContainer),
          ),
        ),
        title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(roleLabel),
        trailing: IconButton(
          tooltip: ref.watch(localeProvider).languageCode == 'ar'
              ? 'خروج'
              : 'Log out',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => ref.read(sessionProvider.notifier).logout(),
        ),
      ),
    );
  }
}
