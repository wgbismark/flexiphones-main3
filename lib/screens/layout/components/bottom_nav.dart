import 'package:flexiphones/shared_widgets/flexi_nav_bar.dart';
import 'package:flutter/material.dart';

/// Customer tab bar. Signed in: Home / Browse / Bag / Orders / Profile.
/// Guests: Home / Browse / Bag and a blue "Sign in". Anyone with an agent
/// account also gets "Agent" to jump back to their dashboard, even if the
/// customer side isn't signed in yet.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool ofl;
  final Function(int) onTap;
  final List cartItems;
  final bool showAgentTab;
  final VoidCallback? onAgentTap;
  final VoidCallback? onSignIn;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.cartItems,
    required this.ofl,
    this.showAgentTab = false,
    this.onAgentTap,
    this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return FlexiNavBar(
      currentIndex: currentIndex,
      onTap: (i) => onTap(i),
      items: [
        const FlexiNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: "Home",
        ),
        const FlexiNavItem(
          icon: Icons.search_rounded,
          activeIcon: Icons.manage_search_rounded,
          label: "Browse",
        ),
        FlexiNavItem(
          icon: Icons.shopping_bag_outlined,
          activeIcon: Icons.shopping_bag_rounded,
          label: "Bag",
          badge: cartItems.length,
        ),
        if (!ofl) ...[
          const FlexiNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: "Orders",
          ),
          const FlexiNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: "Profile",
          ),
        ],
        if (showAgentTab && onAgentTap != null)
          FlexiNavItem(
            icon: Icons.workspace_premium_outlined,
            activeIcon: Icons.workspace_premium_rounded,
            label: "Agent",
            onTap: onAgentTap,
          ),
        if (ofl && onSignIn != null)
          FlexiNavItem(
            icon: Icons.account_circle_outlined,
            activeIcon: Icons.account_circle_rounded,
            label: "Sign in",
            onTap: onSignIn,
            highlight: true,
          ),
      ],
    );
  }
}
