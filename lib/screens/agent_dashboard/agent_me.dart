import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_notifications.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/screens/profile/delete_account.dart';
import 'package:flexiphones/screens/profile/edit_profile.dart';
import 'package:flexiphones/screens/profile/add_phone.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/ghana_card_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF0071E3);
const _bg = Color(0xFFF2F4F7);

/// The agent's profile: an Agent / Customer switch at the top, an ID-card
/// style header with the promo code, quick stats, the details list and
/// settings.
class AgentMe extends StatelessWidget {
  const AgentMe({super.key});

  /// Back to the customer side: the customer home is underneath when the
  /// agent side was opened from it; otherwise open it fresh.
  static Future<void> switchToCustomer(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final p = Provider.of<SharedProvider>(context, listen: false);
    final nav = Navigator.of(context);
    void go() {
      if (nav.canPop()) {
        nav.pop();
      } else {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    }

    // Already a customer on this phone: just switch.
    if (p.userData != null) return go();

    // No customer side yet: offer to add it with the same email.
    final add = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ch = Theme.of(ctx).colorScheme;
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(
            color: ch.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Shop as a customer", style: ptstyle(size: 19, weight: 700, color: ch.onSurface)),
                const SizedBox(height: 6),
                Text(
                  "We'll add a customer account to ${p.partnerData?.email ?? "your email"}, using the same sign-in, phone and Ghana Card. You can switch between the two any time.",
                  style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant, height: 1.45),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0071E3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text("Add customer account", style: ptstyle(size: 15, weight: 700, color: Colors.white)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text("Just browse for now", style: ptstyle(size: 13.5, weight: 600, color: ch.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (add == null) return;
    if (add == false) return go();
    var r = await p.becomeCustomer();
    if (!context.mounted) return;
    // 422 "Add a phone number to your profile first": ask, then retry.
    if (!r.ok && r.message.toLowerCase().contains("phone")) {
      final added = await AddPhoneScreen.open(context, agent: true);
      if (added != true || !context.mounted) return;
      r = await p.becomeCustomer();
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          r.message.isNotEmpty
              ? r.message
              : (r.ok ? "Customer account added." : "Couldn't add it. Try again."),
        ),
      ),
    );
    if (!r.ok) return;
    if (r.signedIn) return go();
    // Added, but sign in once on the customer side (email filled in).
    p.emailEditingController.text = p.partnerData?.email ?? "";
    go();
    nav.push(MaterialPageRoute(builder: (_) => const EmailSignin()));
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final a = p.partnerData;
    final code = p.agentPromoCode ?? "";
    final name = a?.name ?? "Agent";
    final active = a?.isActive ?? false;

    return ColoredBox(
      color: _bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            FadeSlideIn(
              child: _AccountSwitch(
                onCustomer: () => switchToCustomer(context),
              ),
            ),
            const SizedBox(height: 18),

            // ID card
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C0F2E), Color(0xFF5B2A9E), Color(0xFF2E8BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B2A9E).withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap:
                                () => EditProfileScreen.open(
                                  context,
                                  agent: true,
                                ),
                            child: ProfileAvatar(
                              name: name,
                              url: a?.photoUrl,
                              size: 58,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ptstyle(
                                  size: 19,
                                  weight: 800,
                                  color: Colors.white,
                                ).copyWith(letterSpacing: -0.4),
                              ),
                              Text(
                                a?.email ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ptstyle(
                                  size: 12,
                                  weight: 400,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (active
                                    ? const Color(0xFF30D158)
                                    : const Color(0xFFFF9F0A))
                                .withOpacity(0.25),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            a?.status ?? "",
                            style: ptstyle(
                              size: 11,
                              weight: 700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "PROMO CODE",
                      style: ptstyle(
                        size: 10,
                        weight: 700,
                        color: Colors.white60,
                      ).copyWith(letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            code.isEmpty ? "Not available" : code,
                            style: ptstyle(
                              size: code.isEmpty ? 15 : 26,
                              weight: 800,
                              color: Colors.white,
                            ).copyWith(letterSpacing: code.isEmpty ? 0 : 3),
                          ),
                        ),
                        if (code.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Promo code copied"),
                                ),
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.16),
                            ),
                            icon: const Icon(
                              Icons.copy_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Stats
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Row(
                children: [
                  _Stat(
                    icon: Icons.storefront_rounded,
                    color: _blue,
                    value: "${p.agentVendors.length}",
                    label: "Vendors",
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFFBF5AF2),
                    value: "${p.promoUsage?.timesUsed ?? 0}",
                    label: "Code uses",
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF30A14E),
                    value:
                        "GHS ${(p.partnerWallet?.balance ?? 0).toStringAsFixed(0)}",
                    label: "Wallet",
                  ),
                ],
              ),
            ),

            _title(ch, "Details"),
            _Group(
              children: [
                _Row(
                  icon: Icons.edit_rounded,
                  label: "Edit profile",
                  value: "",
                  chevron: true,
                  onTap: () => EditProfileScreen.open(context, agent: true),
                ),
                _Row(icon: Icons.phone_rounded, label: "Phone", value: a?.phone ?? ""),
                _Row(icon: Icons.map_rounded, label: "Region", value: a?.region ?? ""),
                _Row(
                  icon: Icons.home_rounded,
                  label: "Address",
                  value: a?.address ?? "",
                ),
                _Row(
                  icon: Icons.badge_rounded,
                  label: "Ghana Card",
                  value: a?.ghanaCard ?? "Not linked",
                  action:
                      a?.ghanaCard == null
                          ? TextButton(
                            onPressed:
                                () => showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const AgentGhanaCardDialog(),
                                ),
                            child: Text(
                              "Link",
                              style: ptstyle(
                                size: 13,
                                weight: 700,
                                color: _blue,
                              ),
                            ),
                          )
                          : null,
                ),
                _Row(
                  icon: Icons.phone_android_rounded,
                  label: "Mobile money",
                  value:
                      (a?.momoNumber ?? "").isEmpty
                          ? "Not set"
                          : "${a?.momoNetwork ?? ""} ${a?.momoNumber}".trim(),
                ),
              ],
            ),

            _title(ch, "Settings"),
            _Group(
              children: [
                _Row(
                  icon: Icons.notifications_active_rounded,
                  label: "Notifications",
                  value: "",
                  chevron: true,
                  onTap:
                      () => NavigationHelper.push(
                        context,
                        const AgentNotificationSettingsScreen(),
                      ),
                ),
                _Row(
                  icon: Icons.swap_horiz_rounded,
                  label: "Switch to customer",
                  value: "",
                  chevron: true,
                  onTap: () => switchToCustomer(context),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE5484D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => p.agentLogout(),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  "Sign out of agent account",
                  style: ptstyle(size: 14, weight: 600),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const LegalRows(),
            const SizedBox(height: 6),
            const DeleteAccountLink(agent: true),
          ],
        ),
      ),
    );
  }

  Widget _title(ColorScheme ch, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
    child: Text(
      text,
      style: ptstyle(
        size: 19,
        weight: 800,
        color: ch.onSurface,
      ).copyWith(letterSpacing: -0.5),
    ),
  );
}

/// "Agent | Customer" pill switch. Agent is active here; tapping Customer
/// slides the thumb across, then switches sides.
class _AccountSwitch extends StatefulWidget {
  const _AccountSwitch({required this.onCustomer});
  final VoidCallback onCustomer;

  @override
  State<_AccountSwitch> createState() => _AccountSwitchState();
}

class _AccountSwitchState extends State<_AccountSwitch> {
  bool _customer = false;

  Future<void> _go() async {
    if (_customer) return;
    setState(() => _customer = true);
    await Future.delayed(const Duration(milliseconds: 320));
    if (mounted) widget.onCustomer();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    Widget side(String label, IconData icon, bool on, VoidCallback? onTap) =>
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: on ? Colors.white : ch.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: ptstyle(
                      size: 13.5,
                      weight: on ? 700 : 500,
                      color: on ? Colors.white : ch.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ch.surface,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: _customer ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: LinearGradient(
                    colors:
                        _customer
                            ? const [Color(0xFF2E8BFF), Color(0xFF0058C7)]
                            : const [Color(0xFF8E5CFF), Color(0xFF5B2A9E)],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              side("Agent", Icons.workspace_premium_rounded, !_customer, null),
              side("Customer", Icons.person_rounded, _customer, _go),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: ptstyle(
                  size: 17,
                  weight: 800,
                  color: ch.onSurface,
                ).copyWith(letterSpacing: -0.4),
              ),
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

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: ch.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: ch.onSurface.withOpacity(0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.action,
    this.onTap,
    this.chevron = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? action;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: _blue),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: ptstyle(size: 14, weight: 500, color: ch.onSurface),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty && !chevron ? "—" : value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ptstyle(
                  size: 13,
                  weight: 400,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ),
            if (action != null) action!,
            if (chevron)
              Icon(
                Icons.chevron_right_rounded,
                color: ch.onSurfaceVariant.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }
}

/// POST /partner/update-ghana-card/{id} — backend format GHA-XXXXXXXXX-X,
/// so the user only types the 9 digits, a dash and the last digit.
class AgentGhanaCardDialog extends StatefulWidget {
  const AgentGhanaCardDialog();

  @override
  State<AgentGhanaCardDialog> createState() => AgentGhanaCardDialogState();
}

class AgentGhanaCardDialogState extends State<AgentGhanaCardDialog> {
  final controller = TextEditingController();
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = controller.text.trim();
    if (!v.isValidGhanaCardDigits) {
      setState(() => error = "Enter all 10 digits of your Ghana Card");
      return;
    }
    setState(() => error = null);
    final p = Provider.of<SharedProvider>(context, listen: false);
    final ok = await p.updateAgentGhanaCard(context, v);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final saving = Provider.of<SharedProvider>(context).ghanaCardSaving;
    return AlertDialog(
      backgroundColor: ch.surface,
      title: Text(
        "Link Ghana Card",
        style: ptstyle(size: 16, weight: 600, color: ch.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Type the 10 digits. We add GHA- and the dash for you.",
              style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            GhanaCardField(
              controller: controller,
              enabled: !saving,
              autofocus: true,
              onChanged: (_, _) {
                if (error != null) setState(() => error = null);
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: ptstyle(size: 12, weight: 600, color: const Color(0xFFE5484D)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(onPressed: _save, child: const Text("Save")),
      ],
    );
  }
}