import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Step 3 of 3: POST /partner/registration. Validation mirrors the backend
/// rules exactly (name letters only, phone 0[2-9]xxxxxxxx, strict password).
class AgentRegister extends StatefulWidget {
  const AgentRegister({super.key});

  @override
  State<AgentRegister> createState() => _AgentRegisterState();
}

class _AgentRegisterState extends State<AgentRegister> {
  bool showPass = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SharedProvider>(context, listen: false)
          .prefillAgentFieldsFromUser();
    });
  }

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
                  "Your details",
                  style: ptstyle(size: 24, weight: 700, color: ch.onSurface),
                ),
                SizedBox(height: 6),
                Text(
                  "Step 3 of 3 · ${p.agentEmailController.text.trim()} is verified.",
                  style: ptstyle(
                    size: 12,
                    weight: 300,
                    color: ch.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 26),
                Form(
                  key: p.agentRegisterFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlineInput(
                        controller: p.agentNameController,
                        enabled: !p.agentLoading,
                        label: "Full name",
                        hintText: "eg: Kwame Adjei",
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || !value.isValidPartnerName) {
                            return "Letters and spaces only (min 2 characters)";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Phone",
                        style: ptstyle(
                          size: 11,
                          weight: 400,
                          color: ch.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 50,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: ch.onSurfaceVariant.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "🇬🇭 +233",
                              style: ptstyle(
                                size: 13,
                                weight: 400,
                                color: ch.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: OutlineInput(
                              controller: p.agentPhoneController,
                              enabled: !p.agentLoading,
                              label: "",
                              hintText: "24 555 0181",
                              maxLength: 9,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null ||
                                    !value.isValidPartnerLocalPhone) {
                                  return "9 digits, excluding the first 0";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: p.agentRegionController,
                        enabled: !p.agentLoading,
                        label: "Region",
                        hintText: "eg: Greater Accra",
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your region";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: p.agentAddressController,
                        enabled: !p.agentLoading,
                        label: "Address (optional)",
                        hintText: "eg: Adenta, Accra",
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: p.agentPasswordController,
                        enabled: !p.agentLoading,
                        label: "Password",
                        hintText: "Create a password",
                        keyboardType: TextInputType.text,
                        obscureText: !showPass,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => showPass = !showPass),
                          icon: Icon(
                            showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || !value.isValidPartnerPassword) {
                            return "Use 8+ characters with upper & lower case, a number and a symbol (e.g. @ # _)";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: p.agentConfirmPasswordController,
                        enabled: !p.agentLoading,
                        label: "Confirm password",
                        hintText: "Repeat your password",
                        keyboardType: TextInputType.text,
                        obscureText: !showPass,
                        validator: (value) {
                          if (value != p.agentPasswordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: SmartButton(
                          enabled: !p.agentLoading,
                          loading: p.agentLoading,
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            p.agentCompleteRegistration(context);
                          },
                          child: Text(
                            "Create agent account",
                            style: ptstyle(size: 13, weight: 700),
                          ),
                        ),
                      ),
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