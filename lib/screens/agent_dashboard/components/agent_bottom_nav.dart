import 'package:flexiphones/shared_widgets/flexi_nav_bar.dart';
import 'package:flutter/material.dart';

/// Agent bottom bar: Home / Vendors / Share / Wallet / Me.
class AgentBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AgentBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlexiNavBar(
      currentIndex: currentIndex,
      onTap: (i) => onTap(i),
      accent: const Color(0xFF7C4DFF),
      items: const [
        FlexiNavItem(
          icon: Icons.space_dashboard_outlined,
          activeIcon: Icons.space_dashboard_rounded,
          label: "Home",
        ),
        FlexiNavItem(
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront_rounded,
          label: "Vendors",
        ),
        FlexiNavItem(
          icon: Icons.qr_code_2_rounded,
          activeIcon: Icons.qr_code_rounded,
          label: "Share",
        ),
        FlexiNavItem(
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: "Wallet",
        ),
        FlexiNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: "Me",
        ),
      ],
    );
  }
}
