import 'package:flutter/material.dart';

import '../api/client.dart';
import '../theme/theme_controller.dart';
import '../widgets/glass.dart';
import 'admin/admin_divisions.dart';
import 'admin/admin_leads.dart';
import 'admin/admin_subjects.dart';
import 'admin/admin_users.dart';
import 'dashboard.dart';
import 'login.dart';
import 'profile.dart';
import 'rollcall.dart';
import 'settings.dart';
import 'students.dart';

/// HomeShell hosts the dashboard plus a hamburger drawer that navigates
/// to all the other screens.
class HomeShell extends StatefulWidget {
  final ApiClient api;
  final ThemeController theme;
  const HomeShell({super.key, required this.api, required this.theme});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _go(Widget Function() screen) {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen()),
    );
  }

  Future<void> _logout() async {
    Navigator.of(context).pop();
    await widget.api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => LoginScreen(api: widget.api, theme: widget.theme)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.api.user?.role;
    final isAdmin = role == 'admin';
    final isTeacher = role == 'teacher';
    final isStaff = role == 'staff';
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.pageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [NatureColors.dark, NatureColors.medium],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NatureColors.cream.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: NatureColors.cream, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Gravity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: NatureColors.dark,
          border: Border(
            top: BorderSide(color: NatureColors.medium, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.eco_rounded,
                        size: 14, color: NatureColors.light),
                    SizedBox(width: 6),
                    Text(
                      'Gravity · CTMS',
                      style: TextStyle(
                        color: NatureColors.cream,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'v0.4.0',
                  style: TextStyle(
                    color: NatureColors.light,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: _AppDrawer(
        api: widget.api,
        theme: widget.theme,
        onDashboard: () => Navigator.of(context).pop(),
        onStudents: () => _go(() => StudentsScreen(api: widget.api)),
        onRollCall: (isAdmin || isTeacher)
            ? () => _go(() => RollCallScreen(api: widget.api))
            : null,
        onDivisions: isAdmin
            ? () => _go(() => AdminDivisionsScreen(api: widget.api))
            : null,
        onSubjects: isAdmin
            ? () => _go(() => AdminSubjectsScreen(api: widget.api))
            : null,
        onUsers: isAdmin
            ? () => _go(() => AdminUsersScreen(api: widget.api))
            : null,
        onLeads: (isAdmin || isStaff)
            ? () => _go(() => AdminLeadsScreen(api: widget.api))
            : null,
        onProfile: () => _go(() => ProfileScreen(api: widget.api)),
        onSettings: () =>
            _go(() => SettingsScreen(api: widget.api, theme: widget.theme)),
        onLogout: _logout,
      ),
      body: DashboardScreen(
        api: widget.api,
        onOpenStudents: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StudentsScreen(api: widget.api)),
        ),
        onOpenRollCall: (isAdmin || isTeacher)
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => RollCallScreen(api: widget.api)),
                )
            : null,
        onOpenLeads: (isAdmin || isStaff)
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => AdminLeadsScreen(api: widget.api)),
                )
            : null,
        onOpenSubjects: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => AdminSubjectsScreen(api: widget.api)),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final ApiClient api;
  final ThemeController theme;
  final VoidCallback onDashboard;
  final VoidCallback onStudents;
  final VoidCallback? onRollCall;
  final VoidCallback? onDivisions;
  final VoidCallback? onSubjects;
  final VoidCallback? onUsers;
  final VoidCallback? onLeads;
  final VoidCallback onProfile;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _AppDrawer({
    required this.api,
    required this.theme,
    required this.onDashboard,
    required this.onStudents,
    required this.onRollCall,
    required this.onDivisions,
    required this.onSubjects,
    required this.onUsers,
    required this.onLeads,
    required this.onProfile,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final u = api.user;
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (u?.email.isNotEmpty == true ? u!.email[0] : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    u?.email ?? 'Signed out',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (u?.role ?? '').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    onTap: onDashboard,
                  ),
                  _DrawerItem(
                    icon: Icons.groups_rounded,
                    label: 'Students',
                    onTap: onStudents,
                  ),
                  if (onRollCall != null)
                    _DrawerItem(
                      icon: Icons.fact_check_rounded,
                      label: 'Roll Call',
                      onTap: onRollCall!,
                    ),
                  if (onDivisions != null)
                    _DrawerItem(
                      icon: Icons.class_rounded,
                      label: 'Divisions',
                      badge: 'ADMIN',
                      onTap: onDivisions!,
                    ),
                  if (onSubjects != null)
                    _DrawerItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Subjects',
                      badge: 'ADMIN',
                      onTap: onSubjects!,
                    ),
                  if (onUsers != null)
                    _DrawerItem(
                      icon: Icons.manage_accounts_rounded,
                      label: 'Users',
                      badge: 'ADMIN',
                      onTap: onUsers!,
                    ),
                  if (onLeads != null)
                    _DrawerItem(
                      icon: Icons.support_agent_rounded,
                      label: 'Leads',
                      onTap: onLeads!,
                    ),
                  const Divider(height: 24, color: AppColors.outline),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    onTap: onProfile,
                  ),
                  _DrawerItem(
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    onTap: onSettings,
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign out',
                    color: AppColors.danger,
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Gravity · ${theme.current.name}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.text),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.text,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: badge == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}
