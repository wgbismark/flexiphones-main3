import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/models/agent_m.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signin.dart';
import 'package:flexiphones/screens/onboarding/agent/agent_signup.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A signed-in customer becomes an agent with the same account:
/// GET /customer/agent-status, then POST /customer/become-agent.
/// No email code and no password check — the customer is already signed
/// in and verified. Only region is required; name and phone default to the
/// customer's. A password is only sent if they want a different one for the
/// agent login. A different email means a separate account (normal sign-up).
class BecomeAgent extends StatefulWidget {
  const BecomeAgent({super.key});

  @override
  State<BecomeAgent> createState() => _BecomeAgentState();
}

class _BecomeAgentState extends State<BecomeAgent> {
  final _formKey = GlobalKey<FormState>();
  final _region = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _company = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _separatePassword = false;
  bool _showPass = false;

  bool _checking = true;
  AgentStatus? _status;

  // Backend: ^(\+233|0|233)[2-9][0-9]{8}$
  static final _ghPhone = RegExp(r'^(\+233|0|233)[2-9][0-9]{8}$');

  @override
  void initState() {
    super.initState();
    final u =
        Provider.of<SharedProvider>(context, listen: false).userData?.data;
    _name.text = u?.name ?? "";
    _phone.text = u?.phone ?? "";
    _address.text = u?.address ?? "";
    _checkStatus();
  }

  @override
  void dispose() {
    for (final c in [
      _region,
      _name,
      _phone,
      _address,
      _company,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final p = Provider.of<SharedProvider>(context, listen: false);
    final status = await p.getAgentStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _checking = false;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Provider.of<SharedProvider>(context, listen: false).becomeAgent(
      context,
      region: _region.text,
      name: _name.text,
      phone: _phone.text.replaceAll(" ", ""),
      address: _address.text,
      company: _company.text,
      password: _separatePassword ? _password.text : null,
      passwordConfirmation: _separatePassword ? _confirm.text : null,
    );
  }

  void _goToAgentSignIn() {
    final p = Provider.of<SharedProvider>(context, listen: false);
    p.agentSignInEmailController.text = p.userData?.data.email ?? "";
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AgentSignin()));
  }

  void _goToSeparateSignup() => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => const AgentSignup()));

  @override
  Widget build(BuildContext context) {
    final ch = Theme.of(context).colorScheme;
    final p = Provider.of<SharedProvider>(context);
    final status = _status;

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
                const SizedBox(height: 10),
                Text(
                  "Become an agent",
                  style: ptstyle(size: 24, weight: 700, color: ch.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  "Free, and you keep your customer account. You'll sign in to the agent side with the same email.",
                  style: ptstyle(
                    size: 12,
                    weight: 300,
                    color: ch.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 26),
                if (_checking)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (status?.isAgent == true)
                  _alreadyAgent(ch)
                else if (status != null && !status.canBecomeAgent)
                  _notAllowed(ch)
                else
                  _form(ch, p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alreadyAgent(ColorScheme ch) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        "You are already an agent.",
        style: ptstyle(size: 15, weight: 600, color: ch.onSurface),
      ),
      const SizedBox(height: 6),
      Text(
        "Sign in to the agent side with the same email as your customer account.",
        style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _goToAgentSignIn,
        child: Text("Agent sign in", style: ptstyle(size: 13, weight: 600)),
      ),
    ],
  );

  Widget _notAllowed(ColorScheme ch) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        "You can't become an agent with this account yet.",
        style: ptstyle(size: 15, weight: 600, color: ch.onSurface),
      ),
      const SizedBox(height: 6),
      Text(
        "Please verify your account first, or sign up as an agent with a different email.",
        style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      OutlinedButton(
        onPressed: _goToSeparateSignup,
        child: Text(
          "Sign up with a different email",
          style: ptstyle(size: 13, weight: 600),
        ),
      ),
    ],
  );

  Widget _form(ColorScheme ch, SharedProvider p) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlineInput(
          controller: _region,
          enabled: !p.agentLoading,
          label: "Region",
          hintText: "eg: Greater Accra",
          validator:
              (v) =>
                  (v == null || v.trim().isEmpty)
                      ? "Please enter your region"
                      : null,
        ),
        const SizedBox(height: 16),
        OutlineInput(
          controller: _name,
          enabled: !p.agentLoading,
          label: "Agent name",
          hintText: "eg: Kofi Mensah",
          validator:
              (v) =>
                  (v == null || v.trim().isEmpty || v.isValidPartnerName)
                      ? null
                      : "Letters and spaces only",
        ),
        const SizedBox(height: 16),
        OutlineInput(
          controller: _phone,
          enabled: !p.agentLoading,
          label: "Phone",
          hintText: "eg: 0241234567",
          keyboardType: TextInputType.phone,
          validator: (v) {
            final s = (v ?? "").replaceAll(" ", "");
            if (s.isEmpty || _ghPhone.hasMatch(s)) return null;
            return "Enter a valid Ghana number, eg: 0241234567";
          },
        ),
        const SizedBox(height: 16),
        OutlineInput(
          controller: _address,
          enabled: !p.agentLoading,
          label: "Address (optional)",
          hintText: "eg: Adum, Kumasi",
        ),
        const SizedBox(height: 16),
        OutlineInput(
          controller: _company,
          enabled: !p.agentLoading,
          label: "Company (optional)",
          hintText: "eg: Kofi Phones",
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _separatePassword,
          onChanged:
              p.agentLoading
                  ? null
                  : (v) => setState(() => _separatePassword = v),
          title: Text(
            "Use a different password for the agent login",
            style: ptstyle(size: 12, weight: 500, color: ch.onSurface),
          ),
          subtitle: Text(
            "Leave off to use your customer password.",
            style: ptstyle(size: 11, weight: 300, color: ch.onSurfaceVariant),
          ),
        ),
        if (_separatePassword) ...[
          const SizedBox(height: 8),
          OutlineInput(
            controller: _password,
            enabled: !p.agentLoading,
            label: "Agent password",
            hintText: "At least 8 characters",
            obscureText: !_showPass,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showPass = !_showPass),
              icon: Icon(
                _showPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            validator:
                (v) =>
                    (v != null && v.isValidPartnerPassword)
                        ? null
                        : "Use 8+ characters with upper & lower case, a number and a symbol (e.g. @ # _)",
          ),
          const SizedBox(height: 16),
          OutlineInput(
            controller: _confirm,
            enabled: !p.agentLoading,
            label: "Confirm agent password",
            hintText: "Type it again",
            obscureText: !_showPass,
            validator:
                (v) => v == _password.text ? null : "Passwords do not match",
          ),
        ],
        const SizedBox(height: 26),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: SmartButton(
            enabled: !p.agentLoading,
            loading: p.agentLoading,
            onPressed: _submit,
            child: Text(
              "Become an agent",
              style: ptstyle(size: 13, weight: 600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: p.agentLoading ? null : _goToSeparateSignup,
            child: Text(
              "Want a different email for your agent account?",
              style: ptstyle(size: 11, weight: 500, color: ch.primary),
            ),
          ),
        ),
      ],
    ),
  );
}
