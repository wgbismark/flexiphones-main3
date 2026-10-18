import 'package:animation_list/animation_list.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/screens/agent_dashboard/agent_home_shell.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_landing.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signin.dart';
import 'package:flexiphones/screens/layout/layout.dart';
import 'package:flexiphones/screens/onboarding/email_phone/email_signin.dart';
import 'package:flexiphones/screens/onboarding/ghcard_verification.dart';
import 'package:flexiphones/screens/profile/sub_pages/help_and_support.dart';
import 'package:flexiphones/screens/profile/sub_pages/favorites.dart';
import 'package:flexiphones/screens/reviews/reviews.dart' show MyReviewsScreen;
import 'package:flexiphones/screens/profile/sub_pages/promo_code.dart';
import 'package:flexiphones/screens/profile/sub_pages/refer_friends.dart';
import 'package:flexiphones/screens/profile/sub_pages/repayment_calendar.dart';
import 'package:flexiphones/screens/profile/delete_account.dart';
import 'package:flexiphones/screens/profile/edit_profile.dart';
import 'package:flexiphones/screens/profile/add_phone.dart';
import 'package:flexiphones/screens/reports/reports.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/confirmation_dialogue.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/sum_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, this.ghcv = false});
  final bool ghcv;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<Map<int, Object>> pages = <Map<int, Object>>[
    {
      0: Icons.person_outline_outlined,
      1: "Edit profile",
      2: EditProfileScreen(agent: false),
      3: false,
    },
    {
      0: Icons.badge_outlined,
      1: "Ghana Card",
      2: GHCardVerification(lateVerification: true),
      3: true,
    },
    {
      0: Icons.calendar_month_outlined,
      1: "Repayment Calender",
      2: RepaymentCalendar(),
      3: false,
    },
    {
      0: Icons.reviews_outlined,
      1: "My Reviews",
      2: MyReviewsScreen(),
      3: false,
    },
    {
      0: Icons.favorite_border_rounded,
      1: "Favourites",
      2: FavoritesPage(),
      3: false,
    },
    {
      0: Icons.card_giftcard_rounded,
      1: "Refer a Friend & Points",
      2: ReferFriendsPage(),
      3: false,
    },
    {
      0: Icons.redeem_rounded,
      1: "Agent Promo Code",
      2: PromoCodePage(),
      3: false,
    },
    {
      0: Icons.support_sharp,
      1: "Help & Support",
      2: HelpAndSupport(),
      3: false,
    },
    {
      0: Icons.flag_outlined,
      1: "My reports",
      2: MyReportsScreen(),
      3: false,
    },
  ];

  /// From GET /customer/agent-status: tells us if this customer is already
  /// an agent even when the agent side isn't signed in on this phone.
  AgentStatus? _agentStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = Provider.of<SharedProvider>(context, listen: false);
      if (p.isAgentAccount) return;
      final status = await p.getAgentStatus();
      if (mounted) setState(() => _agentStatus = status);
    });
  }

  /// Agent card: dashboard for a signed-in agent, sign-in for an agent who
  /// isn't signed in on this phone, otherwise "Become an Agent".
  ({String title, String subtitle, IconData icon, VoidCallback onTap})
  _agentCard(SharedProvider p) {
    if (p.isAgentAccount) {
      return (
        title: "Agent Dashboard",
        subtitle: "Your earnings, vendors & promo code",
        icon: Icons.dashboard_outlined,
        onTap: () => NavigationHelper.push(context, const AgentHomeShell()),
      );
    }
    if (_agentStatus?.isAgent == true) {
      return (
        title: "Agent Account",
        subtitle: "You're an agent. Sign in to your agent dashboard",
        icon: Icons.login_rounded,
        onTap: () {
          p.agentSignInEmailController.text = p.userData?.data.email ?? "";
          NavigationHelper.push(context, const AgentSignin());
        },
      );
    }
    return (
      title: "Become an Agent",
      subtitle: "Help customers order phones & earn",
      icon: Icons.storefront_outlined,
      onTap: () => NavigationHelper.push(context, AgentLanding()),
    );
  }

  /// The backend returns phone as a bare number with the country code
  /// concatenated straight on, e.g. "233250000000" — no separator, no
  /// leading "+". This just makes it readable as "+233 25 000 0000"
  /// without touching what's actually stored.
  String _formatPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) return raw;
    var local = digits.substring(digits.length - 9);
    var cc = digits.substring(0, digits.length - 9);
    if (cc.isEmpty) cc = "233";
    return "+$cc ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}";
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    // Signed out (logout or session ended) while this tab is showing.
    if (sharedProvider.userData == null) return const SizedBox.shrink();
    final agentCard = _agentCard(sharedProvider);

    sharedProvider.checkValidGhCard();
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: ch.surface.withOpacity(0.8),
        toolbarHeight: 10,
      ),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Bgw2(),
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 20, left: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          width: 2,
                          color: ch.onSurfaceVariant.withOpacity(0.4),
                        ),
                      ),
                      child: GestureDetector(
                        onTap:
                            () => EditProfileScreen.open(context, agent: false),
                        child: ProfileAvatar(
                          name: sharedProvider.userData!.data.name,
                          url: sharedProvider.userData!.data.profilePhoto,
                          size: 40,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sharedProvider.userData!.data.name,
                            style: ptstyle(
                              size: 14,
                              weight: 600,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            sharedProvider.userData!.data.email,
                            style: ptstyle(
                              size: 10,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 11,
                                color: ch.onSurfaceVariant.withOpacity(0.7),
                              ),
                              SizedBox(width: 4),
                              Text(
                                _formatPhone(
                                  sharedProvider.userData!.data.phone,
                                ),
                                style: ptstyle(
                                  size: 10,
                                  weight: 400,
                                  color: ch.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 30,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          elevation: 0,
                          backgroundColor: Colors.redAccent.withOpacity(0.05),
                        ),
                        onPressed: () async {
                          showConfirmationDialog(
                            context: context,
                            title: "Are you sure?",
                            content:
                                "..you are signing out from your flexiphones account.",
                            confirm: () async {
                              // Cancel the tokens on the server and wipe
                              // everything this account left on the phone,
                              // then start over as a guest (nothing to go
                              // "back" to) with sign-in on top.
                              // Leave this screen FIRST, then clear: clearing
                              // while Profile is showing rebuilds it with no
                              // user (and on a tab guests don't have).
                              final nav = Navigator.of(context);
                              final p = sharedProvider;
                              nav.pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                                (_) => false,
                              );
                              nav.push(
                                MaterialPageRoute(
                                  builder: (_) => const EmailSignin(),
                                ),
                              );
                              await p.signOutCompletely();
                            },
                          );
                        },
                        label: Text(
                          "Log Out",
                          style: ptstyle(
                            size: 12,
                            weight: 600,
                            color: Colors.redAccent,
                          ),
                        ),
                        icon: Icon(
                          Icons.power_settings_new_sharp,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      SumCard(
                        ch: ch,
                        value: sharedProvider.orders.length.toString(),
                        title: "Orders",
                      ),
                      SizedBox(width: 8),
                      SumCard(
                        ch: ch,
                        value:
                            sharedProvider.ordersStatusPlaced.length.toString(),
                        title: "Pending",
                      ),
                      SizedBox(width: 8),
                      SumCard(
                        ch: ch,
                        value: sharedProvider.cartItems.length.toString(),
                        title: "In Cart",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: agentCard.onTap,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ch.primary.withOpacity(0.9),
                            ch.primary.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              agentCard.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agentCard.title,
                                  style: ptstyle(
                                    size: 13,
                                    weight: 700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  agentCard.subtitle,
                                  style: ptstyle(
                                    size: 10,
                                    weight: 300,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Gentle reminder while there is no phone number.
                if (sharedProvider.userData!.data.phone.trim().isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Material(
                      color: const Color(0xFF0071E3).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => AddPhoneScreen.open(context, agent: false),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_iphone_rounded, color: Color(0xFF0071E3), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Add your phone number so we can reach you about orders and payments.",
                                  style: ptstyle(size: 12, weight: 500, color: ch.onSurface),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF0071E3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 10),
                Expanded(
                  child: AnimationList(
                    animationDirection: AnimationDirection.vertical,
                    duration: 300,
                    reBounceDepth: 0,
                    padding: EdgeInsets.all(0),
                    children: [
                      ...List.generate(pages.length, (index) {
                      var page = pages[index];

                      return InkWell(
                        onTap:
                            sharedProvider.userData!.data.ghanaCard != null &&
                                    page[3] == true
                                ? null
                                : () => NavigationHelper.push(
                                  context,
                                  page[2] as Widget,
                                ),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    page[0] as IconData,
                                    size: 20,
                                    color: ch.onSurfaceVariant.withOpacity(0.5),
                                  ),
                                  SizedBox(width: 20),
                                  Text(
                                    page[1] as String,
                                    style: ptstyle(
                                      size: 12,
                                      weight: 400,
                                      color: ch.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (page[3] as bool)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8.0),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            sharedProvider
                                                        .userData!
                                                        .data
                                                        .ghanaCard !=
                                                    null
                                                ? Colors.greenAccent
                                                : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(80),
                                      ),
                                      child: Text(
                                        sharedProvider
                                                    .userData!
                                                    .data
                                                    .ghanaCard !=
                                                null
                                            ? "Linked!"
                                            : "Unlinked",
                                        style: ptstyle(
                                          size: 12,
                                          weight: 600,
                                          color:
                                              sharedProvider
                                                          .userData!
                                                          .data
                                                          .ghanaCard !=
                                                      null
                                                  ? Colors.white
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                  (page[3] as bool)
                                      ? (sharedProvider
                                                  .userData!
                                                  .data
                                                  .ghanaCard !=
                                              null
                                          ? SizedBox()
                                          : Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 15,
                                            color: ch.onSurfaceVariant
                                                .withOpacity(0.5),
                                          ))
                                      : Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: ch.onSurfaceVariant.withOpacity(
                                          0.5,
                                        ),
                                        size: 15,
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                      const LegalRows(showSupport: false),
                      const SizedBox(height: 8),
                      const DeleteAccountLink(agent: false),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}