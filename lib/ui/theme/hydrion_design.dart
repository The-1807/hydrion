import 'package:flutter/material.dart';

class HydrionColors {
  static const abyss = Color(0xFF04243A);
  static const deep = Color(0xFF005792);
  static const current = Color(0xFF0088CC);
  static const foam = Color(0xFFE9FBFF);
  static const glow = Color(0xFF00D2FF);
  static const kelp = Color(0xFF0E9F6E);
  static const sunrise = Color(0xFFFFB703);
  static const coral = Color(0xFFE76F51);
}

class HydrionSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class HydrionRadii {
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

class HydrionMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;
}

class HydrionGradients {
  static const ocean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      HydrionColors.abyss,
      HydrionColors.deep,
      HydrionColors.current,
    ],
  );

  static const lagoon = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      HydrionColors.foam,
      Color(0xFFC8F4FF),
      Color(0xFFFFFFFF),
    ],
  );
}

ThemeData buildHydrionTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: HydrionColors.current,
    primary: HydrionColors.deep,
    secondary: HydrionColors.glow,
    tertiary: HydrionColors.kelp,
    error: HydrionColors.coral,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF061923) : HydrionColors.foam,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark
          ? const Color(0xFF0D2A38)
          : Colors.white.withValues(alpha: 0.92),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HydrionRadii.md),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: isDark
          ? const Color(0xFF092331)
          : Colors.white.withValues(alpha: 0.94),
      indicatorColor: HydrionColors.glow.withValues(alpha: 0.18),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HydrionColors.deep,
        foregroundColor: Colors.white,
        disabledBackgroundColor: scheme.surfaceContainerHighest,
        disabledForegroundColor: scheme.onSurfaceVariant,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HydrionRadii.sm),
        ),
        iconSize: 20,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HydrionColors.deep,
        disabledForegroundColor: scheme.onSurfaceVariant,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HydrionRadii.sm),
        ),
        iconSize: 20,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: HydrionColors.deep,
        disabledForegroundColor: scheme.onSurfaceVariant,
        minimumSize: const Size(44, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HydrionRadii.sm),
        ),
        iconSize: 20,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: HydrionColors.deep,
        disabledForegroundColor: scheme.onSurfaceVariant,
      ),
    ),
  );
}

class HydrionSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final double radius;

  const HydrionSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HydrionSpacing.lg),
    this.gradient,
    this.color,
    this.radius = HydrionRadii.md,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ??
            (isDark
                ? const Color(0xFF0D2A38)
                : Colors.white.withValues(alpha: 0.94)),
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
