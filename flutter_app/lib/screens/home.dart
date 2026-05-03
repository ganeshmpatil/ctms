import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../widgets/glass.dart';
import 'dashboard.dart';
import 'profile.dart';
import 'rollcall.dart';
import 'students.dart';

class HomeShell extends StatefulWidget {
  final ApiClient api;
  const HomeShell({super.key, required this.api});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(api: widget.api),
      StudentsScreen(api: widget.api),
      RollCallScreen(api: widget.api),
      ProfileScreen(api: widget.api),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg1,
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              border: const Border(
                top: BorderSide(color: AppColors.glassStroke, width: 0.6),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppColors.accentA.withValues(alpha: 0.30),
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded),
                    label: 'Students'),
                NavigationDestination(
                    icon: Icon(Icons.fact_check_outlined),
                    selectedIcon: Icon(Icons.fact_check_rounded),
                    label: 'Roll Call'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
