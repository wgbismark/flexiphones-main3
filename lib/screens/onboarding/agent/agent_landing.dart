import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signin.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signup.dart';
import 'package:flexiphones/screens/onboarding/agent/become_agent.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgentLanding extends StatelessWidget {
  const AgentLanding({super.key});

  /// Signed-in agent: open the dashboard. Signed-in customer: become an
  /// agent with the customer account (no new email code). Otherwise the
  /// full agent sign-up.
  void _becomeAgent(BuildContext context) {
    final p = Provider.of<SharedProvider>(context, listen: false);
    if (p.isAgentAccount) {
      p.openAgentShell(context);
    } else if (p.userData != null) {
      NavigationHelper.push(context, const BecomeAgent());
    } else {
      NavigationHelper.push(context, const AgentSignup());
    }
  }

  @override
  Widget build(BuildContext context) {
    final benefits = const [
      {
        "icon": Icons.storefront_outlined,
        "title": "Onboard vendors",
        "subtitle": "Sign up shops and tag them to your account",
      },
      {
        "icon": Icons.qr_code_2_rounded,
        "title": "Your personal promo code",
        "subtitle": "Customers you refer are tied to you",
      },
      {
        "icon": Icons.account_balance_wallet_outlined,
        "title": "Earnings wallet",
        "subtitle": "Track credits and payouts to your MoMo",
      },
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF120A06), Color(0xFF3B2011), Color(0xFF1A0F08)],
          ),
        ),
        // Scrolls on short screens (e.g. the M91, where the buttons were
        // pushed off the bottom) while the Spacer still pins the buttons
        // to the bottom on tall ones.
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                IconButton(
                  onPressed: () => NavigationHelper.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                SizedBox(height: 26),
                Text(
                  "AGENT PROGRAMME",
                  style: ptstyle(
                    size: 11,
                    weight: 700,
                    color: Colors.orangeAccent.withOpacity(0.9),
                  ).copyWith(letterSpacing: 3),
                ),
                SizedBox(height: 16),
                Text(
                  "Earn from every phone you help move.",
                  style: ptstyle(
                    size: 30,
                    weight: 700,
                    color: Colors.white,
                  ).copyWith(height: 1.2),
                ),
                SizedBox(height: 14),
                Text(
                  "Sign up vendors. Refer customers. Get paid into your agent wallet.",
                  style: ptstyle(
                    size: 13,
                    weight: 300,
                    color: Colors.white.withOpacity(0.7),
                  ).copyWith(height: 1.4),
                ),
                SizedBox(height: 30),
                ...benefits.map(
                  (b) => Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            b["icon"] as IconData,
                            color: Colors.orangeAccent,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b["title"] as String,
                                style: ptstyle(
                                  size: 13,
                                  weight: 600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                b["subtitle"] as String,
                                style: ptstyle(
                                  size: 11,
                                  weight: 300,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _becomeAgent(context),
                    child: Text(
                      Provider.of<SharedProvider>(context).isAgentAccount
                          ? "Open agent dashboard"
                          : "Become an agent",
                      style: ptstyle(
                        size: 14,
                        weight: 700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        NavigationHelper.push(context, const AgentSignin()),
                    child: RichText(
                      text: TextSpan(
                        text: "Already an agent? ",
                        style: ptstyle(
                          size: 12,
                          weight: 300,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        children: [
                          TextSpan(
                            text: "Sign in",
                            style: ptstyle(
                              size: 12,
                              weight: 700,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}