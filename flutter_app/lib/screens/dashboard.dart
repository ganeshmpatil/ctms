import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/models.dart';
import '../widgets/glass.dart';

/// Dashboard hosted inside HomeShell. Renders a 2x2 grid of action cards
/// plus a "Standards" pill row (clickable into a filtered list).
class DashboardScreen extends StatefulWidget {
  final ApiClient api;
  final VoidCallback onOpenStudents;
  final VoidCallback? onOpenRollCall;
  final VoidCallback? onOpenLeads;
  final VoidCallback onOpenSubjects;

  const DashboardScreen({
    super.key,
    required this.api,
    required this.onOpenStudents,
    required this.onOpenRollCall,
    required this.onOpenLeads,
    required this.onOpenSubjects,
  });

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
      widget.api.leads().catchError((_) => <Lead>[]),
    ]);
    return _DashboardData(
      students: results[0] as List<Student>,
      divisions: results[1] as List<Division>,
      subjects: results[2] as List<Subject>,
      leads: results[3] as List<Lead>,
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
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Good day,',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              user?.email ?? '',
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
          ),
          FutureBuilder<_DashboardData>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            color: AppColors.muted, size: 32),
                        const SizedBox(height: 8),
                        Text(snap.error.toString(),
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: AppColors.text)),
                        const SizedBox(height: 12),
                        GradientButton(
                            label: 'Retry', onPressed: _refresh),
                      ],
                    ),
                  ),
                );
              }
              final d = snap.data!;
              final cards = <_ActionCard>[
                _ActionCard(
                  icon: Icons.groups_rounded,
                  label: 'Students',
                  count: '${d.students.length}',
                  accent: AppColors.primary,
                  bg: AppColors.primaryLight,
                  onTap: widget.onOpenStudents,
                ),
                if (widget.onOpenRollCall != null)
                  _ActionCard(
                    icon: Icons.fact_check_rounded,
                    label: 'Roll Call',
                    count: 'Today',
                    accent: AppColors.success,
                    bg: AppColors.successLight,
                    onTap: widget.onOpenRollCall!,
                  ),
                if (widget.onOpenLeads != null)
                  _ActionCard(
                    icon: Icons.support_agent_rounded,
                    label: 'Leads',
                    count: '${d.leads.where((l) => !l.isResolved).length}',
                    accent: AppColors.warning,
                    bg: AppColors.warningLight,
                    onTap: widget.onOpenLeads!,
                  ),
              ];
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: cards,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  final List<Student> students;
  final List<Division> divisions;
  final List<Subject> subjects;
  final List<Lead> leads;
  _DashboardData({
    required this.students,
    required this.divisions,
    required this.subjects,
    required this.leads,
  });
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color accent;
  final Color bg;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.accent,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded,
                  color: AppColors.muted, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(count,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

