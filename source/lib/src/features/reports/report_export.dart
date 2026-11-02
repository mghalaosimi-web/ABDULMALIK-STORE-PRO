import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/file_save.dart';
import '../../core/format.dart';
import '../../core/shop.dart';
import '../../core/spreadsheet.dart';
import '../../widgets/common.dart';

double _p(Object? cents) => ((cents as int?) ?? 0) / 100;

/// التقرير كملف Excel: ورقة عمل مستقلة لكل قسم لتسهيل مراجعة البيانات.
Future<void> exportReportExcel(BuildContext context, Map<String, dynamic> r, String label) async {
  try {
    final sales = r['sales'] as Map<String, dynamic>;
    final repairs = r['repairs'] as Map<String, dynamic>;
    final services = r['services'] as Map<String, dynamic>;
    final expenses = r['expenses'] as Map<String, dynamic>;
    final receivables = r['receivables'] as Map<String, dynamic>;
    final payables = r['payables'] as Map<String, dynamic>;
    final stock = r['stock'] as Map<String, dynamic>;
    final w = XlsxWriter()
      ..addSheet('الملخص', [
        ['البند', 'القيمة (ر.س)'],
        ['الفترة', label],
        ['صافي الربح', _p(r['netProfitCents'])],
        ['المبيعات', _p(sales['revenueCents'])],
        ['تكلفة المبيعات', _p(sales['costCents'])],
        ['ربح المبيعات', _p(sales['profitCents'])],
        ['الخصومات', _p(sales['discountCents'])],
        ['المرتجعات', _p(sales['returnsCents'])],
        ['إيراد الصيانة', _p(repairs['revenueCents'])],
        ['تكلفة قطع الغيار', _p(repairs['partsCostCents'])],
        ['ربح الصيانة', _p(repairs['profitCents'])],
        ['أجهزة سُلّمت للعملاء', repairs['delivered']],
        ['أجهزة استُلمت للصيانة', repairs['received']],
        ['مرتجعات الضمان', repairs['warrantyReturns']],
        ['عمولات المحافظ', _p(services['commissionCents'])],
        ['المصروفات', _p(expenses['totalCents'])],
        ['فروق الخزنة', _p(r['cashDifferenceCents'])],
        ['قيمة المخزون', _p(stock['valueCents'])],
        ['إجمالي المبالغ المستحقة على العملاء', _p(receivables['totalCents'])],
        ['إجمالي المبالغ المستحقة للموردين', _p(payables['totalCents'])],
      ])
      ..addSheet('البيانات اليومية', [
        ['التاريخ', 'المبيعات', 'الصيانة', 'المصروفات'],
        for (final d in (r['daily'] as List).cast<Map<String, dynamic>>()) [d['date'], _p(d['sales']), _p(d['repairs']), _p(d['expenses'])],
      ])
      ..addSheet('الأصناف', [
        ['الصنف', 'الكمية', 'المبيعات', 'الربح'],
        for (final p in (sales['topProducts'] as List).cast<Map<String, dynamic>>()) [p['name'], p['qty'], _p(p['revenue']), _p(p['profit'])],
      ])
      ..addSheet('الفنيون', [
        ['اسم الفني', 'عدد الأجهزة', 'الإيراد', 'تكلفة قطع الغيار', 'ربح الصيانة', 'العمولة', 'مرتجعات الضمان', 'متوسط مدة الصيانة (ساعة)'],
        for (final t in (r['technicians'] as List).cast<Map<String, dynamic>>())
          [t['name'], t['delivered'], _p(t['revenueCents']), _p(t['partsCostCents']), _p(t['laborCents']), _p(t['commissionCents']), t['warrantyReturns'], t['avgHours']],
      ])
      ..addSheet('المصروفات', [
        ['البند', 'المبلغ'],
        for (final e in (expenses['byCategory'] as List).cast<Map<String, dynamic>>()) [e['name'], _p(e['total'])],
      ])
      ..addSheet('عمولات المحافظ', [
        ['المحفظة', 'عدد العمليات', 'العمولة'],
        for (final wallet in (services['byWallet'] as List).cast<Map<String, dynamic>>())
          [wallet['name'], wallet['count'], _p(wallet['commission'])],
      ])
      ..addSheet('المبالغ المستحقة على العملاء', [
        ['العميل', 'رقم الهاتف', 'الرصيد المستحق'],
        for (final c in (receivables['customers'] as List).cast<Map<String, dynamic>>())
          [c['name'], c['phone'], _p(c['balanceCents'])],
      ])
      ..addSheet('المبالغ المستحقة للموردين', [
        ['المورد', 'الرصيد المستحق'],
        for (final supplier in (payables['suppliers'] as List).cast<Map<String, dynamic>>())
          [supplier['name'], _p(supplier['balanceCents'])],
      ])
      ..addSheet('المخزون الراكد', [
        ['الصنف', 'الكمية', 'قيمة المخزون'],
        for (final item in (stock['deadStock'] as List).cast<Map<String, dynamic>>())
          [item['name'], item['qty'], _p(item['value'])],
      ]);
    final path = await saveOrShareFile(w.build(), 'تقرير ABDULMALIK ERP - ${latinDigits(label).replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    if (path != null && context.mounted) showMessage(context, 'تم حفظ التقرير في: $path');
  } catch (e) {
    if (context.mounted) showMessage(context, 'تعذّر تصدير التقرير: $e', error: true);
  }
}

/// التقرير كملف PDF للطباعة أو الإرسال.
Future<void> exportReportPdf(BuildContext context, WidgetRef ref, Map<String, dynamic> r, String label) async {
  try {
    final shop = await ref.read(shopProvider.future);
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
    final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold), title: 'تقرير $label');
    final sales = r['sales'] as Map<String, dynamic>;
    final repairs = r['repairs'] as Map<String, dynamic>;
    final services = r['services'] as Map<String, dynamic>;
    final expenses = r['expenses'] as Map<String, dynamic>;
    final receivables = r['receivables'] as Map<String, dynamic>;
    final payables = r['payables'] as Map<String, dynamic>;
    final stock = r['stock'] as Map<String, dynamic>;

    pw.Widget table(String title, List<String> headers, List<List<String>> rows) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.SizedBox(height: 12),
          pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          if (rows.isEmpty)
            pw.Text('—')
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerRight,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            ),
        ]);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(shop.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('تقرير: $label', style: const pw.TextStyle(fontSize: 11)),
      ]),
      footer: (c) => pw.Center(child: pw.Text('ABDULMALIK ERP • ${formatDateTime(DateTime.now())} • صفحة ${c.pageNumber}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
      build: (_) => [
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('صافي الربح', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(money(r['netProfitCents'] as int), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ]),
        ),
        table('الملخص', ['البند', 'القيمة'], [
          ['إيرادات المبيعات', money(sales['revenueCents'] as int)],
          ['عدد فواتير المبيعات', '${sales['count']}'],
          ['ربح المبيعات', money(sales['profitCents'] as int)],
          ['إيرادات الصيانة', money(repairs['revenueCents'] as int)],
          ['عدد الأجهزة المسلّمة للعملاء', '${repairs['delivered']}'],
          ['عدد الأجهزة المستلمة للصيانة', '${repairs['received']}'],
          ['ربح الصيانة (بعد قطع الغيار)', money(repairs['profitCents'] as int)],
          ['عمولات المحافظ', money(services['commissionCents'] as int)],
          ['المصروفات', money(expenses['totalCents'] as int)],
          ['فروق الخزنة', money(r['cashDifferenceCents'] as int)],
          ['قيمة المخزون', money(stock['valueCents'] as int)],
          ['إجمالي المبالغ المستحقة على العملاء', money(receivables['totalCents'] as int)],
          ['إجمالي المبالغ المستحقة للموردين', money(payables['totalCents'] as int)],
          ['مرتجعات الضمان', '${repairs['warrantyReturns']}'],
          ['متوسط وقت الصيانة', '${repairs['avgHours']} ساعة'],
        ]),
        table('الأصناف الأعلى مبيعاً', ['الصنف', 'الكمية', 'المبيعات', 'الربح'], [
          for (final p in (sales['topProducts'] as List).cast<Map<String, dynamic>>())
            [p['name'] as String, '${p['qty']}', money(p['revenue'] as int), money(p['profit'] as int)],
        ]),
        table('الفنيون', ['اسم الفني', 'عدد الأجهزة', 'ربح الصيانة', 'العمولة', 'مرتجعات الضمان'], [
          for (final t in (r['technicians'] as List).cast<Map<String, dynamic>>())
            [t['name'] as String, '${t['delivered']}', money(t['laborCents'] as int), money(t['commissionCents'] as int), '${t['warrantyReturns']}'],
        ]),
        table('المصروفات', ['البند', 'المبلغ'], [
          for (final e in (expenses['byCategory'] as List).cast<Map<String, dynamic>>()) [e['name'] as String, money(e['total'] as int)],
        ]),
        table('البيانات اليومية', ['التاريخ', 'المبيعات', 'الصيانة', 'المصروفات'], [
          for (final day in (r['daily'] as List).cast<Map<String, dynamic>>())
            [
              formatDate(DateTime.parse(day['date'] as String)),
              money(day['sales'] as int? ?? 0),
              money(day['repairs'] as int? ?? 0),
              money(day['expenses'] as int? ?? 0),
            ],
        ]),
        table('عمولات المحافظ', ['المحفظة', 'عدد العمليات', 'العمولة'], [
          for (final wallet in (services['byWallet'] as List).cast<Map<String, dynamic>>())
            [wallet['name'] as String, '${wallet['count']}', money(wallet['commission'] as int)],
        ]),
        table('المبالغ المستحقة على العملاء', ['العميل', 'رقم الهاتف', 'الرصيد المستحق'], [
          for (final c in (receivables['customers'] as List).cast<Map<String, dynamic>>())
            [c['name'] as String, c['phone'] as String? ?? '', money(c['balanceCents'] as int)],
        ]),
        table('المبالغ المستحقة للموردين', ['المورد', 'الرصيد المستحق'], [
          for (final supplier in (payables['suppliers'] as List).cast<Map<String, dynamic>>())
            [supplier['name'] as String, money(supplier['balanceCents'] as int)],
        ]),
        table('المخزون الراكد', ['الصنف', 'الكمية', 'قيمة المخزون'], [
          for (final item in (stock['deadStock'] as List).cast<Map<String, dynamic>>())
            [item['name'] as String, '${item['qty']}', money(item['value'] as int)],
        ]),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'تقرير $label');
  } catch (e) {
    if (context.mounted) showMessage(context, 'تعذّر تصدير التقرير: $e', error: true);
  }
}
