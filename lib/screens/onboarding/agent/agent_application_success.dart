import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Registration on the backend is instant (no approval step): the account is
/// Active and already signed in, so this is a welcome screen, not a
/// "we'll review your application" screen.
class AgentApplicationSuccess extends StatelessWidget {
  const AgentApplicationSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final code = p.agentPromoCode;

    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(automaticallyImplyLeading: false, toolbarHeight: 20),
      body: Stack(
        children: [
          Bgw(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ch.primaryFixed.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 60,
                    color: ch.primary,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "You're an agent!",
                  textAlign: TextAlign.center,
                  style: ptstyle(size: 20, weight: 600, color: ch.onSurface),
                ),
                SizedBox(height: 10),
                Text(
                  "Your agent account is ready. Onboard vendors and share your promo code to start earning.",
                  textAlign: TextAlign.center,
                  style: ptstyle(
                    size: 12,
                    weight: 300,
                    color: ch.onSurfaceVariant,
                  ),
                ),
                if (code != null && code.isNotEmpty) ...[
                  SizedBox(height: 24),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Promo code copied")),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: ch.primaryFixed.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "YOUR PROMO CODE",
                            style: ptstyle(
                              size: 10,
                              weight: 700,
                              color: ch.onSurfaceVariant,
                            ).copyWith(letterSpacing: 1.5),
                          ),
                          SizedBox(height: 6),
                          Text(
                            code,
                            style: ptstyle(
                              size: 24,
                              weight: 800,
                              color: ch.primary,
                            ).copyWith(letterSpacing: 2),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Tap to copy",
                            style: ptstyle(
                              size: 10,
                              weight: 300,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 40),
                SizedBox(
                  height: 47,
                  width: double.infinity,
                  child: SmartButton(
                    enabled: true,
                    loading: false,
                    onPressed: () => p.openAgentShell(context),
                    child: Text(
                      "Open agent dashboard",
                      style: ptstyle(size: 12, weight: 400),
                    ),
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