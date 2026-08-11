import 'package:flutter/material.dart';

import 'clients_screen.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'more_screen.dart';
import 'projects_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['', '', 'Clients', 'Expenses', 'All modules'];

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardScreen(),
      ProjectsScreen(),
      ClientsScreen(),
      ExpensesScreen(),
      MoreScreen(),
    ];

    return Scaffold(
      appBar: (_index == 0 || _index == 1)
          ? null
          : AppBar(
              title: Text(_titles[_index]),
            ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
