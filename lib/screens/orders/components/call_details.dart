import 'package:flexiphones/extensions/ui_values.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showVendorBottomSheet(BuildContext context, List vendorDetails) {
  var ch = Theme.of(context).colorScheme;
  void callPhone(tel) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: tel);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SizedBox(
        height: 20.h,
        child: Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 15),
                child: Text(
                  'Vendor(s) Contact(s)',
                  style: ptstyle(size: 16, weight: 400),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  separatorBuilder:
                      (context, index) => Divider(
                        height: 0,
                        color: ch.onSurfaceVariant.withOpacity(0.05),
                      ),
                  itemCount: vendorDetails.length,
                  itemBuilder: (context, index) {
                    final vendor = vendorDetails[index];
                    return ListTile(
                      onTap: () => callPhone(vendor['contact']),
                      title: Text(
                        vendor['name'],
                        style: ptstyle(size: 12, weight: 600),
                      ),
                      subtitle: Text(
                        vendor['contact'],
                        style: ptstyle(size: 12, weight: 400),
                      ),
                      leading: Icon(
                        Icons.phone_outlined,
                        size: 20,
                        color: ch.primary,
                      ),
                      trailing: Icon(
                        Icons.account_circle,
                        size: 30,
                        color: ch.onSurfaceVariant.withOpacity(0.2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
