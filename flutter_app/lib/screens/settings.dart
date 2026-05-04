import 'package:flutter/material.dart';

import '../api/client.dart';
import '../theme/theme_controller.dart';
import '../widgets/glass.dart';

class SettingsScreen extends StatelessWidget {
  final ApiClient api;
  final ThemeController theme;
  const SettingsScreen({super.key, required this.api, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: theme,
        builder: (ctx, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Color theme',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (int i = 0; i < palettes.length; i++) ...[
                    _PaletteRow(
                      palette: palettes[i],
                      selected: theme.current.name == palettes[i].name,
                      onTap: () => theme.setPalette(palettes[i]),
                    ),
                    if (i < palettes.length - 1)
                      const Divider(
                          height: 1,
                          indent: 12,
                          endIndent: 12,
                          color: AppColors.outline),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Account',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.person_rounded,
                    color: AppColors.muted),
                title: const Text('Signed in as'),
                subtitle: Text(api.user?.email ?? '—',
                    style: const TextStyle(color: AppColors.muted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteRow({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Three-color swatch
            SizedBox(
              width: 64,
              height: 28,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: _swatch(palette.primary),
                  ),
                  Positioned(
                    left: 18,
                    child: _swatch(palette.accent),
                  ),
                  Positioned(
                    left: 36,
                    child: _swatch(palette.accentC),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                palette.name,
                style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color c) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
}
