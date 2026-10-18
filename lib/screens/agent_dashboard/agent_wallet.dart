import 'dart:async';
import 'dart:math' as math;

import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_earnings.dart'
    show AgentPointsRow, MomoDialog;
import 'package:flexiphones/screens/agent_dashboard/withdraw_sheet.dart';
import 'package:flexiphones/shared_widgets/fade_slide_in.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const _violet = Color(0xFF7C4DFF);
const _green = Color(0xFF30A14E);
const _red = Color(0xFFE5484D);
const _orange = Color(0xFFFF9F0A);
const _bg = Color(0xFFF2F4F7);

String cedi(num v) => "₵${v.toDouble().toCommaSeparated(0, decimalPlaces: 2)}";

/// "in 5 hours", "in 20 minutes", "tomorrow at 10:00", "on Wed 14 Oct at 09:00".
String releaseLabel(DateTime at) {
  final now = DateTime.now();
  final d = at.difference(now);
  if (d.inMinutes <= 0) return "any moment now";
  if (d.inMinutes < 60) return "in ${d.inMinutes} minute${d.inMinutes == 1 ? "" : "s"}";
  final sameDay = at.year == now.year && at.month == now.month && at.day == now.day;
  if (d.inHours < 12 || sameDay) {
    final h = (d.inMinutes / 60).round();
    return "in $h hour${h == 1 ? "" : "s"}";
  }
  final tomorrow = now.add(const Duration(days: 1));
  if (at.year == tomorrow.year && at.month == tomorrow.month && at.day == tomorrow.day) {
    return "tomorrow at ${DateFormat("HH:mm").format(at)}";
  }
  return "on ${DateFormat("EEE d MMM 'at' HH:mm").format(at)}";
}

/// The agent's wallet: what can be withdrawn now vs the actual balance,
/// a Withdraw button, and tabs for activity, withdrawals and earnings.
class AgentWallet extends StatefulWidget {
  const AgentWallet({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<AgentWallet> createState() => _AgentWalletState();
}

class _AgentWalletState extends State<AgentWallet> with WidgetsBindingObserver {
  late int _tab = widget.initialTab;
  Timer? _poll;
  DateTime? _pollStarted;
  Timer? _release;
  Map<String, String> _lastStatus = {};

  SharedProvider get _p => Provider.of<SharedProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _release?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Money unlocks by itself as time passes: refresh on return.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _p.getPartnerWallet(),
      _p.getWithdrawals(silent: true),
      _p.getPartnerTransactions(),
      _p.getMomoDetails(),
    ]);
    if (!mounted) return;
    _remember();
    _scheduleRelease();
    if (_p.hasPendingWithdrawal) _startPolling();
  }

  void _remember() {
    _lastStatus = {for (final w in _p.withdrawals) w.reference: w.status};
  }

  /// Re-read the wallet the moment the next amount becomes withdrawable.
  void _scheduleRelease() {
    _release?.cancel();
    final at = _p.partnerWallet?.nextReleaseAt;
    if (at == null) return;
    final d = at.difference(DateTime.now());
    if (d.isNegative || d > const Duration(hours: 24)) return;
    _release = Timer(d + const Duration(seconds: 5), () {
      if (mounted) _refresh();
    });
  }

  /// While a withdrawal is on its way: check every 7s for up to 2 minutes.
  void _startPolling() {
    if (_poll != null) return;
    _pollStarted = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 7), (t) async {
      if (!mounted) return t.cancel();
      if (DateTime.now().difference(_pollStarted!) > const Duration(minutes: 2)) {
        t.cancel();
        _poll = null;
        return;
      }
      await _p.getWithdrawals(silent: true);
      if (!mounted) return;
      var settled = false;
      for (final w in _p.withdrawals) {
        final before = _lastStatus[w.reference];
        if (before != null && before != w.status && !w.isPending) {
          settled = true;
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: w.isPaid ? _green : _red,
              content: Text(
                w.isPaid
                    ? "${cedi(w.amount)} reached your Mobile Money"
                    : "Withdrawal of ${cedi(w.amount)} failed. Nothing was taken from your wallet.",
              ),
            ),
          );
        }
      }
      _remember();
      if (settled) {
        await Future.wait([_p.getPartnerWallet(), _p.getPartnerTransactions()]);
      }
      if (!_p.hasPendingWithdrawal) {
        t.cancel();
        _poll = null;
      }
    });
  }

  void _withdraw() {
    HapticFeedback.mediumImpact();
    showWithdrawSheet(
      context,
      onStarted: () {
        if (!mounted) return;
        setState(() => _tab = 1);
        _remember();
        _startPolling();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final w = p.partnerWallet;
    final pending = p.withdrawals.where((x) => x.isPending).toList();

    return ColoredBox(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Text(
                      "Wallet",
                      style: ptstyle(
                        size: 30,
                        weight: 800,
                        color: ch.onSurface,
                      ).copyWith(letterSpacing: -1),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _BalanceCard(wallet: w, onWithdraw: _withdraw),
                  ),
                ),
              ),
              if (pending.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _OnItsWay(
                      total: pending.fold<double>(0, (s, x) => s + x.amount),
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                ),
              if ((w?.holdHours ?? 0) > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: ch.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Money you earn can be withdrawn ${w!.holdHours} hour${w.holdHours == 1 ? "" : "s"} after it arrives.",
                            style: ptstyle(
                              size: 11.5,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: _Tabs(
                    selected: _tab,
                    labels: const ["Activity", "Withdrawals", "Earnings"],
                    onSelect: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _tab = i);
                      if (i == 1) p.getWithdrawals(silent: true);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder:
                      (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(a),
                          child: c,
                        ),
                      ),
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      child: switch (_tab) {
                        0 => _Activity(holdHours: w?.holdHours ?? 0),
                        1 => _WithdrawalList(onWithdraw: _withdraw),
                        _ => const _EarningsTab(),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance card
// ---------------------------------------------------------------------------

class _BalanceCard extends StatefulWidget {
  const _BalanceCard({required this.wallet, required this.onWithdraw});
  final PartnerWallet? wallet;
  final VoidCallback onWithdraw;

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wallet;
    final p = Provider.of<SharedProvider>(context);
    final available = p.withdrawAvailable ?? w?.withdrawable ?? 0;
    final ratio =
        w == null || w.balance <= 0
            ? 0.0
            : (w.withdrawable / w.balance).clamp(0.0, 1.0);
    final momo = p.momoDetails;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B0F3B), Color(0xFF3A1C8C), Color(0xFF5B3BE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Two soft lights drifting slowly
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glow,
              builder: (_, _) {
                final t = _glow.value * 2 * math.pi;
                return Stack(
                  children: [
                    Align(
                      alignment: Alignment(
                        0.9 + 0.2 * math.cos(t),
                        -1 + 0.3 * math.sin(t),
                      ),
                      child: _orb(const Color(0xFF64D2FF), 220),
                    ),
                    Align(
                      alignment: Alignment(
                        -1 + 0.3 * math.sin(t),
                        1 + 0.2 * math.cos(t),
                      ),
                      child: _orb(const Color(0xFFFF6BD6), 200),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "WITHDRAWABLE",
                      style: ptstyle(
                        size: 10.5,
                        weight: 700,
                        color: Colors.white60,
                      ).copyWith(letterSpacing: 1.6),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: w?.withdrawable ?? 0),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder:
                      (_, v, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          w == null ? "—" : cedi(v),
                          style: ptstyle(
                            size: 40,
                            weight: 800,
                            color: Colors.white,
                          ).copyWith(letterSpacing: -1.5),
                        ),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Actual balance ${w == null ? "—" : cedi(w.balance)}",
                  style: ptstyle(size: 13, weight: 500, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder:
                        (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          color: const Color(0xFF64D2FF),
                          backgroundColor: Colors.white.withOpacity(0.15),
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                if (w != null && w.maturing > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_clock_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          w.nextReleaseAt == null
                              ? "${cedi(w.maturing)} is still waiting out the hold time"
                              : "${cedi(w.maturing)} becomes available ${releaseLabel(w.nextReleaseAt!)}",
                          style: ptstyle(
                            size: 12,
                            weight: 500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    w == null || w.balance == 0
                        ? "Earnings land here as your vendors sell."
                        : "All of it can be withdrawn now.",
                    style: ptstyle(size: 12, weight: 500, color: Colors.white70),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PressScale(
                        onTap: available > 0 ? widget.onWithdraw : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: available > 0 ? 1 : 0.45,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Color(0xFF3A1C8C),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Withdraw",
                                  style: ptstyle(
                                    size: 15.5,
                                    weight: 800,
                                    color: const Color(0xFF3A1C8C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PressScale(
                      onTap:
                          () => showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => MomoDialog(current: momo),
                          ),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_iphone_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (momo?.isSet ?? false) ? momo!.network ?? "MoMo" : "Add MoMo",
                              style: ptstyle(
                                size: 13,
                                weight: 700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(Color c, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c.withOpacity(0.4), c.withOpacity(0)]),
    ),
  );
}

class _OnItsWay extends StatefulWidget {
  const _OnItsWay({required this.total, required this.onTap});
  final double total;
  final VoidCallback onTap;

  @override
  State<_OnItsWay> createState() => _OnItsWayState();
}

class _OnItsWayState extends State<_OnItsWay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return PressScale(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ch.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _orange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _c,
              builder:
                  (_, _) => Transform.translate(
                    offset: Offset(0, -3 * math.sin(_c.value * math.pi * 2)),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: _orange,
                        size: 18,
                      ),
                    ),
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${cedi(widget.total)} on its way",
                    style: ptstyle(size: 14, weight: 700, color: ch.onSurface),
                  ),
                  Text(
                    "Usually a minute or two. It may take a little longer.",
                    style: ptstyle(
                      size: 11.5,
                      weight: 400,
                      color: ch.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

/// Sliding segmented control.
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 8) / labels.length;
        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ch.onSurface.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: w * selected,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: ch.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(i),
                        child: Center(
                          child: Text(
                            labels[i],
                            style: ptstyle(
                              size: 13,
                              weight: i == selected ? 700 : 500,
                              color:
                                  i == selected
                                      ? ch.onSurface
                                      : ch.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tabs
// ---------------------------------------------------------------------------

class _Activity extends StatelessWidget {
  const _Activity({required this.holdHours});
  final int holdHours;

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SharedProvider>(context);
    final list = p.partnerTransactions;
    if (list.isEmpty) {
      return _Empty(
        icon: Icons.receipt_long_rounded,
        title: p.loadingTx ? "Loading…" : "No activity yet",
        text: "Commissions and withdrawals show up here.",
      );
    }
    return Column(
      children: [
        _Group(
          children: [
            for (final t in list) _TxRow(tx: t, holdHours: holdHours),
          ],
        ),
        if (p.txHasMore)
          TextButton(
            onPressed:
                p.loadingTx ? null : () => p.getPartnerTransactions(refresh: false),
            child: Text(
              p.loadingTx ? "Loading…" : "Load more",
              style: ptstyle(size: 13, weight: 600, color: _violet),
            ),
          ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx, required this.holdHours});
  final WalletTransaction tx;
  final int holdHours;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final credit = tx.isCredit;
    final unlockAt = tx.createdAt.toLocal().add(Duration(hours: holdHours));
    final waiting = credit && holdHours > 0 && unlockAt.isAfter(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (credit ? _green : _red).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18,
              color: credit ? _green : _red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ptstyle(size: 13.5, weight: 600, color: ch.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    DateFormat("d MMM, HH:mm").format(tx.createdAt.toLocal()),
                    if (tx.kindLabel != null) tx.kindLabel!,
                  ].join(" · "),
                  style: ptstyle(size: 11.5, weight: 400, color: ch.onSurfaceVariant),
                ),
                if (waiting)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock_rounded, size: 12, color: _orange),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "Withdrawable ${releaseLabel(unlockAt)}",
                            style: ptstyle(size: 11, weight: 600, color: _orange),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${credit ? "+" : "−"}${cedi(tx.amount)}",
            style: ptstyle(
              size: 14,
              weight: 800,
              color: credit ? _green : ch.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalList extends StatelessWidget {
  const _WithdrawalList({required this.onWithdraw});
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final list = p.withdrawals;
    if (list.isEmpty) {
      return _Empty(
        icon: Icons.outbox_rounded,
        title: p.loadingWithdrawals ? "Loading…" : "No withdrawals yet",
        text: "When you withdraw to Mobile Money, you can follow it here.",
      );
    }
    return Column(
      children: [
        _Group(
          children: [
            for (final w in list)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    _StatusIcon(w: w),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cedi(w.amount),
                            style: ptstyle(size: 15, weight: 800, color: ch.onSurface),
                          ),
                          Text(
                            [
                              "${w.network} ${w.phone}".trim(),
                              if (w.createdAt != null)
                                DateFormat("d MMM, HH:mm").format(w.createdAt!),
                            ].join(" · "),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ptstyle(size: 11.5, weight: 400, color: ch.onSurfaceVariant),
                          ),
                          Text(
                            "Ref ${w.reference}",
                            style: ptstyle(
                              size: 10.5,
                              weight: 400,
                              color: ch.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusPill(w: w),
                        if (w.isFailed)
                          TextButton(
                            onPressed: onWithdraw,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: _violet,
                            ),
                            child: Text(
                              "Try again",
                              style: ptstyle(size: 12, weight: 700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (p.withdrawalsHasMore)
          TextButton(
            onPressed:
                p.loadingWithdrawals ? null : () => p.getWithdrawals(refresh: false),
            child: Text(
              "Load more",
              style: ptstyle(size: 13, weight: 600, color: _violet),
            ),
          ),
      ],
    );
  }
}

class _StatusIcon extends StatefulWidget {
  const _StatusIcon({required this.w});
  final Withdrawal w;

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.w.isPending) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _StatusIcon old) {
    super.didUpdateWidget(old);
    widget.w.isPending ? _spin.repeat() : _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    final color = w.isPaid ? _green : w.isFailed ? _red : _orange;
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (w.isPending)
            RotationTransition(
              turns: _spin,
              child: CircularProgressIndicator(
                value: 0.25,
                strokeWidth: 2.4,
                color: color,
              ),
            ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              w.isPaid
                  ? Icons.check_rounded
                  : w.isFailed
                  ? Icons.close_rounded
                  : Icons.send_rounded,
              size: 17,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.w});
  final Withdrawal w;

  @override
  Widget build(BuildContext context) {
    final (text, color) =
        w.isPaid
            ? ("Paid", _green)
            : w.isFailed
            ? ("Failed", _red)
            : ("On its way", _orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text, style: ptstyle(size: 11, weight: 700, color: color)),
    );
  }
}

class _EarningsTab extends StatelessWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final e = p.partnerEarnings;
    final w = p.partnerWallet;
    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ptstyle(size: 13.5, weight: 500, color: ch.onSurface),
            ),
          ),
          Text(
            value,
            style: ptstyle(size: 13.5, weight: 700, color: color ?? ch.onSurface),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (e != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _violet.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: _violet),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.ratesSentence,
                    style: ptstyle(size: 12.5, weight: 500, color: ch.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Group(
            children: [
              row("Down payment commission", cedi(e.earnedDownPayment), color: _green),
              row("Repayment commission", cedi(e.earnedRepayment), color: _green),
              row("Customers referred", "${e.referredCustomers}"),
              if (w != null) row("Total earned", cedi(w.totalCredits)),
              if (w != null) row("Total withdrawn", cedi(w.totalDebits)),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                "Points",
                style: ptstyle(size: 18, weight: 800, color: ch.onSurface),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFCC9A44).withOpacity(0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                "${e?.points ?? 0} pts",
                style: ptstyle(size: 12.5, weight: 800, color: const Color(0xFFCC9A44)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Points are a score for now; they can't be spent or withdrawn.",
          style: ptstyle(size: 11.5, weight: 400, color: ch.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        if (p.pointsHistory.isEmpty)
          _Empty(
            icon: Icons.stars_rounded,
            title: p.loadingPoints ? "Loading…" : "No points yet",
            text: "Share your promo code to earn some.",
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: ch.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [for (final pt in p.pointsHistory) AgentPointsRow(entry: pt)],
            ),
          ),
        if (p.pointsHasMore)
          Center(
            child: TextButton(
              onPressed:
                  p.loadingPoints ? null : () => p.getPartnerPoints(refresh: false),
              child: Text(
                "Load more",
                style: ptstyle(size: 13, weight: 600, color: _violet),
              ),
            ),
          ),
      ],
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
              Divider(height: 1, indent: 66, color: ch.onSurface.withOpacity(0.06)),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: ch.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: _violet.withOpacity(0.6)),
          const SizedBox(height: 10),
          Text(title, style: ptstyle(size: 15, weight: 700, color: ch.onSurface)),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: ptstyle(size: 12.5, weight: 400, color: ch.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
