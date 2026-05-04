import 'package:flutter/material.dart';

/// Color palette — one entry per selectable theme.
class AppPalette {
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final Color accentLight;
  final Color accentC; // pink/secondary accent for gradients
  final Color accentD; // tertiary accent for gradients
  final Color pageBg; // subtle theme-tinted page background

  const AppPalette({
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.accentLight,
    required this.accentC,
    required this.accentD,
    required this.pageBg,
  });
}

const palettes = <AppPalette>[
  AppPalette(
    name: 'Violet',
    primary: Color(0xFF7C3AED),
    primaryDark: Color(0xFF5B21B6),
    primaryLight: Color(0xFFEDE9FE),
    accent: Color(0xFF2563EB),
    accentLight: Color(0xFFDBEAFE),
    accentC: Color(0xFFEC4899),
    accentD: Color(0xFF06B6D4),
    pageBg: Color(0xFFF6F4FE),
  ),
  AppPalette(
    name: 'Ocean',
    primary: Color(0xFF2563EB),
    primaryDark: Color(0xFF1E3A8A),
    primaryLight: Color(0xFFDBEAFE),
    accent: Color(0xFF06B6D4),
    accentLight: Color(0xFFCFFAFE),
    accentC: Color(0xFF8B5CF6),
    accentD: Color(0xFF14B8A6),
    pageBg: Color(0xFFF1F6FF),
  ),
  AppPalette(
    name: 'Forest',
    primary: Color(0xFF059669),
    primaryDark: Color(0xFF065F46),
    primaryLight: Color(0xFFD1FAE5),
    accent: Color(0xFF14B8A6),
    accentLight: Color(0xFFCCFBF1),
    accentC: Color(0xFFF59E0B),
    accentD: Color(0xFF06B6D4),
    pageBg: Color(0xFFF1FAF5),
  ),
  AppPalette(
    name: 'Coral',
    primary: Color(0xFFE11D48),
    primaryDark: Color(0xFF9F1239),
    primaryLight: Color(0xFFFFE4E6),
    accent: Color(0xFFF59E0B),
    accentLight: Color(0xFFFEF3C7),
    accentC: Color(0xFFEC4899),
    accentD: Color(0xFFEF4444),
    pageBg: Color(0xFFFEF6F4),
  ),
  AppPalette(
    name: 'Indigo',
    primary: Color(0xFF4F46E5),
    primaryDark: Color(0xFF312E81),
    primaryLight: Color(0xFFE0E7FF),
    accent: Color(0xFF06B6D4),
    accentLight: Color(0xFFCFFAFE),
    accentC: Color(0xFF8B5CF6),
    accentD: Color(0xFFEC4899),
    pageBg: Color(0xFFF3F4FF),
  ),
];

/// Brand colors used for the app-wide header and footer.
/// From colorhunt.co/palettes/nature — sage green family.
class NatureColors {
  static const dark = Color(0xFF344E41);   // forest
  static const medium = Color(0xFF588157); // green
  static const light = Color(0xFFA3B18A);  // sage
  static const cream = Color(0xFFDAD7CD);  // cream
}

/// Singleton holder for the active palette. Mutated by ThemeController.
class _PaletteHolder {
  AppPalette current = palettes.first;
}

final _palette = _PaletteHolder();

void setActivePalette(AppPalette p) {
  _palette.current = p;
}

AppPalette get activePalette => _palette.current;

/// All-app color tokens — getters so they reflect the current palette.
class AppColors {
  // Brand
  static Color get primary => _palette.current.primary;
  static Color get primaryDark => _palette.current.primaryDark;
  static Color get primaryLight => _palette.current.primaryLight;
  static Color get accent => _palette.current.accent;
  static Color get accentLight => _palette.current.accentLight;
  static Color get accentA => _palette.current.primary;
  static Color get accentB => _palette.current.accent;
  static Color get accentC => _palette.current.accentC;
  static Color get accentD => _palette.current.accentD;
  static Color get pageBg => _palette.current.pageBg;

  // Surface
  static const bg1 = Color(0xFFF8FAFC);
  static const bg2 = Color(0xFFF1F5F9);
  static const bg3 = Color(0xFFEEF2FF);
  static const surface = Colors.white;

  // Text
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const outline = Color(0xFFE2E8F0);

  // Status
  static const success = Color(0xFF059669);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerLight = Color(0xFFFEE2E2);

  // Compat aliases
  static const glassFill = bg2;
  static const glassStroke = outline;
}

/// Page background — subtle theme-tinted color.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.pageBg, child: child);
  }
}

/// Clean white card with a subtle outline + shadow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final card = Container(
      decoration: BoxDecoration(
        color: tint ?? AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.outline, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return TapScale(onTap: onTap!, child: card);
  }
}

/// Tactile press feedback — scales the child slightly on tap-down.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final Duration duration;

  const TapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 130),
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Solid primary button. (Kept the "Gradient" name for backward compat.)
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;
    return TapScale(
      onTap: disabled ? () {} : onPressed!,
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              else if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              if (!busy)
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration glassInputDecoration({
  required String label,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.muted),
    prefixIcon:
        icon != null ? Icon(icon, color: AppColors.muted, size: 20) : null,
    filled: true,
    fillColor: AppColors.bg2,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 1.4),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    isDense: true,
  );
}
