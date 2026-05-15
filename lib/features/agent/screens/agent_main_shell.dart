import 'package:flutter/material.dart';

import '../widgets/agent_header.dart';
import '../widgets/agent_bottom_nav.dart';
import 'agent_dashboard_screen.dart';
import 'agent_missions_explorer_screen.dart';
import 'agent_profile_screen.dart';

class AgentMainShell extends StatefulWidget {
  const AgentMainShell({super.key});

  @override
  State<AgentMainShell> createState() => _AgentMainShellState();
}

class _AgentMainShellState extends State<AgentMainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AgentDashboardScreen(),
    const AgentMissionsExplorerScreen(),
    const Center(child: Text('Wallet - En cours de développement')),
    const AgentProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AgentHeader(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AgentBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
