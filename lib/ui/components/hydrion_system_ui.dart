import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Applies one theme-aware system-bar policy to every Hydrion route and modal.
class HydrionSystemUi extends StatelessWidget {
  final Widget child;

  const HydrionSystemUi({super.key, required this.child});

  static SystemUiOverlayStyle styleFor(ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    final navigationColor =
        theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.surface;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: navigationColor,
      systemNavigationBarDividerColor: navigationColor,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: styleFor(theme),
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: child,
      ),
    );
  }
}
