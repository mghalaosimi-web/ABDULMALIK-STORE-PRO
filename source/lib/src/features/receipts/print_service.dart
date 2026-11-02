import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/app_config.dart';
import '../../core/pos_models.dart';
import '../../core/session.dart';
import '../../core/shop.dart';
import '../../core/ticket_models.dart';
import '../../widgets/common.dart';
import 'receipt_pdf.dart';

enum PrintKind { receipt, sticker }

/// يطبع الإيصال أو الملصق. إذا كانت هناك طابعة مخصصة محفوظة لهذا الجهاز، فستتم الطباعة عليها مباشرة،
/// وإلا فستُفتح شاشة الطباعة الخاصة بالنظام.
Future<void> printTicket(BuildContext context, WidgetRef ref, String ticketId, PrintKind kind) async {
  try {
    final api = ref.read(sessionProvider).value!.api!;
    final detail = TicketDetail(await api.get('/api/tickets/$ticketId'));
    final shop = await ref.read(shopProvider.future);
    final bytes = kind == PrintKind.receipt ? await buildReceiptPdf(detail, shop) : await buildStickerPdf(detail, shop);
    final name = '${kind == PrintKind.receipt ? 'إيصال' : 'ملصق'}-${detail.ticket.number}';
    final format = paperFormat(shop.receiptPaper);

    final config = ref.read(appConfigProvider);
    final url = config.receiptPrinterUrl;
    if (url != null) {
      final ok = await Printing.directPrintPdf(
        printer: Printer(url: url, name: config.receiptPrinterName),
        onLayout: (_) async => bytes,
        name: name,
        format: format,
      );
      if (context.mounted) {
        showMessage(context, ok ? 'أُرسل إلى الطابعة ${config.receiptPrinterName ?? ''}' : 'تعذّرت الطباعة؛ يُرجى التحقق من تشغيل الطابعة.', error: !ok);
      }
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: name, format: format);
  } catch (e) {
    if (context.mounted) showMessage(context, 'تعذّرت الطباعة: ${errorText(e)}', error: true);
  }
}

/// حفظ الإيصال أو مشاركته كملف PDF (مثلاً لإرساله إلى العميل عبر واتساب).
Future<void> shareReceipt(BuildContext context, WidgetRef ref, String ticketId) async {
  try {
    final api = ref.read(sessionProvider).value!.api!;
    final detail = TicketDetail(await api.get('/api/tickets/$ticketId'));
    final shop = await ref.read(shopProvider.future);
    final Uint8List bytes = await buildReceiptPdf(detail, shop, paper: 'a5');
    await Printing.sharePdf(bytes: bytes, filename: 'إيصال-${detail.ticket.number}.pdf');
  } catch (e) {
    if (context.mounted) showMessage(context, errorText(e), error: true);
  }
}

/// طباعة فاتورة بيع على طابعة الوصولات.
Future<void> printSale(BuildContext context, WidgetRef ref, String saleId) async {
  try {
    final api = ref.read(sessionProvider).value!.api!;
    final detail = SaleDetail(await api.get('/api/sales/$saleId'));
    final shop = await ref.read(shopProvider.future);
    final bytes = await buildSalePdf(detail, shop);
    if (!context.mounted) return;
    await _printBytes(context, ref, bytes, 'فاتورة-${detail.sale.number}', paperFormat(shop.receiptPaper));
  } catch (e) {
    if (context.mounted) showMessage(context, 'تعذّرت الطباعة: ${errorText(e)}', error: true);
  }
}

Future<void> printBarcodeLabels(BuildContext context, WidgetRef ref, List<({Product product, int copies})> items, {bool a4 = false}) async {
  try {
    final shop = await ref.read(shopProvider.future);
    final bytes = await buildBarcodeLabelsPdf(items, shop, a4: a4);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'الرمز-الشريطي');
  } catch (e) {
    if (context.mounted) showMessage(context, 'تعذّرت الطباعة: ${errorText(e)}', error: true);
  }
}

Future<void> _printBytes(BuildContext context, WidgetRef ref, Uint8List bytes, String name, PdfPageFormat format) async {
  final config = ref.read(appConfigProvider);
  final url = config.receiptPrinterUrl;
  if (url != null) {
    final ok = await Printing.directPrintPdf(
      printer: Printer(url: url, name: config.receiptPrinterName),
      onLayout: (_) async => bytes,
      name: name,
      format: format,
    );
    if (!ok && context.mounted) showMessage(context, 'تعذّرت الطباعة؛ يُرجى التحقق من تشغيل الطابعة.', error: true);
    return;
  }
  await Printing.layoutPdf(onLayout: (_) async => bytes, name: name, format: format);
}

/// اختيار طابعة الوصولات الافتراضية للجهاز ده.
Future<void> pickReceiptPrinter(BuildContext context, WidgetRef ref) async {
  final config = ref.read(appConfigProvider);
  final printer = await Printing.pickPrinter(context: context, title: 'اختر طابعة الإيصالات');
  if (printer == null) return;
  await config.setReceiptPrinter(printer.url, printer.name);
  if (context.mounted) showMessage(context, 'ستتم طباعة الإيصالات على ${printer.name}');
}

Future<void> printUsedPurchase(BuildContext context, WidgetRef ref, PhoneUnit unit) async {
  try {
    final shop = await ref.read(shopProvider.future);
    final bytes = await buildUsedPurchasePdf(unit, shop);
    if (!context.mounted) return;
    await _printBytes(context, ref, bytes, 'إيصال-شراء-${unit.imei}', paperFormat(shop.receiptPaper));
  } catch (e) {
    if (context.mounted) showMessage(context, 'تعذّرت الطباعة: ${errorText(e)}', error: true);
  }
}
