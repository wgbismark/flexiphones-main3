import 'package:flexiphones/helpers/app_update.dart';
import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_earnings.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_referrals.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Agent notifications — GET /partner/notifications. Tapping one marks it
/// read and opens the related list: vendor decisions and new orders open
/// "My vendors", down payments open the wallet (the commission is there),
/// referral points open Earnings (the points history is there).
class AgentNotificationsScreen extends StatefulWidget {
  const AgentNotificationsScreen({super.key});

  @override
  State<AgentNotificationsScreen> createState() =>
      _AgentNotificationsScreenState();
}

class _AgentNotificationsScreenState extends State<AgentNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SharedProvider>(context, listen: false).getAgentNotifications();
    });
  }

  void _open(SharedProvider p, AgentNotification n) {
    if (n.isUnread) p.markAgentNotificationRead(n.id);

    if (n.kind == "app_update") {
      AppUpdate.openStore(n.androidUrl);
      return;
    }
    Widget? page;
    String title = "";
    switch (n.kind) {
      case "vendor_decision":
      case "vendor_order_placed":
        p.getAgentVendors();
        page = const AgentReferrals();
        title = "My vendors";
      case "vendor_down_payment":
      case "vendor_first_down_payment":
        p.getPartnerWallet();
        p.getPartnerTransactions();
        page = const AgentEarnings();
        title = "Earnings";
      case "referral_points":
        // Points history lives on the Earnings screen.
        p.getPartnerEarnings();
        p.getPartnerPoints();
        page = const AgentEarnings();
        title = "Earnings";
    }
    if (page == null) return;
    final body = page;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title, style: ptstyle(size: 15, weight: 600))),
          body: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final list = p.agentNotifications;

    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(
        backgroundColor: ch.surface,
        scrolledUnderElevation: 0,
        title: Text(
          "Notifications",
          style: ptstyle(size: 15, weight: 600, color: ch.onSurface),
        ),
        actions: [
          if (p.agentUnreadCount > 0)
            TextButton(
              onPressed: p.markAllAgentNotificationsRead,
              child: Text("Mark all read", style: ptstyle(size: 12, weight: 600)),
            ),
          IconButton(
            tooltip: "Notification settings",
            icon: const Icon(Icons.tune_rounded),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AgentNotificationSettingsScreen(),
                  ),
                ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => p.getAgentNotifications(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    p.loadingAgentNotifications
                        ? "Loading..."
                        : "No notifications yet.\nYou'll hear here when FlexiPhones decides on a vendor you onboarded.",
                    textAlign: TextAlign.center,
                    style: ptstyle(
                      size: 12,
                      weight: 300,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...list.map((n) => _NotificationTile(n: n, onTap: () => _open(p, n))),
            if (p.agentNotificationsHasMore)
              Center(
                child: TextButton(
                  onPressed:
                      p.loadingAgentNotifications
                          ? null
                          : () => p.getAgentNotifications(refresh: false),
                  child: Text(
                    p.loadingAgentNotifications ? "Loading..." : "Load more",
                    style: ptstyle(size: 12, weight: 600, color: ch.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});
  final AgentNotification n;
  final VoidCallback onTap;

  ({IconData icon, Color color}) _style(ColorScheme ch) {
    switch (n.kind) {
      case "vendor_decision":
        switch (n.decision) {
          case "approved":
            return (icon: Icons.verified_rounded, color: Colors.green);
          case "declined":
            return (icon: Icons.cancel_outlined, color: Colors.redAccent);
          case "suspended":
            return (icon: Icons.pause_circle_outline, color: Colors.orange);
        }
      case "vendor_order_placed":
        return (icon: Icons.shopping_bag_outlined, color: ch.primary);
      case "vendor_down_payment":
        return (icon: Icons.payments_outlined, color: Colors.green);
      case "vendor_first_down_payment":
        return (icon: Icons.celebration_outlined, color: Colors.green);
      case "account_notice":
        return (icon: Icons.verified_user_outlined, color: ch.primary);
      case "referral_points":
        return (icon: Icons.stars_rounded, color: const Color(0xFFCC9A44));
    }
    return (icon: Icons.notifications_none_rounded, color: ch.onSurfaceVariant);
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final s = _style(ch);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              n.isUnread
                  ? s.color.withOpacity(0.08)
                  : ch.surfaceContainerLow.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(s.icon, color: s.color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: ptstyle(
                            size: 13,
                            weight: n.isUnread ? 700 : 600,
                            color: ch.onSurface,
                          ),
                        ),
                      ),
                      if (n.isUnread)
                        Icon(Icons.circle, size: 8, color: ch.primary),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.message,
                    style: ptstyle(
                      size: 12,
                      weight: 400,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.createdAt.toLocal().formatDate(),
                    style: ptstyle(
                      size: 10,
                      weight: 300,
                      color: ch.onSurfaceVariant.withOpacity(0.7),
                    ),
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

/// One row per notification type with App and Email switches, built from
/// GET /partner/notification-settings (new types appear automatically).
/// Each switch PUTs only the channel that changed.
class AgentNotificationSettingsScreen extends StatefulWidget {
  const AgentNotificationSettingsScreen({super.key});

  @override
  State<AgentNotificationSettingsScreen> createState() =>
      _AgentNotificationSettingsScreenState();
}

class _AgentNotificationSettingsScreenState
    extends State<AgentNotificationSettingsScreen> {
  /// "key.channel" while its PUT is in flight.
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SharedProvider>(
        context,
        listen: false,
      ).getAgentNotificationSettings();
    });
  }

  Future<void> _toggle(
    SharedProvider p,
    AgentNotificationSetting s,
    String channel,
    bool value,
  ) async {
    final id = "${s.key}.$channel";
    setState(() => _saving.add(id));
    await p.updateAgentNotificationSetting(context, s.key, channel, value);
    if (mounted) setState(() => _saving.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final settings = p.agentNotificationSettings;

    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(
        backgroundColor: ch.surface,
        scrolledUnderElevation: 0,
        title: Text(
          "Notification settings",
          style: ptstyle(size: 15, weight: 600, color: ch.onSurface),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: p.getAgentNotificationSettings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Text(
              "Choose how you hear about each type: in the app, by email, both or neither. Turning both off stops that type from now on.",
              style: ptstyle(size: 12, weight: 300, color: ch.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            if (settings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child:
                      p.loadingAgentNotificationSettings
                          ? const CircularProgressIndicator()
                          : Text(
                            "Couldn't load your settings. Pull down to try again.",
                            style: ptstyle(
                              size: 12,
                              weight: 300,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                ),
              )
            else
              ...settings.map(
                (s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ch.onSurfaceVariant.withOpacity(0.15),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.label,
                        style: ptstyle(size: 13, weight: 700, color: ch.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.description,
                        style: ptstyle(
                          size: 11,
                          weight: 300,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      _switchRow(p, s, "app", "In the app", s.app, ch),
                      _switchRow(p, s, "email", "By email", s.email, ch),
                    ],
                  ),
                ),
              ),
            Text(
              "Push notifications and SMS aren't available yet.",
              style: ptstyle(size: 11, weight: 300, color: ch.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(
    SharedProvider p,
    AgentNotificationSetting s,
    String channel,
    String label,
    bool value,
    ColorScheme ch,
  ) {
    final saving = _saving.contains("${s.key}.$channel");
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ptstyle(size: 12, weight: 500, color: ch.onSurface),
          ),
        ),
        if (saving)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          Switch(
            value: value,
            onChanged: (v) => _toggle(p, s, channel, v),
          ),
      ],
    );
  }
}
