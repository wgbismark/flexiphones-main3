import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/screens/profile/edit_profile.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_me.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_earnings.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_notifications.dart';
import 'package:flexiphones/screens/agent_dashboard/vendor_onboarding/onboard_vendor.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const _agentDark1 = Color(0xFF120A06);
const _agentDark2 = Color(0xFF3B2011);
const _agentGold = Color(0xFFCC9A44);

/// Agent home. Everything comes from the backend:
///  - wallet: GET /partner/wallet
///  - earned, points, rates, promo code, referred: GET /partner/earnings
///  - vendors: GET /partner/my-vendors
///  - activity: GET /partner/wallet/transactions
///
/// [onOpenTab] switches the agent shell's tab (1 vendors, 2 share,
/// 3 earnings) from the quick actions and "See all".
class AgentDashboard extends StatelessWidget {
  const AgentDashboard({super.key, this.onOpenTab});

  final ValueChanged<int>? onOpenTab;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    final p = Provider.of<SharedProvider>(context);
    final fullName = p.partnerData?.name ?? "Agent";
    final name = fullName.split(" ").first;
    final w = p.partnerWallet;
    final e = p.partnerEarnings;
    final code = p.agentPromoCode;
    final recent = p.partnerTransactions.take(4).toList();
    final cardColor = isDark ? ch.surfaceContainerLow : Colors.white;

    // Light grey page so the white cards lift off it (Apple-style).
    return ColoredBox(
      color: isDark ? ch.surface : const Color(0xFFF5F5F7),
      child: SafeArea(
      child: RefreshIndicator(
        color: _agentGold,
        onRefresh: p.refreshAgentData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ---------------- Header ----------------
            Row(
              children: [
                // Tap the picture or name: your profile (Me tab).
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onOpenTab?.call(4),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          name: name,
                          url: p.partnerData?.photoUrl,
                          size: 44,
                          color: _agentGold,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: ptstyle(
                                  size: 12,
                                  weight: 400,
                                  color: ch.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ptstyle(
                                  size: 22,
                                  weight: 800,
                                  color: ch.onSurface,
                                ).copyWith(letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  elevation: isDark ? 0 : 1,
                  shadowColor: Colors.black12,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap:
                        () => NavigationHelper.push(
                          context,
                          const AgentNotificationsScreen(),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Badge(
                        isLabelVisible: p.agentUnreadCount > 0,
                        backgroundColor: Colors.redAccent,
                        label: Text(
                          p.agentUnreadCount > 9
                              ? "9+"
                              : "${p.agentUnreadCount}",
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: ch.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Agent | Shop: one tap to the customer side.
            _ModeSwitch(onShop: () => AgentMe.switchToCustomer(context)),
            const SizedBox(height: 18),

            // ---------------- Approval (information only) ----------------
            if (p.agentApproval != null &&
                !p.agentApproval!.approved &&
                p.agentApproval!.title.isNotEmpty) ...[
              _ApprovalBanner(
                approval: p.agentApproval!,
                onLink:
                    () => showDialog(
                      context: context,
                      builder: (_) => const AgentGhanaCardDialog(),
                    ),
              ),
              const SizedBox(height: 14),
            ],

            // ---------------- Wallet hero ----------------
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_agentDark2, _agentDark1],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: _agentDark1.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Soft gold glow in the corner.
                  Positioned(
                    right: -40,
                    top: -50,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _agentGold.withOpacity(0.35),
                            _agentGold.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Withdrawable now",
                              style: ptstyle(
                                size: 12,
                                weight: 500,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          w == null ? "—" : agentMoney(w.withdrawable),
                          style: ptstyle(
                            size: 34,
                            weight: 800,
                            color: Colors.white,
                          ).copyWith(letterSpacing: -1),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _HeroStat(
                              label: "Earned",
                              value:
                                  e != null
                                      ? agentMoney(e.earnedTotal)
                                      : (w == null
                                          ? "—"
                                          : agentMoney(w.totalCredits)),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              margin: const EdgeInsets.symmetric(horizontal: 18),
                              color: Colors.white.withOpacity(0.12),
                            ),
                            _HeroStat(
                              label: "Paid out",
                              value: w == null ? "—" : agentMoney(w.totalDebits),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---------------- Stat tiles ----------------
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.stars_rounded,
                    color: _agentGold,
                    value: e == null ? "—" : "${e.points}",
                    label: "Points",
                    cardColor: cardColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF0071E3),
                    value: "${p.agentVendors.length}",
                    label: "Vendors",
                    cardColor: cardColor,
                    onTap: onOpenTab == null ? null : () => onOpenTab!(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF34C759),
                    value: e == null ? "—" : "${e.referredCustomers}",
                    label: "Referred",
                    cardColor: cardColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ---------------- Promo code ----------------
            _Card(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your promo code",
                    style: ptstyle(size: 12, weight: 500, color: ch.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (code == null || code.isEmpty) ? "Not available yet" : code,
                    style: ptstyle(
                      size: (code == null || code.isEmpty) ? 15 : 24,
                      weight: 800,
                      color: ch.onSurface,
                    ).copyWith(letterSpacing: (code == null || code.isEmpty) ? 0 : 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Customers enter it under Profile → Promo Code.",
                    style: ptstyle(size: 11, weight: 400, color: ch.onSurfaceVariant),
                  ),
                  if (code != null && code.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PillButton(
                            icon: Icons.copy_rounded,
                            label: "Copy",
                            background: ch.onSurface.withOpacity(0.06),
                            foreground: ch.onSurface,
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Promo code copied")),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PillButton(
                            icon: Icons.chat_rounded,
                            label: "WhatsApp",
                            background: const Color(0xFF25D366),
                            foreground: Colors.white,
                            onTap: () async {
                              final text = Uri.encodeComponent(
                                "Get your next phone on flexible payments with FlexiPhones. "
                                "Enter my promo code $code in the app under Profile → Promo Code.",
                              );
                              final uri = Uri.parse("https://wa.me/?text=$text");
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ---------------- How you earn ----------------
            if (e != null) ...[
              const SizedBox(height: 14),
              _Card(
                color: _agentGold.withOpacity(isDark ? 0.12 : 0.08),
                shadow: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: _agentGold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "How you earn",
                            style: ptstyle(size: 13, weight: 700, color: ch.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.ratesSentence,
                            style: ptstyle(
                              size: 12,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                            ).copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ---------------- Quick actions ----------------
            const SizedBox(height: 22),
            Text(
              "Quick actions",
              style: ptstyle(size: 16, weight: 800, color: ch.onSurface)
                  .copyWith(letterSpacing: -0.3),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                _ActionTile(
                  icon: Icons.add_business_rounded,
                  color: const Color(0xFFFF6B4A),
                  title: "Onboard vendor",
                  subtitle: "Sign up a new shop",
                  cardColor: cardColor,
                  onTap: () => NavigationHelper.push(context, const OnboardVendor()),
                ),
                _ActionTile(
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF0071E3),
                  title: "My vendors",
                  subtitle: "Status & invitations",
                  cardColor: cardColor,
                  onTap: onOpenTab == null ? null : () => onOpenTab!(1),
                ),
                _ActionTile(
                  icon: Icons.ios_share_rounded,
                  color: const Color(0xFF34C759),
                  title: "Share code",
                  subtitle: "Invite customers",
                  cardColor: cardColor,
                  onTap: onOpenTab == null ? null : () => onOpenTab!(2),
                ),
                _ActionTile(
                  icon: Icons.insights_rounded,
                  color: _agentGold,
                  title: "Wallet",
                  subtitle: "Withdraw & earnings",
                  cardColor: cardColor,
                  onTap: onOpenTab == null ? null : () => onOpenTab!(3),
                ),
              ],
            ),

            // ---------------- Recent activity ----------------
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Recent activity",
                    style: ptstyle(size: 16, weight: 800, color: ch.onSurface)
                        .copyWith(letterSpacing: -0.3),
                  ),
                ),
                if (recent.isNotEmpty && onOpenTab != null)
                  TextButton(
                    onPressed: () => onOpenTab!(3),
                    child: Text(
                      "See all",
                      style: ptstyle(size: 12, weight: 700, color: _agentGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _Card(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child:
                  recent.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 30,
                              color: ch.onSurfaceVariant.withOpacity(0.35),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.loadingTx
                                  ? "Loading..."
                                  : "No activity yet. Commissions show up here.",
                              textAlign: TextAlign.center,
                              style: ptstyle(
                                size: 12,
                                weight: 400,
                                color: ch.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        children: [
                          for (int i = 0; i < recent.length; i++) ...[
                            AgentTxRow(tx: recent[i]),
                            if (i < recent.length - 1)
                              Divider(
                                height: 1,
                                color: ch.onSurfaceVariant.withOpacity(0.08),
                              ),
                          ],
                        ],
                      ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// White (or dark-surface) rounded card with a whisper of shadow.
class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(16),
    this.shadow = true,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            shadow && !isDark
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ]
                : null,
      ),
      child: child,
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ptstyle(size: 11, weight: 500, color: Colors.white.withOpacity(0.55)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: ptstyle(size: 15, weight: 700, color: Colors.white),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.cardColor,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final Color cardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return _Tappable(
      color: cardColor,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ptstyle(size: 20, weight: 800, color: ch.onSurface)
                  .copyWith(letterSpacing: -0.5),
            ),
            Text(
              label,
              style: ptstyle(size: 11, weight: 500, color: ch.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color cardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return _Tappable(
      color: cardColor,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(size: 13, weight: 700, color: ch.onSurface),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ptstyle(size: 10, weight: 400, color: ch.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card surface with a soft shadow and a gentle press-down.
class _Tappable extends StatefulWidget {
  const _Tappable({required this.child, required this.color, this.onTap});
  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _down = v),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(label, style: ptstyle(size: 13, weight: 700, color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Link your Ghana Card" / "We're reviewing your account": the server's
/// own title and message. Nothing is locked on it.
class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({required this.approval, required this.onLink});
  final AgentApproval approval;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final blocked = approval.state == "blocked";
    final reviewing = approval.state == "under_review";
    final color =
        blocked
            ? const Color(0xFFE5484D)
            : reviewing
            ? const Color(0xFF0071E3)
            : const Color(0xFFC9871A);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            blocked
                ? Icons.block_rounded
                : reviewing
                ? Icons.hourglass_top_rounded
                : Icons.badge_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval.title,
                  style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  approval.message,
                  style: ptstyle(
                    size: 12,
                    weight: 400,
                    color: ch.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (approval.canLinkGhanaCard &&
                    approval.state == "needs_ghana_card") ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onLink,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "Link Ghana Card",
                        style: ptstyle(
                          size: 12.5,
                          weight: 700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Agent | Shop" switch at the top of the dashboard. Agent is where you
/// are; tapping Shop goes to the customer side (buy phones for yourself).
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.onShop});
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    Widget seg({
      required IconData icon,
      required String label,
      required bool on,
      VoidCallback? onTap,
    }) => Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow:
                on
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: on ? _agentGold : ch.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(
                    size: 13.5,
                    weight: on ? 700 : 600,
                    color: on ? ch.onSurface : ch.onSurfaceVariant,
                  ),
                ),
              ),
              if (!on) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: ch.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ch.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          seg(icon: Icons.workspace_premium_rounded, label: "Agent", on: true),
          seg(
            icon: Icons.storefront_rounded,
            label: "Shop",
            on: false,
            onTap: () {
              HapticFeedback.selectionClick();
              onShop();
            },
          ),
        ],
      ),
    );
  }
}
