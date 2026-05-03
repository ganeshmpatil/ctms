import 'dart:ui';

import 'package:flutter/material.dart';

/// Brand color palette — inspired by deep-dark glassmorphism mockups.
class AppColors {
  static const bg1 = Color(0xFF0B0F1F);
  static const bg2 = Color(0xFF1B1238);
  static const bg3 = Color(0xFF120B26);

  static const accentA = Color(0xFFEC4899); // pink
  static const accentB = Color(0xFFF59E0B); // orange
  static const accentC = Color(0xFF8B5CF6); // purple
  static const accentD = Color(0xFF22D3EE); // cyan

  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);

  static const glassFill = Color(0x22FFFFFF);
  static const glassStroke = Color(0x33FFFFFF);
  static const muted = Color(0xB3FFFFFF); // 70% white
}

/// Full-screen background: dark gradient + animated blurred color blobs.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.bg1, AppColors.bg2, AppColors.bg3],
              ),
            ),
          ),
        ),
        const _Blob(
            top: -120, left: -80, size: 320, color: AppColors.accentA, opacity: 0.45),
        const _Blob(
            top: 200, right: -120, size: 280, color: AppColors.accentC, opacity: 0.35),
        const _Blob(
            bottom: -100, left: 80, size: 300, color: AppColors.accentB, opacity: 0.28),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double? top, left, right, bottom;
  final double size;
  final Color color;
  final double opacity;
  const _Blob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass surface — backdrop blur + semi-transparent fill + 1px border.
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
    this.borderRadius = 20,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: tint ?? AppColors.glassFill,
            border: Border.all(color: AppColors.glassStroke, width: 1),
            borderRadius: radius,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return TapScale(
      onTap: onTap!,
      child: card,
    );
  }
}

/// Wraps any child with a "press shrinks slightly" animation.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final Duration duration;

  const TapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 140),
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

/// Pink→orange gradient pill, used as the primary call-to-action button.
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
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
            gradient: const LinearGradient(
              colors: [AppColors.accentA, AppColors.accentB],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentA.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
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

/// Frosted-glass text field (input fields used inside cards).
InputDecoration glassInputDecoration({
  required String label,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.muted),
    prefixIcon: icon != null ? Icon(icon, color: AppColors.muted, size: 20) : null,
    filled: true,
    fillColor: const Color(0x14FFFFFF),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.glassStroke),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accentA, width: 1.4),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.glassStroke),
    ),
    isDense: true,
  );
}
