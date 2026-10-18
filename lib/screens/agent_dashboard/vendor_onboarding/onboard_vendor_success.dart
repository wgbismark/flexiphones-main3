import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _agentGreen = Color(0xFF12362C);
const _agentGold = Color(0xFFCC9A44);

/// After POST /partner/onboard-vendor. When [inviteSent] is false the
/// vendor was saved but the invitation email failed, so this offers
/// "Resend invitation" right away.
class OnboardVendorSuccess extends StatefulWidget {
  const OnboardVendorSuccess({
    super.key,
    this.vendorId,
    this.inviteSent = true,
    this.message = "",
  });

  final int? vendorId;
  final bool inviteSent;
  final String message;

  @override
  State<OnboardVendorSuccess> createState() => _OnboardVendorSuccessState();
}

class _OnboardVendorSuccessState extends State<OnboardVendorSuccess> {
  late bool _sent = widget.inviteSent;

  Future<void> _resend() async {
    final id = widget.vendorId;
    if (id == null) return;
    final ok = await Provider.of<SharedProvider>(
      context,
      listen: false,
    ).resendVendorInvite(context, id);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final resending =
        widget.vendorId != null && p.resendingInvites.contains(widget.vendorId);

    return Scaffold(
      backgroundColor: ch.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _sent ? _agentGold : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _sent ? Icons.check_rounded : Icons.mark_email_unread_outlined,
                  size: 46,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                _sent ? "Submitted!" : "Vendor saved",
                textAlign: TextAlign.center,
                style: ptstyle(size: 24, weight: 700, color: ch.onSurface),
              ),
              SizedBox(height: 10),
              Text(
                _sent
                    ? "An invitation email was sent to the owner. They set a password, complete the shop profile, then FlexiPhones verifies them. You can follow its status under Vendors."
                    : (widget.message.isNotEmpty
                        ? widget.message
                        : "The vendor was saved, but the invitation email couldn't be sent. Send it again below."),
                textAlign: TextAlign.center,
                style: ptstyle(
                  size: 13,
                  weight: 300,
                  color: ch.onSurfaceVariant,
                ).copyWith(height: 1.4),
              ),
              SizedBox(height: 40),
              if (!_sent && widget.vendorId != null) ...[
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: resending ? null : _resend,
                    icon:
                        resending
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      "Resend invitation",
                      style: ptstyle(size: 13, weight: 700),
                    ),
                  ),
                ),
                SizedBox(height: 12),
              ],
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _agentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => NavigationHelper.pop(context),
                  child: Text(
                    "Back to dashboard",
                    style: ptstyle(size: 13, weight: 700, color: Colors.white),
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
