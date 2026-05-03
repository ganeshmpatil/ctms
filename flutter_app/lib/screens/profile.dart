import 'package:flutter/material.dart';

import '../api/client.dart';
import '../widgets/glass.dart';

class ProfileScreen extends StatelessWidget {
  final ApiClient api;
  const ProfileScreen({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    final u = api.user;
    return Scaffold(
      backgroundColor: AppColors.bg1,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    (u?.email.isNotEmpty == true ? u!.email[0] : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  u?.email ?? '',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (u?.role ?? '').toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.cloud_done_rounded, color: AppColors.muted),
                  title: const Text('API endpoint',
                      style: TextStyle(color: AppColors.text)),
                  subtitle: Text(api.apiBase,
                      style: const TextStyle(color: AppColors.muted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
