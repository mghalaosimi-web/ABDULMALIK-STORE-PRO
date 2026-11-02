import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';

/// الشعار الرسمي لعبدالملك للاتصالات المستخدم داخل واجهات النظام.
class AbdulmalikErpLogo extends StatelessWidget {
  const AbdulmalikErpLogo({super.key, this.size = 56, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    if (showName) {
      return Image.asset(
        'assets/branding/abdulmalik-communications.png',
        width: size * 4.8,
        height: size * 2.85,
        fit: BoxFit.contain,
        semanticLabel: 'عبدالملك للاتصالات - ABDULMALIK COMMUNICATIONS',
      );
    }
    return Image.asset(
      'assets/branding/abdulmalik-mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'ABDULMALIK',
    );
  }
}

/// كارت في نص الشاشة للشاشات البسيطة زي الدخول والإعداد.
class CenteredPanel extends StatelessWidget {
  const CenteredPanel({super.key, required this.child, this.maxWidth = 460});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// زرار بيعرض loading وهو بيستنى العملية تخلص.
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Text(label);
    if (icon != null && !busy) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: child,
      );
    }
    return FilledButton(onPressed: busy ? null : onPressed, child: child);
  }
}

String errorText(Object e) =>
    e is ApiException ? e.message : 'حصل خطأ غير متوقع: $e';

void showMessage(BuildContext context, String message, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
      ),
    );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium?.bold),
  );
}
