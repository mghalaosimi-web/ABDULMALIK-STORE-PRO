import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/format.dart';
import '../../core/pos_models.dart';
import '../../core/product_sections.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/barcode_scan.dart';
import '../../widgets/common.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/suggest_field.dart';
import '../../widgets/ticket_widgets.dart';
import '../pos/providers.dart';
import '../receipts/print_service.dart';
import '../phones/phones_screen.dart';
import 'import_screen.dart';


const _productTemplates = <({String label, String category, int cost, int price, bool serialized, int warranty})>[
  (label: 'هاتف ذكي', category: 'أجهزة محمولة', cost: 52000, price: 69900, serialized: true, warranty: 12),
  (label: 'هاتف اقتصادي', category: 'أجهزة محمولة', cost: 35000, price: 46500, serialized: true, warranty: 12),
  (label: 'شاحن سريع 25 واط', category: 'شواحن', cost: 5500, price: 9900, serialized: false, warranty: 3),
  (label: 'سماعة لاسلكية', category: 'سماعات', cost: 8500, price: 15400, serialized: false, warranty: 3),
  (label: 'كابل USB-C', category: 'كابلات', cost: 1200, price: 2500, serialized: false, warranty: 0),
  (label: 'غطاء هاتف', category: 'أغطية وحافظات', cost: 2500, price: 5900, serialized: false, warranty: 0),
  (label: 'واقي شاشة زجاجي', category: 'حماية الشاشة', cost: 1500, price: 4500, serialized: false, warranty: 0),
  (label: 'بطارية هاتف', category: 'بطاريات وقطع', cost: 4500, price: 9500, serialized: false, warranty: 1),
  (label: 'باور بانك 10000mAh', category: 'الأكسسوارات::أخرى', cost: 10500, price: 16000, serialized: false, warranty: 6),
  (label: 'قطعة غيار شاشة', category: 'قطع غيار', cost: 9000, price: 14500, serialized: false, warranty: 1),
];
const _demoProducts = <({String name, String category, int cost, int price, int qty, bool serialized, int warranty})>[
  (name: 'عينة تجريبية — Samsung Galaxy A17 4G 128GB', category: 'أجهزة محمولة', cost: 56000, price: 69900, qty: 0, serialized: true, warranty: 12),
  (name: 'عينة تجريبية — Samsung Galaxy A07 64GB', category: 'أجهزة محمولة', cost: 37000, price: 46500, qty: 0, serialized: true, warranty: 12),
  (name: 'عينة تجريبية — شاحن Samsung USB-C 25W', category: 'الأكسسوارات::شواحن', cost: 5500, price: 9900, qty: 3, serialized: false, warranty: 3),
  (name: 'عينة تجريبية — سماعة Galaxy Buds Core', category: 'الأكسسوارات::سماعات', cost: 9000, price: 15400, qty: 2, serialized: false, warranty: 3),
  (name: 'عينة تجريبية — سماعة سلكية USB-C', category: 'الأكسسوارات::سماعات', cost: 1800, price: 3100, qty: 4, serialized: false, warranty: 1),
  (name: 'عينة تجريبية — كابل USB-C سريع 1 متر', category: 'الأكسسوارات::كابلات', cost: 1200, price: 2500, qty: 5, serialized: false, warranty: 0),
  (name: 'عينة تجريبية — غطاء حماية شفاف', category: 'الأكسسوارات::أغطية وحافظات', cost: 2500, price: 5900, qty: 4, serialized: false, warranty: 0),
  (name: 'عينة تجريبية — واقي شاشة زجاجي', category: 'الأكسسوارات::حماية الشاشة', cost: 1500, price: 4500, qty: 6, serialized: false, warranty: 0),
  (name: 'عينة تجريبية — باور بانك 10000mAh', category: 'الأكسسوارات::أخرى', cost: 10500, price: 16000, qty: 2, serialized: false, warranty: 6),
  (name: 'عينة تجريبية — بطارية هاتف', category: 'الأكسسوارات::بطاريات وقطع', cost: 4500, price: 9500, qty: 2, serialized: false, warranty: 1),
  (name: 'عينة تجريبية — شاشة بديلة لهاتف', category: 'قطع غيار', cost: 9000, price: 14500, qty: 1, serialized: false, warranty: 1),
  (name: 'عينة تجريبية — خدمة تركيب واقي شاشة', category: 'خدمات', cost: 0, price: 2500, qty: 0, serialized: false, warranty: 0),
];
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key, this.accessories = false});

  final bool accessories;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _category;
  bool _lowOnly = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _addDemoProducts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منتجات تجريبية'),
        content: const Text('ستُضاف عينة من الهواتف والسماعات والشواحن والكابلات والحماية وقطع الغيار والخدمات، مع أسعار وكميات افتراضية. ستظهر باسم «عينة تجريبية»، ويمكنك تعديلها أو إيقافها لاحقاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة العينات')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    var added = 0;
    final api = ref.read(sessionProvider).value!.api!;
    try {
      final existing = await api.get('/api/products', query: {'q': 'عينة تجريبية', 'limit': '500'});
      final existingNames = ((existing['products'] as List?) ?? const [])
          .map((item) => (item as Map)['name'] as String)
          .toSet();
      for (final item in _demoProducts) {
        if (existingNames.contains(item.name)) continue;
        await api.post('/api/products', {
          'name': item.name, 'category': item.category, 'costCents': item.cost,
          'priceCents': item.price, 'qty': item.qty, 'lowStock': 1,
          'trackStock': true, 'serialized': item.serialized, 'warrantyMonths': item.warranty,
          'notes': 'بيانات تجريبية — يمكن تعديلها أو إيقاف الصنف.',
        });
        added++;
      }
      ref.invalidate(productsProvider);
      ref.invalidate(categoriesProvider);
      if (mounted) showMessage(context, 'تمت إضافة $added منتج تجريبي. يمكنك البحث عن «عينة تجريبية» لإدارتها.');
    } catch (e) {
      ref.invalidate(productsProvider);
      ref.invalidate(categoriesProvider);
      if (mounted) showMessage(context, 'تمت إضافة $added من ${_demoProducts.length}؛ تعذرت متابعة البقية: ${errorText(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value!.user!;
    final data = ref.watch(productsProvider((q: _query, category: _category, low: _lowOnly, section: widget.accessories ? 'accessories' : 'general')));
    final allCategories = ref.watch(categoriesProvider).value ?? const <String>[];
    final categories = allCategories
        .where((c) => widget.accessories ? isAccessoriesCategory(c) : !isAccessoriesCategory(c))
        .map((c) => widget.accessories ? visibleProductCategory(c) : c)
        .toList();
    final scheme = Theme.of(context).colorScheme;
    final r = data.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accessories ? 'الأكسسوارات' : 'المخزون'),
        actions: [
          if (user.isOwner && !widget.accessories)
            TextButton.icon(
              onPressed: _addDemoProducts,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('إضافة عينات تجريبية'),
            ),
          if (user.isOwner && !widget.accessories)
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ImportScreen())),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('استيراد من Excel'),
            ),
          IconButton(
            tooltip: 'طباعة رمز شريطي',
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: r == null || r.items.isEmpty
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (_) => _LabelsDialog(products: r.items.where((p) => p.barcode != null).toList()),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(context: context, builder: (_) => ProductDialog(accessories: widget.accessories)),
        icon: const Icon(Icons.add_rounded),
        label: Text(widget.accessories ? 'إضافة ملحق' : 'صنف جديد'),
      ),
      body: Column(
        children: [
          if (r != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('${r.count} صنف', style: const TextStyle().semiBold),
                  if (r.lowCount > 0)
                    InkWell(
                      onTap: () => setState(() => _lowOnly = !_lowOnly),
                      child: Text('${r.lowCount} أوشك على النفاد', style: TextStyle(color: scheme.error).semiBold),
                    ),
                  if (r.stockValueCents != null) Text('قيمة المخزون (بسعر الشراء): ${money(r.stockValueCents!)}'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الرمز الشريطي',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: cameraScanSupported
                    ? IconButton(
                        icon: const Icon(Icons.photo_camera_rounded),
                        onPressed: () async {
                          final code = await scanBarcode(context);
                          if (code != null) {
                            _search.text = code;
                            setState(() => _query = code);
                          }
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _query = v.trim()));
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: FilterChip(label: const Text('أوشك على النفاد'), selected: _lowOnly, onSelected: (v) => setState(() => _lowOnly = v)),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    label: const Text('كل الأقسام'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(label: Text(c), selected: (widget.accessories ? visibleProductCategory(_category) : _category) == c, onSelected: (_) => setState(() => _category = widget.accessories ? storedAccessoriesCategory(c) : c)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: data.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(padding: const EdgeInsets.all(20), child: ErrorBanner(errorText(e))),
              ),
              data: (r) => r.items.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: _query.isEmpty && _category == null && !_lowOnly
                          ? (widget.accessories ? 'لا توجد أكسسوارات حتى الآن.\nابدأ بإضافة أول ملحق وتحديد تصنيفه.' : 'لا توجد أصناف حتى الآن.\nأضف صنفاً جديداً، أو استورد الأصناف من ملف Excel من برنامجك السابق.')
                          : 'لا توجد أصناف هنا',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: r.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, i) => _ProductRow(product: r.items[i], showCost: user.isOwner, accessories: widget.accessories),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.showCost, required this.accessories});
  final Product product;
  final bool showCost;
  final bool accessories;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(p.name, style: const TextStyle().semiBold),
        subtitle: Text([if ((p.category ?? '').isNotEmpty) visibleProductCategory(p.category), if (p.barcode != null) p.barcode!, if (showCost) 'سعر الشراء ${money(p.costCents)}'].join(' • ')),
        leading: p.imageFileId != null
            ? _ProductImageThumbnail(fileId: p.imageFileId!, size: 52)
            : p.trackStock && !p.serialized
                ? IconButton.filledTonal(
                    tooltip: 'إضافة كمية واردة',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => showDialog<void>(context: context, builder: (_) => AddStockDialog(product: p)),
                  )
                : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(money(p.priceCents), style: TextStyle(color: scheme.primary).bold),
            if (p.trackStock)
              Text(
                p.outOfStock ? 'نفدت الكمية' : 'متاح ${p.qty}',
                style: TextStyle(fontSize: 12, color: p.isLow ? scheme.error : scheme.onSurfaceVariant).semiBold,
              ),
          ],
        ),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => ProductDialog(product: p, accessories: accessories),
        ),
      ),
    );
  }
}


typedef _PhoneTemplate = ({String brand, String series, String name});
const _phoneTemplates = <_PhoneTemplate>[
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S26 Ultra'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S26+'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S26'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S25 Ultra'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S25+'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S25'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S25 FE'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S24 Ultra'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S24+'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S24'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S24 FE'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S23 Ultra'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S23+'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S23'),
  (brand: 'Samsung', series: 'Galaxy S', name: 'Samsung Galaxy S23 FE'),
  (brand: 'Samsung', series: 'Galaxy Note', name: 'Samsung Galaxy Note20 Ultra'),
  (brand: 'Samsung', series: 'Galaxy Note', name: 'Samsung Galaxy Note20'),
  (brand: 'Samsung', series: 'Galaxy Note', name: 'Samsung Galaxy Note10+'),
  (brand: 'Samsung', series: 'Galaxy Note', name: 'Samsung Galaxy Note10'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A57'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A56 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A55 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A54 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A53 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A37'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A36 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A35 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A34 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A26 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A25 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A17 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A17 4G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A16 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A16 4G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A15 5G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A15 4G'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A07'),
  (brand: 'Samsung', series: 'Galaxy A', name: 'Samsung Galaxy A06'),
  (brand: 'Samsung', series: 'Galaxy Z', name: 'Samsung Galaxy Z Fold7'),
  (brand: 'Samsung', series: 'Galaxy Z', name: 'Samsung Galaxy Z Flip7'),
  (brand: 'Samsung', series: 'Galaxy Z', name: 'Samsung Galaxy Z Fold6'),
  (brand: 'Samsung', series: 'Galaxy Z', name: 'Samsung Galaxy Z Flip6'),
  (brand: 'Samsung', series: 'Galaxy Z', name: 'Samsung Galaxy Z Fold5'),
  (brand: 'Samsung', series: 'Galaxy Z', name: 'Samsung Galaxy Z Flip5'),
  (brand: 'Samsung', series: 'Galaxy M', name: 'Samsung Galaxy M56 5G'),
  (brand: 'Samsung', series: 'Galaxy M', name: 'Samsung Galaxy M55 5G'),
  (brand: 'Samsung', series: 'Galaxy M', name: 'Samsung Galaxy M35 5G'),
  (brand: 'Samsung', series: 'Galaxy M', name: 'Samsung Galaxy M15 5G'),
  (brand: 'Apple', series: 'iPhone 17', name: 'Apple iPhone 17 Pro Max'),
  (brand: 'Apple', series: 'iPhone 17', name: 'Apple iPhone 17 Pro'),
  (brand: 'Apple', series: 'iPhone 17', name: 'Apple iPhone 17 Plus'),
  (brand: 'Apple', series: 'iPhone 17', name: 'Apple iPhone 17'),
  (brand: 'Apple', series: 'iPhone 17', name: 'Apple iPhone 17 Air'),
  (brand: 'Apple', series: 'iPhone 16', name: 'Apple iPhone 16 Pro Max'),
  (brand: 'Apple', series: 'iPhone 16', name: 'Apple iPhone 16 Pro'),
  (brand: 'Apple', series: 'iPhone 16', name: 'Apple iPhone 16 Plus'),
  (brand: 'Apple', series: 'iPhone 16', name: 'Apple iPhone 16'),
  (brand: 'Apple', series: 'iPhone 16', name: 'Apple iPhone 16e'),
  (brand: 'Apple', series: 'iPhone 15', name: 'Apple iPhone 15 Pro Max'),
  (brand: 'Apple', series: 'iPhone 15', name: 'Apple iPhone 15 Pro'),
  (brand: 'Apple', series: 'iPhone 15', name: 'Apple iPhone 15 Plus'),
  (brand: 'Apple', series: 'iPhone 15', name: 'Apple iPhone 15'),
  (brand: 'Apple', series: 'iPhone 14', name: 'Apple iPhone 14 Pro Max'),
  (brand: 'Apple', series: 'iPhone 14', name: 'Apple iPhone 14 Pro'),
  (brand: 'Apple', series: 'iPhone 14', name: 'Apple iPhone 14 Plus'),
  (brand: 'Apple', series: 'iPhone 14', name: 'Apple iPhone 14'),
  (brand: 'Apple', series: 'iPhone 13', name: 'Apple iPhone 13 Pro Max'),
  (brand: 'Apple', series: 'iPhone 13', name: 'Apple iPhone 13 Pro'),
  (brand: 'Apple', series: 'iPhone 13', name: 'Apple iPhone 13'),
  (brand: 'Apple', series: 'iPhone 13', name: 'Apple iPhone 13 mini'),
  (brand: 'Apple', series: 'iPhone 12', name: 'Apple iPhone 12 Pro Max'),
  (brand: 'Apple', series: 'iPhone 12', name: 'Apple iPhone 12 Pro'),
  (brand: 'Apple', series: 'iPhone 12', name: 'Apple iPhone 12'),
  (brand: 'Apple', series: 'iPhone 12', name: 'Apple iPhone 12 mini'),
  (brand: 'Honor', series: 'Magic', name: 'HONOR Magic8 Pro'),
  (brand: 'Honor', series: 'Magic', name: 'HONOR Magic8'),
  (brand: 'Honor', series: 'Magic', name: 'HONOR Magic7 Pro'),
  (brand: 'Honor', series: 'Magic', name: 'HONOR Magic7'),
  (brand: 'Honor', series: 'Magic', name: 'HONOR Magic6 Pro'),
  (brand: 'Honor', series: 'Magic', name: 'HONOR Magic V3'),
  (brand: 'Honor', series: 'Magic', name: 'HONOR Magic V2'),
  (brand: 'Honor', series: 'Number', name: 'HONOR 400 Pro'),
  (brand: 'Honor', series: 'Number', name: 'HONOR 400'),
  (brand: 'Honor', series: 'Number', name: 'HONOR 200 Pro'),
  (brand: 'Honor', series: 'Number', name: 'HONOR 200'),
  (brand: 'Honor', series: 'Number', name: 'HONOR 90'),
  (brand: 'Honor', series: 'X', name: 'HONOR X9d'),
  (brand: 'Honor', series: 'X', name: 'HONOR X9c'),
  (brand: 'Honor', series: 'X', name: 'HONOR X9b'),
  (brand: 'Honor', series: 'X', name: 'HONOR X8c'),
  (brand: 'Honor', series: 'X', name: 'HONOR X8b'),
  (brand: 'Honor', series: 'X', name: 'HONOR X7c'),
  (brand: 'Honor', series: 'X', name: 'HONOR X7b'),
  (brand: 'Honor', series: 'X', name: 'HONOR X6b'),
  (brand: 'Honor', series: 'Play', name: 'HONOR Play9T'),
  (brand: 'Honor', series: 'Play', name: 'HONOR Play8T'),
];

const _customPhoneTemplatesKey = 'abdulmalik_custom_phone_templates_v1';

Future<_PhoneTemplate?> _showPhoneTemplatePicker(BuildContext context) =>
    showDialog<_PhoneTemplate>(context: context, builder: (_) => const _PhoneTemplatePicker());

class _PhoneTemplatePicker extends StatefulWidget {
  const _PhoneTemplatePicker();
  @override
  State<_PhoneTemplatePicker> createState() => _PhoneTemplatePickerState();
}

class _PhoneTemplatePickerState extends State<_PhoneTemplatePicker> {
  final _search = TextEditingController();
  String _brand = 'Samsung';
  String? _series;
  final List<_PhoneTemplate> _customTemplates = [];
  bool _loadingCustom = true;
  List<_PhoneTemplate> get _allTemplates => [..._phoneTemplates, ..._customTemplates];

  @override
  void initState() { super.initState(); _loadCustomTemplates(); }

  Future<void> _loadCustomTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customPhoneTemplatesKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List;
        _customTemplates.addAll(decoded.map((item) {
          final map = item as Map<String, dynamic>;
          return (brand: map['brand'] as String, series: map['series'] as String, name: map['name'] as String);
        }));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCustom = false);
  }

  Future<void> _addCustomTemplate() async {
    final brand = TextEditingController(text: _brand);
    final series = TextEditingController(text: _series ?? 'فئة مخصصة');
    final name = TextEditingController();
    final result = await showDialog<_PhoneTemplate>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة طراز هاتف جديد'),
        content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: brand, decoration: const InputDecoration(labelText: 'الشركة المصنعة')),
          const SizedBox(height: 8),
          TextField(controller: series, decoration: const InputDecoration(labelText: 'الفئة أو السلسلة')),
          const SizedBox(height: 8),
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'اسم الطراز الكامل')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            if (brand.text.trim().isEmpty || name.text.trim().isEmpty) return;
            Navigator.pop(dialogContext, (
              brand: brand.text.trim(),
              series: series.text.trim().isEmpty ? 'فئة مخصصة' : series.text.trim(),
              name: name.text.trim(),
            ));
          }, child: const Text('إضافة القالب')),
        ],
      ),
    );
    brand.dispose(); series.dispose(); name.dispose();
    if (result == null) return;
    if (_allTemplates.any((item) => item.name.toLowerCase() == result.name.toLowerCase())) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الطراز موجود بالفعل في القائمة')));
      return;
    }
    setState(() { _customTemplates.add(result); _brand = result.brand; _series = result.series; _search.clear(); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customPhoneTemplatesKey, jsonEncode(_customTemplates.map((item) => {
      'brand': item.brand, 'series': item.series, 'name': item.name,
    }).toList()));
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final templates = _allTemplates;
    final brands = templates.map((e) => e.brand).toSet().toList()..sort();
    final series = templates.where((e) => e.brand == _brand).map((e) => e.series).toSet().toList()..sort();
    final q = _search.text.trim().toLowerCase();
    final items = templates.where((e) => e.brand == _brand &&
      (_series == null || e.series == _series) && (q.isEmpty || e.name.toLowerCase().contains(q))).toList();
    return AlertDialog(
      title: const Text('اختيار طراز الهاتف'),
      content: SizedBox(width: 520, height: 540, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final b in brands) ChoiceChip(label: Text(b), selected: _brand == b, onSelected: (_) => setState(() { _brand=b; _series=null; })),
        ]),
        const SizedBox(height: 10),
        TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن اسم الطراز أو رقمه'), onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: [
          Padding(padding: const EdgeInsetsDirectional.only(end: 6), child: ChoiceChip(label: const Text('كل الفئات'), selected: _series == null, onSelected: (_) => setState(() => _series=null))),
          for (final s in series) Padding(padding: const EdgeInsetsDirectional.only(end: 6), child: ChoiceChip(label: Text(s), selected: _series == s, onSelected: (_) => setState(() => _series=s))),
        ])),
        const SizedBox(height: 8),
        Expanded(child: _loadingCustom ? const Center(child: CircularProgressIndicator()) :
          items.isEmpty ? const Center(child: Text('لا توجد نتائج مطابقة')) :
          ListView.separated(
            itemCount: items.length, separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(dense: true, leading: const Icon(Icons.phone_android_rounded),
              title: Text(items[i].name), subtitle: Text(items[i].series),
              trailing: _customTemplates.contains(items[i]) ? const Icon(Icons.bookmark_added_outlined, size: 18) : null,
              onTap: () => Navigator.pop(context, items[i])),
          )),
        Text('${items.length} طرازاً في القائمة', textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall),
      ])),
      actions: [
        TextButton.icon(onPressed: _addCustomTemplate, icon: const Icon(Icons.add), label: const Text('إضافة طراز جديد')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      ],
    );
  }
}

/// إضافة صنف أو تعديله، ومنه الجرد وحركة المخزون.
class _ProductImageThumbnail extends ConsumerWidget {
  const _ProductImageThumbnail({required this.fileId, this.size = 64});
  final String fileId;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(sessionProvider).value!.api!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        '${api.baseUrl}/api/files/$fileId', width: size, height: size, fit: BoxFit.cover,
        headers: {'authorization': 'Bearer ${api.token}'},
        errorBuilder: (_, _, _) => Container(width: size, height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}

class ProductDialog extends ConsumerStatefulWidget {
  const ProductDialog({super.key, this.product, this.initialBarcode, this.accessories = false});
  final Product? product;
  final String? initialBarcode;
  final bool accessories;

  @override
  ConsumerState<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<ProductDialog> {
  final _form = GlobalKey<FormState>();
  late final p = widget.product;
  late final _name = TextEditingController(text: p?.name);
  late final _barcode = TextEditingController(text: p?.barcode ?? widget.initialBarcode);
  late final _category = TextEditingController(text: widget.accessories ? visibleProductCategory(p?.category) : p?.category);
  late final _cost = TextEditingController(text: p == null ? '' : moneyInput(p!.costCents));
  late final _price = TextEditingController(text: p == null ? '' : moneyInput(p!.priceCents));
  late final _qty = TextEditingController(text: p == null ? '' : '${p!.qty}');
  late final _low = TextEditingController(text: '${p?.lowStock ?? 2}');
  late bool _track = p?.trackStock ?? true;
  late bool _serialized = p?.serialized ?? false;
  late final _warranty = TextEditingController(text: '${p?.warrantyMonths ?? 0}');
  bool _busy = false;
  String? _error;
  String? _imageFileId;
  bool _imageChanged = false;

  @override
  void initState() { super.initState(); _imageFileId = p?.imageFileId; }

  bool get _isNew => p == null;

  @override
  void dispose() {
    for (final c in [_name, _barcode, _category, _cost, _price, _qty, _low, _warranty]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generateBarcode() async {
    final res = await ref.read(sessionProvider).value!.api!.post('/api/products/barcode');
    setState(() => _barcode.text = res['barcode'] as String);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (widget.accessories && _category.text.trim().isEmpty) {
      setState(() => _error = 'يرجى تحديد تصنيف الملحق أولاً');
      return;
    }
    final isOwner = ref.read(sessionProvider).value!.user!.isOwner;
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = ref.read(sessionProvider).value!.api!;
    try {
      final body = {
        'name': _name.text,
        'barcode': _barcode.text,
        'category': widget.accessories ? storedAccessoriesCategory(_category.text) : _category.text,
        if (isOwner || _isNew) 'costCents': parseMoney(_cost.text) ?? 0,
        'priceCents': parseMoney(_price.text) ?? 0,
        'lowStock': int.tryParse(latinDigits(_low.text)) ?? 0,
        'trackStock': _track,
        'serialized': _serialized,
        'warrantyMonths': int.tryParse(latinDigits(_warranty.text)) ?? 0,
        if (_imageChanged) 'imageFileId': _imageFileId,
      };
      if (_isNew) {
        await api.post('/api/products', {...body, 'qty': int.tryParse(latinDigits(_qty.text)) ?? 0});
      } else {
        await api.patch('/api/products/${p!.id}', body);
        final newQty = int.tryParse(latinDigits(_qty.text));
        if (isOwner && newQty != null && newQty != p!.qty) {
          await api.post('/api/products/${p!.id}/adjust', {'setQty': newQty, 'reason': 'count', 'note': 'تعديل من شاشة الصنف'});
        }
      }
      ref.invalidate(productsProvider);
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(context, _isNew ? 'تمت إضافة "${_name.text}"' : 'تم الحفظ');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive() async {
    await ref.read(sessionProvider).value!.api!.patch('/api/products/${p!.id}', {'active': false});
    ref.invalidate(productsProvider);
    ref.invalidate(categoriesProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value!.user!;
    final categories = ref.watch(categoriesProvider).value ?? const <String>[];
    final canEditQty = _isNew || user.isOwner;
    return AlertDialog(
      title: Text(_isNew ? 'صنف جديد' : p!.name),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isNew)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Wrap(spacing: 8, runSpacing: 4, children: [
                      TextButton.icon(
                        onPressed: () async {
                          final selected = await _showPhoneTemplatePicker(context);
                          if (selected == null || !mounted) return;
                          setState(() {
                            _name.text = selected.name;
                            _category.text = 'أجهزة محمولة';
                            _serialized = true;
                            _track = true;
                            _warranty.text = '12';
                            _qty.text = '0';
                          });
                        },
                        icon: const Icon(Icons.phone_android_rounded, size: 18),
                        label: const Text('قوالب الهواتف حسب الشركة'),
                      ),
                      PopupMenuButton<int>(
                        tooltip: 'قوالب المنتجات العامة',
                        onSelected: (index) {
                          final t = _productTemplates[index];
                          setState(() {
                            _name.text = t.label; _category.text = t.category;
                            _cost.text = (t.cost / 100).toStringAsFixed(2);
                            _price.text = (t.price / 100).toStringAsFixed(2);
                            _serialized = t.serialized; _track = true;
                            _warranty.text = '${t.warranty}';
                            if (t.serialized) _qty.text = '0';
                          });
                        },
                        itemBuilder: (_) => [for (var i=0; i<_productTemplates.length; i++) PopupMenuItem(value:i, child:Text(_productTemplates[i].label))],
                        child: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.dashboard_customize_outlined, size: 18), SizedBox(width: 6),
                          Text('قوالب المنتجات الأخرى'), Icon(Icons.arrow_drop_down),
                        ])),
                      ),
                    ]),
                  ),
                TextFormField(
                  controller: _name,
                  autofocus: _isNew,
                  decoration: const InputDecoration(labelText: 'اسم الصنف *'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'يُرجى إدخال اسم الصنف' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcode,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'الرمز الشريطي (امسحه بالقارئ أو اتركه فارغاً)',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cameraScanSupported)
                          IconButton(
                            icon: const Icon(Icons.photo_camera_rounded),
                            onPressed: () async {
                              final c = await scanBarcode(context);
                              if (c != null) setState(() => _barcode.text = c);
                            },
                          ),
                        IconButton(tooltip: 'إنشاء رمز شريطي جديد', icon: const Icon(Icons.auto_awesome_rounded), onPressed: _generateBarcode),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  if (_imageFileId != null)
                    _ProductImageThumbnail(fileId: _imageFileId!, size: 88)
                  else
                    Container(width: 88, height: 88,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.image_outlined, size: 34)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('صورة الصنف', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('اختر صورة من الجهاز أو التقطها. تُحفظ على خادم المحل.', style: Theme.of(context).textTheme.bodySmall),
                    TextButton.icon(
                      onPressed: _busy ? null : () async {
                        try {
                          final id = await captureAndUploadPhoto(context, ref, 'product');
                          if (id != null && mounted) setState(() { _imageFileId = id; _imageChanged = true; });
                        } catch (e) { if (context.mounted) showMessage(context, errorText(e)); }
                      },
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(_imageFileId == null ? 'إضافة صورة' : 'تغيير الصورة'),
                    ),
                    if (_imageFileId != null)
                      TextButton.icon(
                        onPressed: _busy ? null : () => setState(() { _imageFileId = null; _imageChanged = true; }),
                        icon: const Icon(Icons.delete_outline), label: const Text('إزالة الصورة')),
                  ])),
                ]),
                const SizedBox(height: 12),
                SuggestField(
                  controller: _category,
                  label: widget.accessories ? 'تصنيف الأكسسوار' : 'القسم (مثلاً: أجهزة، قطع غيار)',
                  options: () => widget.accessories
                      ? accessoryCategorySuggestions(categories)
                      : categories.where((c) => !isAccessoriesCategory(c)).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user.isOwner || _isNew) ...[
                      Expanded(
                        child: MoneyField(controller: _cost, label: 'سعر الشراء'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: MoneyField(controller: _price, label: 'سعر البيع *', validator: (c) => (c ?? 0) <= 0 ? 'يُرجى إدخال السعر' : null),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('هاتف أو جهاز برقم IMEI'),
                  subtitle: const Text('يُسجّل كل جهاز ويُباع باستخدام رقم IMEI الخاص به'),
                  value: _serialized,
                  onChanged: p?.serialized == true ? null : (v) => setState(() => _serialized = v),
                ),
                TextFormField(
                  controller: _warranty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الضمان بالشهور (0 = دون ضمان)'),
                ),
                if (!_serialized)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('متابعة الكمية في المخزون'),
                    subtitle: const Text('عطّلها للخدمات أو الأصناف التي لا تُتابع كميتها'),
                    value: _track,
                    onChanged: (v) => setState(() => _track = v),
                  ),
                if (_serialized && !_isNew)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.tonalIcon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => AddUnitsDialog(product: p!),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text('الأجهزة: ${p!.qty} في المحل • إضافة بالـ IMEI'),
                    ),
                  ),
                if (_track && !_serialized)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qty,
                          enabled: canEditQty,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: _isNew ? 'الكمية الموجودة' : 'الكمية (الجرد)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _low,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'نبّهني عند وصول الكمية إلى'),
                        ),
                      ),
                    ],
                  ),
                if (!_isNew && _track && !_serialized) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await showDialog<void>(context: context, builder: (_) => AddStockDialog(product: p!));
                      },
                      icon: const Icon(Icons.add_box_rounded),
                      label: Text('إضافة كمية مستلمة (الموجود ${p!.qty})'),
                    ),
                  ),
                ],
                if (!_isNew && user.isOwner) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _MovesDialog(product: p!),
                      ),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('حركة الصنف'),
                    ),
                  ),
                ],
                if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!_isNew && user.isOwner)
          TextButton(
            onPressed: _busy ? null : _archive,
            child: Text('إيقاف الصنف', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        SizedBox(
          width: 120,
          child: BusyButton(label: 'حفظ', busy: _busy, onPressed: _save),
        ),
      ],
    );
  }
}

/// إضافة كمية مستلمة: يُعرض الرصيد الحالي، وتُدخل الكمية المستلمة، ويُحسب الإجمالي تلقائياً قبل الحفظ.
class AddStockDialog extends ConsumerStatefulWidget {
  const AddStockDialog({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends ConsumerState<AddStockDialog> {
  final _qty = TextEditingController();
  final _cost = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    super.dispose();
  }

  int? get _added {
    final v = int.tryParse(latinDigits(_qty.text.trim()));
    return v == null || v <= 0 ? null : v;
  }

  Future<void> _save() async {
    final added = _added;
    if (added == null) return setState(() => _error = 'يُرجى إدخال الكمية المستلمة');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cost = parseMoney(_cost.text);
      final res = await ref.read(sessionProvider).value!.api!.post('/api/products/${widget.product.id}/adjust', {
        'qtyChange': added,
        'reason': 'purchase',
        'note': 'كمية مستلمة',
        if (cost != null && cost > 0) 'costCents': cost,
      });
      ref.invalidate(productsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(context, '${widget.product.name}: بقى ${(res['product'] as Map)['qty']}');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final added = _added;
    final isOwner = ref.watch(sessionProvider).value!.user!.isOwner;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget box(String label, String value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text(label, style: text.bodySmall),
              Text(value, style: text.titleLarge?.bold.copyWith(color: color), textAlign: TextAlign.center),
            ]),
          ),
        );
    return AlertDialog(
      title: Text('إضافة كمية: ${p.name}'),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            box('الرصيد الحالي', '${p.qty}', scheme.outline),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.add_rounded)),
            box('الكمية المستلمة', added == null ? '—' : '$added', brandOrange),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('=', style: TextStyle(fontSize: 22))),
            box('سيصبح', '${p.qty + (added ?? 0)}', scheme.primary),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _qty,
            autofocus: true,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(labelText: 'الكمية المستلمة حديثاً'),
          ),
          if (isOwner) ...[
            const SizedBox(height: 10),
            MoneyField(controller: _cost, label: 'المبلغ المدفوع (اختياري، لتحديث سعر الشراء)'),
          ],
          if (_error != null) ...[const SizedBox(height: 10), ErrorBanner(_error!)],
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        SizedBox(width: 120, child: BusyButton(label: 'حفظ', busy: _busy, onPressed: _save)),
      ],
    );
  }
}

const _moveReasons = {
  'initial': 'رصيد أول المدة',
  'sale': 'بيع',
  'return': 'مرتجع من عميل',
  'purchase': 'شراء / وارد',
  'count': 'جرد',
  'damaged': 'تالف',
  'lost': 'فاقد',
  'return_supplier': 'مرتجع للمورد',
  'import': 'استيراد',
  'repair': 'صيانة',
  'transfer_out': 'تحويل إلى فرع آخر',
  'transfer_in': 'تحويل من فرع آخر',
  'other': 'أخرى',
};

class _MovesDialog extends ConsumerWidget {
  const _MovesDialog({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(sessionProvider).value!.api!;
    return AlertDialog(
      title: Text('حركة: ${product.name}'),
      content: SizedBox(
        width: 460,
        height: 460,
        child: FutureBuilder(
          future: api.get('/api/products/${product.id}/moves'),
          builder: (context, snap) {
            if (snap.hasError) return ErrorBanner(errorText(snap.error!));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final moves = (snap.data!['moves'] as List).cast<Map<String, dynamic>>();
            if (moves.isEmpty) return const Center(child: Text('لا توجد حركات'));
            return ListView.separated(
              itemCount: moves.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = moves[i];
                final change = m['change'] as int;
                return ListTile(
                  dense: true,
                  leading: Text(
                    change > 0 ? '+$change' : '$change',
                    style: TextStyle(color: change > 0 ? const Color(0xFF16A34A) : Theme.of(context).colorScheme.error).bold,
                  ),
                  title: Text(_moveReasons[m['reason']] ?? '${m['reason']}'),
                  subtitle: Text(
                    '${formatDateTime(parseDate(m['createdAt'])!)}${m['userName'] != null ? ' • ${m['userName']}' : ''}${m['note'] != null ? '\n${m['note']}' : ''}',
                  ),
                  trailing: Text('الرصيد ${m['after']}'),
                );
              },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('قفل'))],
    );
  }
}

class _LabelsDialog extends ConsumerStatefulWidget {
  const _LabelsDialog({required this.products});
  final List<Product> products;

  @override
  ConsumerState<_LabelsDialog> createState() => _LabelsDialogState();
}

class _LabelsDialogState extends ConsumerState<_LabelsDialog> {
  late final Map<String, int> _copies = {for (final p in widget.products) p.id: 0};
  bool _a4 = false;

  @override
  Widget build(BuildContext context) {
    final total = _copies.values.fold<int>(0, (s, c) => s + c);
    return AlertDialog(
      title: const Text('طباعة ملصقات الرموز الشريطية'),
      content: SizedBox(
        width: 460,
        height: 480,
        child: Column(
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('طابعة ستيكر (50×30)')),
                ButtonSegment(value: true, label: Text('ورق A4')),
              ],
              selected: {_a4},
              onSelectionChanged: (s) => setState(() => _a4 = s.first),
            ),
            const SizedBox(height: 8),
            if (widget.products.isEmpty) const Expanded(child: Center(child: Text('لا توجد أصناف لها رموز شريطية في القائمة'))),
            Expanded(
              child: ListView(
                children: [
                  for (final p in widget.products)
                    ListTile(
                      dense: true,
                      title: Text(p.name),
                      subtitle: Text(p.barcode!, textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded),
                            onPressed: () => setState(() => _copies[p.id] = (_copies[p.id]! - 1).clamp(0, 999)),
                          ),
                          Text('${_copies[p.id]}'),
                          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => setState(() => _copies[p.id] = _copies[p.id]! + 1)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: total == 0
              ? null
              : () {
                  final items = [
                    for (final p in widget.products)
                      if (_copies[p.id]! > 0) (product: p, copies: _copies[p.id]!),
                  ];
                  Navigator.pop(context);
                  printBarcodeLabels(context, ref, items, a4: _a4);
                },
          child: Text('طباعة $total'),
        ),
      ],
    );
  }
}

/// يُستخدم في شاشة نقطة البيع عند مسح رمز شريطي غير مسجل؛ لفتح شاشة إضافة صنف جديد بهذا الرمز.
Future<void> addProductWithBarcode(BuildContext context, String barcode) => showDialog<void>(
  context: context,
  builder: (_) => ProductDialog(initialBarcode: barcode),
);
