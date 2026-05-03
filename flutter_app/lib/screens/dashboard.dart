import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../widgets/glass.dart';
import 'students.dart';

class DashboardScreen extends StatefulWidget {
  final ApiClient api;
  const DashboardScreen({super.key, required this.api});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait<dynamic>([
      widget.api.students(),
      widget.api.divisions(),
      widget.api.subjects(),
    ]);
    return _DashboardData(
      students: results[0] as List<Student>,
      divisions: results[1] as List<Division>,
      subjects: results[2] as List<Subject>,
    );
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.api.user;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.accentA,
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentA, AppColors.accentB],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        (user?.email.isNotEmpty == true ? user!.email[0] : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                          Text(user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        border: Border.all(color: AppColors.glassStroke),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (user?.role ?? '').toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FutureBuilder<_DashboardData>(
                  future: _future,
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accentA)),
                      );
                    }
                    if (snap.hasError) {
                      return _ErrorBox(
                          message: snap.error.toString(), onRetry: _refresh);
                    }
                    final d = snap.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.25,
                          children: [
                            _StatCard(
                              icon: Icons.school_rounded,
                              value: '${d.students.length}',
                              label: 'Students',
                              gradient: const [
                                AppColors.accentA,
                                AppColors.accentB
                              ],
                            ),
                            _StatCard(
                              icon: Icons.class_rounded,
                              value: '${d.divisions.length}',
                              label: 'Divisions',
                              gradient: const [
                                AppColors.accentC,
                                AppColors.accentA
                              ],
                            ),
                            _StatCard(
                              icon: Icons.menu_book_rounded,
                              value: '${d.subjects.length}',
                              label: 'Subjects',
                              gradient: const [
                                AppColors.accentD,
                                AppColors.accentC
                              ],
                            ),
                            _StatCard(
                              icon: Icons.fact_check_rounded,
                              value: 'Today',
                              label: 'Roll Call',
                              gradient: const [
                                AppColors.success,
                                AppColors.accentD
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 10),
                          child: Text('Standards',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ),
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: d.divisions
                                .map((div) => TapScale(
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => StudentsScreen(
                                            api: widget.api,
                                            initialDivisionId: div.id,
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: div.medium == 'english'
                                                ? const [
                                                    AppColors.accentC,
                                                    AppColors.accentA
                                                  ]
                                                : const [
                                                    AppColors.accentB,
                                                    AppColors.accentA
                                                  ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          div.label,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  final List<Student> students;
  final List<Division> divisions;
  final List<Subject> subjects;
  _DashboardData(
      {required this.students,
      required this.divisions,
      required this.subjects});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36, color: Colors.white70),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );
  }
}
