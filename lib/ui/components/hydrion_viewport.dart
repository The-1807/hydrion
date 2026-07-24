import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared responsive geometry for Hydrion routes and the persistent shell.
///
/// The shell owns the system status-bar and bottom-navigation insets. Standalone
/// routes use [scrollPadding] to keep their final scrollable control above the
/// device navigation area. Keyboard-aware sheets and dialogs opt into the
/// current view inset explicitly.
abstract final class HydrionViewport {
  static const double _compactHorizontal = 12;
  static const double _regularHorizontal = 16;
  static const double _wideHorizontal = 24;

  static double textScale(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(14) / 14;
  }

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return _compactHorizontal;
    if (width >= 720) return _wideHorizontal;
    return _regularHorizontal;
  }

  static EdgeInsets scrollPadding(
    BuildContext context, {
    double top = 16,
    double bottom = 24,
    bool includeSystemBottom = true,
    bool includeKeyboard = false,
  }) {
    final media = MediaQuery.of(context);
    final horizontal = horizontalPadding(context);
    final systemBottom = includeSystemBottom ? media.viewPadding.bottom : 0.0;
    final keyboard = includeKeyboard ? media.viewInsets.bottom : 0.0;
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      bottom + systemBottom + keyboard,
    );
  }

  static double navigationBarHeight(BuildContext context) {
    final scale = textScale(context);
    if (scale >= 1.75) return 76;
    if (scale >= 1.3) return 70;
    return 64;
  }

  static double headerHeight(BuildContext context) {
    final scale = textScale(context);
    return (64 + math.max(0, scale - 1) * 24).clamp(64, 88).toDouble();
  }

  static bool stackActions(
    BuildContext context, {
    required double availableWidth,
    double widthBreakpoint = 360,
    double textScaleBreakpoint = 1.3,
  }) {
    return availableWidth < widthBreakpoint ||
        textScale(context) >= textScaleBreakpoint;
  }

  static EdgeInsets dialogInsetPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 360
        ? 12.0
        : width < 480
            ? 20.0
            : 40.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 24);
  }
}

/// Keeps segmented controls and similar fixed-row inputs usable at large text
/// scales without shrinking or clipping their labels.
class HydrionHorizontalControl extends StatelessWidget {
  final Widget child;

  const HydrionHorizontalControl({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: child,
        ),
      ),
    );
  }
}
