import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Where a customer enters an agent's promo code
/// (POST /customer/apply-promo-code). One code per customer, and nobody can
/// use their own code — the server's message is shown for both.
class PromoCodePage extends StatefulWidget {
  const PromoCodePage({super.key});

  @override
  State<PromoCodePage> createState() => _PromoCodePageState();
}

class _PromoCodePageState extends State<PromoCodePage> {
  final _code = TextEditingController();
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    // GET /customer/my-referral: hide the code box once a code was used.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<SharedProvider>(context, listen: false).getMyReferral();
      if (mounted) setState(() => _checking = false);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    FocusScope.of(context).unfocus();
    final p = Provider.of<SharedProvider>(context, listen: false);
    await p.applyPromoCode(context, _code.text);
    // On success (or 409 "already used") the page switches to the
    // "Referred by" view on its own.
  }

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);

    return Scaffold(
      backgroundColor: ch.surface,
      appBar: AppBar(
        backgroundColor: ch.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Promo Code",
          style: ptstyle(size: 14, weight: 400, color: ch.onSurfaceVariant),
        ),
      ),
      body:
          _checking && p.hasReferrer == null
              ? const Center(child: CircularProgressIndicator())
              : p.hasReferrer == true
              ? _referredBy(ch, p)
              : _form(ch, p),
    );
  }

  Widget _referredBy(ColorScheme ch, SharedProvider p) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Icon(Icons.handshake_outlined, size: 48, color: ch.primary),
      const SizedBox(height: 14),
      Text(
        p.myReferrerName == null || p.myReferrerName!.isEmpty
            ? "You've used a promo code"
            : "Referred by ${p.myReferrerName}",
        textAlign: TextAlign.center,
        style: ptstyle(size: 17, weight: 700, color: ch.onSurface),
      ),
      if (p.myReferrerCode != null && p.myReferrerCode!.isNotEmpty) ...[
        const SizedBox(height: 6),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ch.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.myReferrerCode!,
              style: ptstyle(size: 12, weight: 700, color: ch.primary),
            ),
          ),
        ),
      ],
      const SizedBox(height: 10),
      Text(
        "Each customer can use one promo code, and yours is already applied.",
        textAlign: TextAlign.center,
        style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
      ),
    ],
  );

  Widget _form(ColorScheme ch, SharedProvider p) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.redeem_rounded, size: 48, color: ch.primary),
          const SizedBox(height: 14),
          Text(
            "Were you referred by an agent?",
            textAlign: TextAlign.center,
            style: ptstyle(size: 17, weight: 700, color: ch.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter their promo code. You can only use one code, and you can't use your own.",
            textAlign: TextAlign.center,
            style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          OutlineInput(
            controller: _code,
            enabled: !p.applyingPromo,
            label: "Promo code",
            hintText: "eg: ABC-1234",
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: SmartButton(
              enabled: !p.applyingPromo,
              loading: p.applyingPromo,
              onPressed: _apply,
              child: Text("Apply", style: ptstyle(size: 13, weight: 600)),
            ),
          ),
        ],
      );
}
