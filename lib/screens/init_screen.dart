// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;

import 'package:flexiphones/screens/profile/add_phone.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_home_shell.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/shared_widgets/neu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InitScreen extends StatefulWidget {
  /// [openAgent]: after loading, open the agent dashboard (an agent-only
  /// account just signed in).
  const InitScreen({super.key, this.openAgent = false});

  final bool openAgent;

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  // The loading ring keeps circling until home opens.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((x) async {
      await checkUser();
    });

    super.initState();
  }

  /// Sends the user to Home no matter what happened above — offline,
  /// a slow/erroring endpoint, or a genuinely successful load all end
  /// the same way: the splash never gets left stuck.
  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final nav = Navigator.of(context);
    final isAgent =
        Provider.of<SharedProvider>(context, listen: false).isAgentAccount;
    final p = Provider.of<SharedProvider>(context, listen: false);
    p.sessionStartup = false;
    NavigationHelper.pushAndRemoveUntil(context, HomePage());
    if (widget.openAgent && isAgent) {
      nav.push(MaterialPageRoute(builder: (_) => const AgentHomeShell()));
    }
    // A session that ended while loading (24h token expired): sign in again.
    p.showPendingSignIn();
    // Just signed up with Google/Apple: ask for the phone number now that
    // the app is ready (Save or Skip, never blocking).
    final prompt = p.pendingPhonePrompt;
    if (prompt != null) {
      p.pendingPhonePrompt = null;
      nav.push(
        MaterialPageRoute(
          builder:
              (_) => AddPhoneScreen(agent: prompt.agent, advice: prompt.advice),
        ),
      );
    }
  }

  Future<void> checkUser() async {
    final sharedProvider = Provider.of<SharedProvider>(context, listen: false);
    sharedProvider.sessionStartup = true;

    try {
      final hasConnection = await sharedProvider
          .hasInternetConnection(true, context)
          .timeout(const Duration(seconds: 12), onTimeout: () => false);

      // No internet: NoInternetPage is already showing (pushed inside
      // hasInternetConnection). Stop here — don't fire off a chain of
      // network calls that have nothing to talk to.
      if (!hasConnection) return;

      if (!mounted) return;

      await sharedProvider.getUserDetails();
      // Restores the separate partner (agent) session from secure storage,
      // or clears it if it's missing/expired (partner tokens last 24h).
      await sharedProvider.loadPartnerSession();
      // Renew a token with under 2 hours left (or end an expired one)
      // before anything is requested with it.
      await sharedProvider.ensureFreshSessions().timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
      await sharedProvider.hasSeenAdThisWeek();
      await sharedProvider.initTHM(context);

      if (!mounted) return;

      if (sharedProvider.userData == null) {
        await _loadGuestData(sharedProvider);
      } else {
        await _loadUserData(sharedProvider);
      }
    } catch (_) {
      // Whatever failed (timeout, bad response, unfinished endpoint on
      // the backend, etc.) — don't leave the splash frozen. Home still
      // works fine with whatever data did load; individual screens
      // handle their own empty/error states.
    } finally {
      _goHome();
    }
  }

  Future<void> _loadGuestData(SharedProvider sharedProvider) async {
    await Future.wait([
      sharedProvider.getProducts(context, refresh: true, next: false),
      sharedProvider.getHotDeals(),
      sharedProvider.getTopDeals(refresh: true, next: false),
      sharedProvider.getBrands(),
    ]).timeout(const Duration(seconds: 12), onTimeout: () => []);
  }

  Future<void> _loadUserData(SharedProvider sharedProvider) async {
    await Future.wait([
      sharedProvider.getProducts(context, refresh: true, next: false),
      sharedProvider.getHotDeals(),
      sharedProvider.getTopDeals(refresh: true, next: false),
      sharedProvider.getVendors(refresh: true, next: false),
      sharedProvider.getOrders(refresh: true, next: false),
      sharedProvider.getRepaymentCL(refresh: true, next: false),
      sharedProvider.getRecentViewed(),
      sharedProvider.loadCartItems(),
      sharedProvider.getNotifications(),
      sharedProvider.getBrands(),
      sharedProvider.getFavorites(),
    ]).timeout(const Duration(seconds: 12), onTimeout: () => []);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Logo springs in, then breathes; phones rise from the bottom.
    final pop = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.35, curve: Curves.easeOut),
    );
    final phones = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Phones photo rising softly from the bottom, fading into white.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.42,
            child: AnimatedBuilder(
              animation: phones,
              builder:
                  (_, child) => Opacity(
                    opacity: phones.value,
                    child: Transform.translate(
                      offset: Offset(0, 60 * (1 - phones.value)),
                      child: child,
                    ),
                  ),
              child: ShaderMask(
                shaderCallback:
                    (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.35],
                      colors: [Colors.transparent, Colors.white],
                    ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  AssetsHelper.phonesIMG,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // The logo, a little above centre.
          Align(
            alignment: const Alignment(0, -0.28),
            child: AnimatedBuilder(
              animation: Listenable.merge([pop, fade, _spin]),
              builder: (_, _) {
                // Gentle breathing once it has landed.
                final breathe =
                    _intro.isCompleted
                        ? 1 + 0.025 * math.sin(_spin.value * 2 * math.pi)
                        : 1.0;
                return Opacity(
                  opacity: fade.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: (0.6 + 0.4 * pop.value) * breathe,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AssetsHelper.logoImage,
                          width: 190,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 26),
                        // Slim loading line.
                        SizedBox(
                          width: 110,
                          height: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(
                              children: [
                                Container(color: const Color(0xFFE8EEF7)),
                                Positioned(
                                  left: -50 + 160 * _spin.value,
                                  top: 0,
                                  bottom: 0,
                                  width: 50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: LinearGradient(
                                        colors: [
                                          Neu.blue.withOpacity(0),
                                          Neu.blue,
                                          Neu.blue.withOpacity(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


