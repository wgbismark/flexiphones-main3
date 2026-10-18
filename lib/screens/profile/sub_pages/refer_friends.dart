import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// The customer's own referral code and points wallet:
/// GET /customer/referral, POST /customer/referral-code,
/// POST /customer/apply-referral-code, GET /customer/referrals and
/// GET /customer/points. Not the agent promo code (see PromoCodePage).
class ReferFriendsPage extends StatefulWidget {
  const ReferFriendsPage({super.key});

  @override
  State<ReferFriendsPage> createState() => _ReferFriendsPageState();
}

class _ReferFriendsPageState extends State<ReferFriendsPage> {
  final _friendCode = TextEditingController();
  int _tab = 0; // 0 friends, 1 points history

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _friendCode.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    await Future.wait([
      p.getReferral(),
      p.getReferredFriends(),
      p.getCustomerPoints(),
    ]);
  }

  void _copy(String text, String toast) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast)));
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final r = p.referral;

    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(
        backgroundColor: ch.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Refer a Friend",
          style: ptstyle(size: 14, weight: 400, color: ch.onSurfaceVariant),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              "Share FlexiPhones.\nEarn points.",
              style: ptstyle(
                size: 28,
                weight: 700,
                color: ch.onSurface,
                height: 1.15,
              ).copyWith(letterSpacing: -0.8),
            ),
            const SizedBox(height: 8),
            Text(
              r == null || r.pointsPerReferral <= 0
                  ? "Invite friends to get their phone on easy daily payments."
                  : "Get ${r.pointsPerReferral} points for every friend who joins with your code.",
              style: ptstyle(size: 13, weight: 400, color: ch.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _codeCard(ch, p),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    ch,
                    "${p.customerPointsBalance ?? r?.points ?? 0}",
                    "Points",
                    Icons.stars_rounded,
                    const Color(0xFFCC9A44),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _stat(
                    ch,
                    "${r?.referralCount ?? 0}",
                    "Friends joined",
                    Icons.people_alt_rounded,
                    ch.primary,
                  ),
                ),
              ],
            ),
            if (r != null && !r.referredByCustomer) ...[
              const SizedBox(height: 24),
              _applyCard(ch, p),
            ],
            const SizedBox(height: 26),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text("Friends")),
                ButtonSegment(value: 1, label: Text("Points history")),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            const SizedBox(height: 12),
            if (_tab == 0) ..._friends(ch, p) else ..._history(ch, p),
          ],
        ),
      ),
    );
  }

  Widget _codeCard(ColorScheme ch, SharedProvider p) {
    final r = p.referral;
    final code = r?.referralCode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D1D1F), Color(0xFF3A3A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "YOUR REFERRAL CODE",
            style: ptstyle(
              size: 10,
              weight: 600,
              color: Colors.white60,
            ).copyWith(letterSpacing: 1.4),
          ),
          const SizedBox(height: 10),
          if (p.loadingReferral && r == null)
            const SizedBox(
              height: 44,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (code == null) ...[
            Text(
              "You don't have a code yet.",
              style: ptstyle(size: 14, weight: 500, color: Colors.white),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D1D1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    p.creatingReferralCode
                        ? null
                        : () => p.createReferralCode(context),
                child:
                    p.creatingReferralCode
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          "Get my referral code",
                          style: ptstyle(size: 14, weight: 600),
                        ),
              ),
            ),
          ] else ...[
            Text(
              code,
              style: ptstyle(
                size: 32,
                weight: 700,
                color: Colors.white,
              ).copyWith(letterSpacing: 4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _darkButton(
                    Icons.copy_rounded,
                    "Copy",
                    () => _copy(code, "Referral code copied"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _darkButton(
                    Icons.ios_share_rounded,
                    "Share",
                    () => _copy(
                      "Join FlexiPhones with my code $code and get your phone on easy daily payments.",
                      "Invite message copied. Paste it in any chat",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _darkButton(IconData icon, String label, VoidCallback onTap) =>
      SizedBox(
        height: 44,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.14),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label, style: ptstyle(size: 13, weight: 600)),
        ),
      );

  Widget _stat(
    ColorScheme ch,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ch.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: ptstyle(
              size: 24,
              weight: 700,
              color: ch.onSurface,
            ).copyWith(letterSpacing: -0.5),
          ),
          Text(
            label,
            style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _applyCard(ColorScheme ch, SharedProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ch.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Got a friend's code?",
            style: ptstyle(size: 15, weight: 700, color: ch.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            "You can use one friend's code, once.",
            style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          OutlineInput(
            controller: _friendCode,
            enabled: !p.applyingReferral,
            label: "Friend's referral code",
            hintText: "e.g. FXK7M2QPA",
            maxLength: 20,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: SmartButton(
              enabled: !p.applyingReferral,
              loading: p.applyingReferral,
              onPressed: () async {
                FocusScope.of(context).unfocus();
                final ok = await p.applyReferralCode(context, _friendCode.text);
                if (ok) _friendCode.clear();
              },
              child: Text("Apply code", style: ptstyle(size: 13, weight: 600)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _friends(ColorScheme ch, SharedProvider p) {
    if (p.loadingFriends && p.referredFriends.isEmpty) {
      return [const Center(child: CircularProgressIndicator())];
    }
    if (p.referredFriends.isEmpty) {
      return [_empty(ch, "Friends who join with your code will show up here.")];
    }
    return [
      _group(ch, [
        for (final f in p.referredFriends)
          _row(
            ch,
            leading: f.name.isEmpty ? "?" : f.name[0].toUpperCase(),
            title: f.name,
            trailing: f.joinedAt == null ? "" : "Joined ${f.joinedAt!.toAgo()}",
          ),
      ]),
      if (p.friendsHasMore)
        TextButton(
          onPressed: () => p.getReferredFriends(refresh: false),
          child: const Text("Load more"),
        ),
    ];
  }

  List<Widget> _history(ColorScheme ch, SharedProvider p) {
    if (p.loadingCustomerPoints && p.customerPoints.isEmpty) {
      return [const Center(child: CircularProgressIndicator())];
    }
    if (p.customerPoints.isEmpty) {
      return [_empty(ch, "Points you earn will be listed here.")];
    }
    return [
      _group(ch, [
        for (final e in p.customerPoints)
          _row(
            ch,
            leading: "+",
            title: e.description.isEmpty ? e.reason : e.description,
            trailing: "${e.points > 0 ? "+" : ""}${e.points} pts",
            sub: e.createdAt?.toAgo(),
          ),
      ]),
      if (p.customerPointsHasMore)
        TextButton(
          onPressed: () => p.getCustomerPoints(refresh: false),
          child: const Text("Load more"),
        ),
    ];
  }

  Widget _empty(ColorScheme ch, String text) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: ch.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
    ),
  );

  Widget _group(ColorScheme ch, List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: ch.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1)
            Divider(
              height: 1,
              indent: 62,
              color: ch.outlineVariant.withOpacity(0.4),
            ),
        ],
      ],
    ),
  );

  Widget _row(
    ColorScheme ch, {
    required String leading,
    required String title,
    required String trailing,
    String? sub,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: ch.primary.withOpacity(0.12),
            child: Text(
              leading,
              style: ptstyle(size: 13, weight: 700, color: ch.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(size: 13, weight: 600, color: ch.onSurface),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: ptstyle(
                      size: 11,
                      weight: 400,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: ptstyle(size: 11, weight: 600, color: ch.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
