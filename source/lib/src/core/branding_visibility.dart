import 'dart:async';

import 'package:flutter/widgets.dart';

/// Controls when optional developer/company branding is visible in the UI.
///
/// The release date is fixed for this build: branding is hidden from
/// 2026-11-04 through 2027-01-03 and becomes visible on 2027-01-04.
class BrandingVisibility {
  BrandingVisibility._();

  static final DateTime visibleFrom = DateTime(2027, 1, 4);

  static bool get isVisible => isVisibleAt(DateTime.now());

  static bool isVisibleAt(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return !localDate.isBefore(visibleFrom);
  }
}

/// Rebuilds at the visibility date so an app left open overnight reveals the
/// branding without requiring a restart or an application update.
class BrandingVisibilityGate extends StatefulWidget {
  const BrandingVisibilityGate({required this.child, super.key});

  final Widget child;

  @override
  State<BrandingVisibilityGate> createState() => _BrandingVisibilityGateState();
}

class _BrandingVisibilityGateState extends State<BrandingVisibilityGate> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleVisibilityCheck();
  }

  void _scheduleVisibilityCheck() {
    if (BrandingVisibility.isVisible) return;
    final delay = BrandingVisibility.visibleFrom.difference(DateTime.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted) return;
      setState(() {});
      if (!BrandingVisibility.isVisible) _scheduleVisibilityCheck();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BrandingVisibility.isVisible ? widget.child : const SizedBox.shrink();
}
