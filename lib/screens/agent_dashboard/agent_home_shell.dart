import 'dart:async';

import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_dashboard.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_earnings.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_me.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_referrals.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_share.dart';
import 'package:flexiphones/screens/agent_dashboard/components/agent_bottom_nav.dart';
import 'package:flexiphones/screens/agent_dashboard/components/floating_wallet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hosts the whole agent-mode experience with its own bottom nav
/// (Home / Vendors / Share / Earnings / Me). Loads the real partner data
/// on entry, and leaves automatically if the partner session ends
/// (sign out, or the 24h token was rejected with a 401).
class AgentHomeShell extends StatefulWidget {
  const AgentHomeShell({super.key});

  @override
  State<AgentHomeShell> createState() => _AgentHomeShellState();
}

class _AgentHomeShellState extends State<AgentHomeShell> {
  int _selectedIndex = 0;

  void _openTab(int index) => setState(() => _selectedIndex = index);

  // The dashboard's quick actions switch tabs through _openTab.
  late final List<Widget> _pages = [
    AgentDashboard(onOpenTab: _openTab),
    const AgentReferrals(),
    const AgentShare(),
    const AgentEarnings(),
    const AgentMe(),
  ];

  /// Keeps the bell's unread count fresh while the agent side is open.
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<SharedProvider>(context, listen: false);
      p.refreshAgentData();
      p.getAgentApproval();
      // unread-count is cheap and indexed: 30s is fine.
      _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && p.isAgentAccount) p.pollAgentNotifications();
      });
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context);

    if (!p.isAgentAccount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
          // Floating withdrawable amount; hidden on the Wallet tab itself.
          Positioned.fill(
            child: FloatingWallet(
              visible: _selectedIndex != 3,
              onOpen: () => _openTab(3),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AgentBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}