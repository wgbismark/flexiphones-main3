import 'dart:ui';

import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

class FlexiNavItem {
  const FlexiNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
    this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Count shown on the icon (e.g. bag items); 0 hides it.
  final int badge;

  /// When set, tapping runs this instead of selecting the tab (e.g. a tab
  /// that opens another screen, like Sign in or Agent).
  final VoidCallback? onTap;

  /// Draw it in the accent colour even when not selected (e.g. "Sign in").
  final bool highlight;
}

/// The app's tab bar, iOS style: slim, edge to edge, frosted, a hairline
/// on top. Icon + small label; the chosen tab is blue with a filled icon
/// and a soft pop. No floating pill, no heavy shadows.
class FlexiNavBar extends StatelessWidget {
  const FlexiNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.floating = true,
    this.accent = const Color(0xFF0071E3),
  });

  final List<FlexiNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Kept for older callers; the bar always sits flat at the bottom.
  final bool floating;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).padding.bottom;
    // Selected index counts only real tabs (items without onTap).
    final tabIndexes = <int>[];
    var t = 0;
    for (final it in items) {
      tabIndexes.add(it.onTap == null ? t++ : -1);
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(bottom: bottom > 0 ? bottom - 6 : 4),
          decoration: BoxDecoration(
            color: (dark ? const Color(0xFF1C1C1E) : Colors.white).withOpacity(
              0.86,
            ),
            border: Border(
              top: BorderSide(
                color: (dark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 0.6,
              ),
            ),
          ),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final item = items[i];
                        final isTab = item.onTap == null;
                        final myIndex = tabIndexes[i];
                        final selected = isTab && myIndex == currentIndex;
                        final color =
                            selected || item.highlight
                                ? accent
                                : ch.onSurfaceVariant.withOpacity(0.75);
                        return _Tab(
                          item: item,
                          selected: selected,
                          color: color,
                          onTap: item.onTap ?? () => onTap(myIndex),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final FlexiNavItem item;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    key: ValueKey(selected),
                    size: 24,
                    color: color,
                  ),
                ),
                if (item.badge > 0)
                  Positioned(
                    top: -4,
                    right: -9,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        item.badge > 99 ? "99+" : "${item.badge}",
                        style: ptstyle(
                          size: 9,
                          weight: 700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ptstyle(
              size: 10.5,
              weight: selected ? 600 : 500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
