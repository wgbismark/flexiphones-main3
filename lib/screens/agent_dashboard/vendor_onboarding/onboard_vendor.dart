import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _agentGreen = Color(0xFF12362C);
const _agentGold = Color(0xFFCC9A44);

/// POST /partner/onboard-vendor. The backend requires:
/// shop_name, owner_name, owner_email (unique among users), phone,
/// address, and optionally estimated_monthly_devices. There is no photo
/// upload on the backend, so the shopfront photo field was removed.
class OnboardVendor extends StatelessWidget {
  const OnboardVendor({super.key});

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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: ch.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Onboard a vendor",
                            style: ptstyle(
                              size: 15,
                              weight: 700,
                              color: ch.onSurface,
                            ),
                          ),
                          Text(
                            "Tag them to your account",
                            style: ptstyle(
                              size: 11,
                              weight: 300,
                              color: ch.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 26),
                Text(
                  "SHOP DETAILS",
                  style: ptstyle(
                    size: 11,
                    weight: 700,
                    color: ch.onSurfaceVariant,
                  ).copyWith(letterSpacing: 1.5),
                ),
                SizedBox(height: 14),
                Form(
                  key: p.vendorFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlineInput(
                        controller: p.vendorShopNameController,
                        enabled: !p.vendorSubmitting,
                        label: "Shop / business name",
                        hintText: "e.g. Kumasi Phones Ltd",
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter the shop name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: p.vendorOwnerNameController,
                        enabled: !p.vendorSubmitting,
                        label: "Owner's full name",
                        hintText: "Full name",
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter the owner's name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: p.vendorOwnerEmailController,
                        enabled: !p.vendorSubmitting,
                        label: "Owner's email",
                        hintText: "owner@example.com",
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.trim().isValidEmail) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Owner's phone",
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
                              "+233",
                              style: ptstyle(
                                size: 12,
                                weight: 400,
                                color: ch.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: OutlineInput(
                              controller: p.vendorPhoneController,
                              enabled: !p.vendorSubmitting,
                              label: "",
                              hintText: "24 000 0000",
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
                        controller: p.vendorAddressController,
                        enabled: !p.vendorSubmitting,
                        label: "Business address",
                        hintText: "Adum, Kumasi",
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter the business address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlineInput(
                        controller: p.vendorEstimatedDevicesController,
                        enabled: !p.vendorSubmitting,
                        label: "Estimated monthly devices (optional)",
                        hintText: "~ 40",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _agentGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 16,
                              color: _agentGold,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "The shop is submitted for review and a setup email is sent to the owner so they can set their password.",
                                style: ptstyle(
                                  size: 11,
                                  weight: 300,
                                  color: ch.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
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
                          onPressed: p.vendorSubmitting
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  p.submitVendorOnboarding(context);
                                },
                          child: p.vendorSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Submit for review",
                                  style: ptstyle(
                                    size: 13,
                                    weight: 700,
                                    color: Colors.white,
                                  ),
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