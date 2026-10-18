import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/space_divider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FAQ extends StatefulWidget {
  const FAQ({super.key, required this.nextPage});
  final VoidCallback nextPage;

  @override
  State<FAQ> createState() => _FAQState();
}

class _FAQState extends State<FAQ> {
  final List<Map<String, dynamic>> faqs = [
    {
      'question': 'My payment is not showing, what should I do?',
      'answer':
          'Payments can take up to 24–48 hours to reflect. If it still doesn’t show, please reach out to our support team with your payment details.',
    },

    // {
    //   'question': 'How do repayments happen?',
    //   'answer':
    //       'Your repayments are deducted automatically on your due dates. Just make sure your account is funded before the schedule.',
    // },
    {
      'question': 'Can I adjust or change my payment plan?',
      'answer':
          'Yes. If you want to extend or change your plan, simply contact customer support and we’ll assist you.',
    },
    {
      'question': 'What happens if I miss a payment?',
      'answer':
          'If you miss a payment, your device may be temporarily locked until the balance is cleared. Please pay on time to keep your device active.',
    },
    {
      'question': 'When will I fully own the device?',
      'answer':
          'Once your final installment is completed, the device becomes 100% yours with no extra charges.',
    },
  ];

  final Map<String, String> contacts = {
    'email': 'flexiphonesupport@vogghana.com',
    'phone': '+(+233) 302 937 130',
    'website': 'flexiphones.app',
  };

  int? expandedIndex;
  final String tel = "0302937130";
  final String email = "flexiphonessupport@wgghana.com";

  void toggleExpansion(int index) {
    setState(() {
      expandedIndex = expandedIndex == index ? null : index;
    });
  }

  void openEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: contacts['email']!);

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $emailUri';
    }
  }

  void callPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: contacts['phone']!);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  void openUrl() async {
    final Uri url = Uri.https(contacts['website']!);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return ListView(
      children: [
        // Padding(
        //   padding: const EdgeInsets.all(10.0),
        //   child: Text(
        //     "How may we be of help?",
        //     style: ptstyle(size: 20, weight: 600, color: ch.onSurfaceVariant),
        //   ),
        // ),

        // AbsorbPointer(
        //   absorbing: true,
        //   child: Opacity(
        //     opacity: 0.5,
        //     child: ListTile(
        //       onTap: widget.nextPage,
        //       contentPadding: EdgeInsets.all(10),

        //       title: Padding(
        //         padding: const EdgeInsets.only(bottom: 10),
        //         child: Text(
        //           "Service Ticket",
        //           style: ptstyle(
        //             size: 12,
        //             weight: 400,
        //             color: ch.onSurfaceVariant,
        //           ),
        //         ),
        //       ),
        //       subtitle: Row(
        //         crossAxisAlignment: CrossAxisAlignment.center,
        //         children: [
        //           Container(
        //             padding: EdgeInsets.all(10),
        //             decoration: BoxDecoration(
        //               borderRadius: BorderRadius.circular(50),
        //               color: ch.surfaceContainerLow,
        //             ),
        //             child: Icon(Icons.chat_bubble_outline_rounded, size: 20),
        //           ),
        //           SizedBox(width: 15),
        //           Expanded(
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Text("Inbox", style: ptstyle(size: 12, weight: 600)),
        //                 SizedBox(height: 5),
        //                 Text(
        //                   "View all service ticket",
        //                   style: ptstyle(size: 12, weight: 400),
        //                 ),
        //               ],
        //             ),
        //           ),
        //           Padding(
        //             padding: const EdgeInsets.all(6.0),
        //             child: Icon(
        //               Icons.arrow_forward_ios,
        //               color: ch.onSurfaceVariant.withOpacity(0.8),
        //               size: 15,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),

        // SDivider(),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
          child: Text(
            'Frequently Asked Questions',
            style: ptstyle(size: 18, weight: 600, color: ch.onSurfaceVariant),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,

          itemCount: faqs.length,

          itemBuilder: (context, index) {
            final faq = faqs[index];
            return buildExpandableFAQItem(context, faq, index);
          },
        ),
        SDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Contact Support',
                style: ptstyle(
                  size: 18,
                  weight: 600,
                  color: ch.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.email,
                      color: ch.onSurfaceVariant,
                      size: 18,
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          "Support Email",
                          style: ptstyle(
                            size: 12,
                            weight: 400,
                            color: ch.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 30,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                          ),
                          onPressed: () => openEmail(),
                          child: Text(
                            contacts['email']!,
                            style: ptstyle(
                              size: 12,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.phone,
                      color: ch.onSurfaceVariant,
                      size: 18,
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          "Call Us",
                          style: ptstyle(
                            size: 12,
                            weight: 400,
                            color: ch.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 30,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                          ),
                          onPressed: () => callPhone(),
                          child: Text(
                            contacts['phone']!,
                            style: ptstyle(
                              size: 12,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.public_outlined,
                      color: ch.onSurfaceVariant,
                      size: 18,
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          "Visit our website",
                          style: ptstyle(
                            size: 12,
                            weight: 400,
                            color: ch.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 30,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                          ),
                          onPressed: () => openUrl(),
                          child: Text(
                            contacts['website']!,
                            style: ptstyle(
                              size: 12,
                              weight: 400,
                              color: ch.onSurfaceVariant,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildExpandableFAQItem(BuildContext context, Map faq, int index) {
    var ch = Theme.of(context).colorScheme;
    bool isExpanded = expandedIndex == index;

    return AnimatedCrossFade(
      firstChild: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
        title: Text(
          faq['question'],
          style: ptstyle(
            size: 12,
            weight: 600,
            color: ch.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_right_rounded,
          color: ch.onSurfaceVariant.withOpacity(0.5),
        ),
        onTap: () => toggleExpansion(index),
      ),
      secondChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 10),

            title: Text(
              faq['question'],
              style: ptstyle(size: 12, weight: 600, color: ch.onSurfaceVariant),
            ),
            trailing: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ch.onSurfaceVariant,
            ),
            onTap: () => toggleExpansion(index),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 0,
              bottom: 20,
              left: 10,
              right: 10,
            ),
            child: Text(
              faq['answer'],
              style: ptstyle(
                size: 12,
                weight: 400,
                color: ch.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: Duration(milliseconds: 300),
    );
  }
}
