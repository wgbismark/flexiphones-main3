import 'dart:async';

import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/vendor_onboarding/onboard_vendor.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Vendors the agent onboarded — GET /partner/my-vendors.
/// (The backend has no "referred customers" list endpoint yet, so this tab
/// only shows vendors. Class name kept so the shell doesn't change.)
class AgentReferrals extends StatelessWidget {
  const AgentReferrals({super.key});

  Color _statusColor(String s, ColorScheme ch) {
    switch (s.toLowerCase()) {
      case "active":
      case "live":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
      case "inactive":
        return Colors.redAccent;
      case "suspended":
        return Colors.deepOrange;
      default:
        return ch.onSurfaceVariant;
    }
  }

  /// Vendor status words as the agent hears them in notifications.
  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case "active":
        return "Approved";
      case "rejected":
        return "Declined";
      default:
        return s.toSentenceCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final List<PartnerVendor> vendors = p.agentVendors;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh:
            () => Future.wait([p.getAgentVendors(), p.getPartnerEarnings()]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "My vendors",
                    style: ptstyle(size: 20, weight: 700, color: ch.onSurface),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      NavigationHelper.push(context, const OnboardVendor()),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text("Onboard", style: ptstyle(size: 12, weight: 600)),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (p.partnerEarnings != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ch.primaryFixed.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_outlined, color: ch.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Customers who used your promo code",
                        style: ptstyle(
                          size: 12,
                          weight: 500,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      "${p.partnerEarnings!.referredCustomers}",
                      style: ptstyle(size: 18, weight: 700, color: ch.onSurface),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            if (vendors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 50,
                      color: ch.onSurfaceVariant.withOpacity(0.4),
                    ),
                    SizedBox(height: 12),
                    Text(
                      p.loadingVendors
                          ? "Loading..."
                          : "You haven't onboarded any vendors yet.",
                      textAlign: TextAlign.center,
                      style: ptstyle(
                        size: 12,
                        weight: 300,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...vendors.map(
                (v) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ch.onSurfaceVariant.withOpacity(0.15),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ch.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.storefront_outlined,
                          size: 18,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ptstyle(
                                size: 13,
                                weight: 600,
                                color: ch.onSurface,
                              ),
                            ),
                            Text(
                              "${v.location} · ${v.createdAt.formatDateNoTime()}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ptstyle(
                                size: 11,
                                weight: 300,
                                color: ch.onSurfaceVariant,
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
                          color: _statusColor(v.status, ch).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          _statusLabel(v.status),
                          style: ptstyle(
                            size: 11,
                            weight: 700,
                            color: _statusColor(v.status, ch),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (v.awaitingVendor)
                    _VendorInvitePanel(vendor: v)
                  else if (v.status.toLowerCase() == "pending")
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "The vendor has set up their account. Waiting for FlexiPhones to verify them.",
                        style: ptstyle(
                          size: 11,
                          weight: 400,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            if (p.vendorsHasMore)
              Center(
                child: TextButton(
                  onPressed:
                      p.loadingVendors
                          ? null
                          : () => p.getAgentVendors(refresh: false),
                  child: Text(
                    p.loadingVendors ? "Loading..." : "Load more",
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

/// Invite state for a vendor still waiting to set a password: how many
/// emails went out and a Resend button that stays disabled (with a
/// countdown) until `next_resend_at`, or a "contact support" note once the
/// 6-email limit is reached.
class _VendorInvitePanel extends StatefulWidget {
  const _VendorInvitePanel({required this.vendor});
  final PartnerVendor vendor;

  @override
  State<_VendorInvitePanel> createState() => _VendorInvitePanelState();
}

class _VendorInvitePanelState extends State<_VendorInvitePanel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Re-render every 30s so the countdown moves and the button wakes up.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final invite = widget.vendor.invite!;
    final resending = p.resendingInvites.contains(widget.vendor.id);

    final next = invite.nextResendAt;
    final now = DateTime.now();
    final canResend =
        invite.canResend || (next != null && !now.isBefore(next.toLocal()));
    String? wait;
    if (!canResend && next != null) {
      final mins = next.toLocal().difference(now).inMinutes + 1;
      wait = mins <= 1 ? "Available in a minute" : "Available in $mins min";
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, size: 14, color: Colors.orange),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Waiting for the vendor to set up",
                  style: ptstyle(size: 12, weight: 600, color: ch.onSurface),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            "${invite.invitesSent} invitation${invite.invitesSent == 1 ? "" : "s"} sent"
            "${invite.lastInvitedAt == null ? "" : " · last ${invite.lastInvitedAt!.toLocal().formatDate()}"}",
            style: ptstyle(size: 11, weight: 300, color: ch.onSurfaceVariant),
          ),
          SizedBox(height: 8),
          if (invite.resendLimitReached)
            Text(
              "Invitation limit reached. Please contact FlexiPhones support.",
              style: ptstyle(size: 11, weight: 600, color: Colors.redAccent),
            )
          else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed:
                      (!canResend || resending)
                          ? null
                          : () => p.resendVendorInvite(context, widget.vendor.id),
                  icon:
                      resending
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send_rounded, size: 14),
                  label: Text(
                    "Resend invitation",
                    style: ptstyle(size: 11, weight: 600),
                  ),
                ),
                if (wait != null) ...[
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      wait,
                      style: ptstyle(
                        size: 11,
                        weight: 300,
                        color: ch.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}