import 'package:abdulmalik_erp/src/features/home/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('about screen presents the complete project profile in Arabic', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AboutScreen(),
    ));

    expect(find.text('عن المشروع والفريق'), findsOneWidget);
    expect(find.text('M.GH.AL'), findsOneWidget);
    expect(find.text('شركة للبرمجيات والأنظمة والتطبيقات'), findsOneWidget);
    expect(find.textContaining('شارة توثيق تعريفية للمشروع'), findsOneWidget);
    expect(find.text('فريق العمل والهيكل الأكاديمي والتقني للمشروع'), findsOneWidget);
    expect(find.text('أولاً: اللجنة الأكاديمية والاستشارية'), findsOneWidget);
    expect(find.text('ثانياً: فريق الهندسة والتطوير'), findsOneWidget);
    expect(find.text('ثالثاً: الهيكل التنظيمي للمشروع'), findsOneWidget);
    expect(find.text('رابعاً: منهجية تطوير المشروع'), findsOneWidget);
    expect(find.text('رؤية المشروع'), findsOneWidget);
    expect(find.textContaining('تنويه مهني'), findsNothing);
    expect(find.textContaining('Professional note'), findsNothing);

    expect(find.text('الأستاذ الدكتور أحمد الناشري'), findsOneWidget);
    expect(find.text('الأستاذ الدكتور عبد الرزاق الأهدل'), findsOneWidget);
    expect(find.text('الدكتور ضياء الحق القدمي'), findsOneWidget);
    expect(find.text('الدكتور عبده شويه'), findsOneWidget);
    expect(find.text('الأستاذة سمر'), findsOneWidget);
    expect(find.text('محمد غالب العصيمي'), findsOneWidget);
    expect(find.text('رمزي محمد الصرابي'), findsOneWidget);
    expect(find.text('عرفات الكاملي'), findsOneWidget);

    // Biographies are collapsed by default and expand on demand.
    await tester.ensureVisible(find.text('الأستاذ الدكتور أحمد الناشري'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الأستاذ الدكتور أحمد الناشري'));
    await tester.pumpAndSettle();
    expect(find.text('المسؤوليات والمهام'), findsOneWidget);
    expect(find.text('المؤهلات والخبرات'), findsOneWidget);
  });
}
