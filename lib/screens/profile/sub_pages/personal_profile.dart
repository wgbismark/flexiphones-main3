import 'package:flexiphones/extensions/value_validation.dart';
import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/screens/onboarding/forgot_password.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class PersonalProfile extends StatefulWidget {
  const PersonalProfile({super.key});

  @override
  State<PersonalProfile> createState() => _PersonalProfileState();
}

class _PersonalProfileState extends State<PersonalProfile> {
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ch.primaryFixed.withOpacity(0.5),
                ch.primaryFixed.withOpacity(0.2),
                ch.primaryFixed.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Text(
          "Profile",
          style: ptstyle(size: 14, weight: 400, color: ch.onSurfaceVariant),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 10),
        children: [
          SizedBox(height: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Full Name",
                style: ptstyle(
                  size: 12,
                  weight: 700,
                  color: ch.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              Text(
                sharedProvider.userData!.data.name,
                style: ptstyle(
                  size: 14,
                  weight: 600,
                  color: ch.onSurfaceVariant,
                ),
              ),
            ],
          ),

          SDivider(),
          Text(
            "Email",
            style: ptstyle(
              size: 12,
              weight: 700,
              color: ch.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
          Text(
            sharedProvider.userData!.data.email,

            style: ptstyle(size: 14, weight: 600, color: ch.onSurfaceVariant),
          ),

          SDivider(),
          Text(
            "Phone Number",
            style: ptstyle(
              size: 12,
              weight: 700,
              color: ch.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
          Text(
            _formatPhone(sharedProvider.userData!.data.phone),
            style: ptstyle(size: 14, weight: 600, color: ch.onSurfaceVariant),
          ),

          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10),
                      ),
                    ),
                  ),

                  onPressed:
                      () => {
                        sharedProvider.fullNameController.text =
                            sharedProvider.userData!.data.name,
                        showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => UNDi(),
                        ),
                      },
                  child: Text("Update Name", style: ptstyle(size: 12, weight: 400, color: ch.onPrimaryContainer)),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonal(
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10),
                      ),
                    ),
                  ),

                  onPressed:
                      () => {
                        sharedProvider.phoneController.clear(),
                        showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => UPDi(),
                        ),
                      },
                  child: Text("Update Phone", style: ptstyle(size: 12, weight: 400, color: ch.onPrimaryContainer)),
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(10),
                ),
              ),

              onPressed:
                  () => NavigationHelper.push(context, ForgotPassword()),
              child: Text("Update Password", style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant)),
            ),
          ),
        ],
      ),
    );
  }
}

class UNDi extends StatefulWidget {
  const UNDi({super.key});

  @override
  State<UNDi> createState() => _UNDiState();
}

class _UNDiState extends State<UNDi> {
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return AbsorbPointer(
      absorbing: sharedProvider.dialogueLoading,
      child: AlertDialog(
        backgroundColor: ch.surface,
        titlePadding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
        contentPadding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 0,
          bottom: 15,
        ),
        title: Text(
          "Update Your Name",
          style: ptstyle(size: 18, weight: 500, color: ch.onSurfaceVariant),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlineInput(
              label: "",
              controller: sharedProvider.fullNameController,
              maxLength: 80,
              onchange: (value) {
                setState(() {});
              },
            ),
            SizedBox(height: 10),
            Text(
              "At least 6 characters, must contain letters only",
              style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          Opacity(
            opacity: sharedProvider.dialogueLoading ? 0.3 : 1,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(elevation: 0),
              child: Text("Cancel"),
            ),
          ),
          SizedBox(width: 5),
          sharedProvider.dialogueLoading
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(),
              )
              : Opacity(
                opacity:
                    sharedProvider.fullNameController.text.length < 5 ||
                            !sharedProvider
                                .fullNameController
                                .text
                                .containsLetters ||
                            sharedProvider.fullNameController.text ==
                                sharedProvider.userData!.data.name
                        ? 0.4
                        : 1,
                child: AbsorbPointer(
                  absorbing:
                      sharedProvider.fullNameController.text.length < 5 ||
                      !sharedProvider.fullNameController.text.containsLetters ||
                      sharedProvider.fullNameController.text ==
                          sharedProvider.userData!.data.name,
                  child: TextButton(
                    onPressed:
                        () => {
                          FocusScope.of(context).unfocus(),
                          sharedProvider.updateName(context),
                        },
                    child: Text("Confirm Update"),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class UPDi extends StatefulWidget {
  const UPDi({super.key});

  @override
  State<UPDi> createState() => _UPDiState();
}

class _UPDiState extends State<UPDi> {
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return AbsorbPointer(
      absorbing: sharedProvider.dialogueLoading,
      child: AlertDialog(
        backgroundColor: ch.surface,
        titlePadding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
        contentPadding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 0,
          bottom: 15,
        ),
        title: Text(
          "Update Your Phone Number",
          style: ptstyle(size: 18, weight: 500, color: ch.onSurfaceVariant),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlineInput(
              label: "",
              controller: sharedProvider.phoneController,
              maxLength: 9,
              onchange: (value) {
                setState(() {});
              },
            ),
            SizedBox(height: 10),
            Text(
              "Enter your new number excluding the first zero, e.g. 24 123 4567",
              style: ptstyle(size: 12, weight: 400, color: ch.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          Opacity(
            opacity: sharedProvider.dialogueLoading ? 0.3 : 1,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(elevation: 0),
              child: Text("Cancel"),
            ),
          ),
          SizedBox(width: 5),
          sharedProvider.dialogueLoading
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(),
              )
              : Opacity(
                opacity:
                    !sharedProvider.phoneController.text.isValidPhoneNumber
                        ? 0.4
                        : 1,
                child: AbsorbPointer(
                  absorbing:
                      !sharedProvider.phoneController.text.isValidPhoneNumber,
                  child: TextButton(
                    onPressed:
                        () => {
                          FocusScope.of(context).unfocus(),
                          sharedProvider.updatePhone(context),
                        },
                    child: Text("Confirm Update"),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}