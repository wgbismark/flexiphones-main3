import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

/// Step 2 of 3: 5 digit code -> POST /partner/email-otp-verification.
class AgentOtpScreen extends StatelessWidget {
  const AgentOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);

    return Scaffold(
      backgroundColor: ch.surface,
      body: Stack(
        children: [
          Bgw(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: ch.onSurfaceVariant),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                SizedBox(height: 10),
                Text(
                  "Enter the code",
                  style: ptstyle(size: 24, weight: 700, color: ch.onSurface),
                ),
                SizedBox(height: 6),
                Text(
                  "Step 2 of 3 · We sent a 5 digit code to ${p.agentEmailController.text.trim()}. It expires in 10 minutes.",
                  style: ptstyle(
                    size: 12,
                    weight: 300,
                    color: ch.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 30),
                Center(
                  child: Pinput(
                    length: 5,
                    controller: p.agentOtpController,
                    enabled: !p.agentLoading,
                    keyboardType: TextInputType.number,
                    onCompleted: (_) => p.agentVerifyOtp(context),
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  height: 48,
                  child: SmartButton(
                    enabled: !p.agentLoading,
                    loading: p.agentLoading,
                    onPressed: () => p.agentVerifyOtp(context),
                    child: Text("Verify", style: ptstyle(size: 13, weight: 600)),
                  ),
                ),
                SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: p.agentLoading
                        ? null
                        : () => p.agentSendEmailOtp(context, resend: true),
                    child: Text(
                      "Resend code",
                      style: ptstyle(size: 12, weight: 600, color: ch.primary),
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