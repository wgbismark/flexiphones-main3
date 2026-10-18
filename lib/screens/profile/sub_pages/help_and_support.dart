import 'package:flexiphones/extensions/value_formating.dart';
import 'package:flexiphones/helpers/assets_helper.dart';
import 'package:flexiphones/screens/profile/sub_pages/help_and_support/faq.dart';
import 'package:flexiphones/screens/profile/sub_pages/help_and_support/new_ticket.dart';
import 'package:flexiphones/screens/profile/sub_pages/help_and_support/tickets.dart';
import 'package:flexiphones/shared_widgets/bgw.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  _HelpAndSupportState createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  final PageController _pageController = PageController(initialPage: 0);
  final subjectTEC = TextEditingController();
  final messageTEC = TextEditingController();
  final ImagePicker picker = ImagePicker();

  List<XFile> images = [];

  int _currentPage = 0;
  bool loading = false;

  // Data structure to hold all support content

  final List<Map<String, dynamic>> tickets = [
    {
      'id': 'TICK-001',
      'subject': 'Payment not reflecting',
      'status': 'In Progress',
      'attachments': [],
      'date': 'Tuesday, June 10, 2025 at 03:45 PM',
      'messages': [
        {
          'sender': 'Customer',
          'text':
              'Hi, I made a payment this morning but haven\'t received confirmation.',
          'time': 'Today at 9:45 AM',
        },
        {
          'sender': 'Support',
          'text':
              'We\'re looking into this issue. Our team will get back to you shortly.',
          'time': 'Today at 10:15 AM',
        },
      ],
    },
    {
      'id': 'TICK-002',
      'subject': 'Question about repayment schedule',
      'status': 'Pending',
      'attachments': [],
      'date': 'Monday, June 9, 2025 at 01:30 PM',
      'messages': [
        {
          'sender': 'Customer',
          'text': 'Can I reschedule my next repayment?',
          'time': 'Yesterday at 3:20 PM',
        },
      ],
    },
  ];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() => _currentPage++);
    }
  }

  void _toPage(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    setState(() => _currentPage = index);
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() => _currentPage--);
    }
  }

  void pickScreenshotImages() async {
    if (images.length > 3) return;
    XFile? newImg = await picker.pickImage(source: ImageSource.gallery);
    if (newImg == null) return;

    setState(() {
      images.add(newImg);

      //print("\n\n\n ${images.map((x) => x.path).toList().toString()} \n \n");
    });
  }

  void submitTicket() async {
    setState(() {
      loading = true;
    });

    await Future.delayed(Duration(seconds: 2), () {});

    final newTicket = {
      'id': 'TICK-${DateTime.now().millisecond * (tickets.length + 1)}',
      'subject': subjectTEC.text.trim(),
      'status': 'Pending',
      'date': DateTime.now().formatDate(),
      'attachments': images.isEmpty ? [] : images.map((x) => x.path).toList(),
      'messages': [
        {
          'sender': 'Customer',
          'text': messageTEC.text.trim(),
          'time': DateTime.now().toString(),
        },
      ],
    };
    FocusScope.of(context).unfocus();
    setState(() {
      tickets.insert(0, newTicket);
      subjectTEC.clear();
      messageTEC.clear();
    });

    _nextPage();

    setState(() {
      loading = false;
    });
  }

  Widget buildSuccessScreen(ColorScheme ch) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView(
        children: [
          Image.asset(AssetsHelper.tfaqIMG, width: 200, fit: BoxFit.contain),
          SizedBox(height: 20),
          Text(
            'Ticket Created Successfully!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ch.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Your ticket has been submitted successfully. Our support team will respond to you via email or SMS shortly.',
            style: ptstyle(size: 16, weight: 400, color: ch.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: SmartButton(
              enabled: true,
              loading: false,
              onPressed: () => _toPage(1),
              child: Text("OK"),
            ),
          ),
          SizedBox(height: 150),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ch.surface,
          elevation: 0,
          leading:
              _currentPage == 3
                  ? null
                  : IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed:
                        () =>
                            _currentPage > 0
                                ? _prevPage()
                                : Navigator.pop(context),
                  ),
          title: Text(
            _currentPage == 0
                ? 'Help'
                : _currentPage == 2
                ? "New Ticket"
                : "",
          ),
          centerTitle: true,

          actions: [
            if (_currentPage == 1)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton(
                  onPressed: () => _nextPage(),
                  child: Text("New Ticket"),
                ),
              ),
          ],
        ),
        body: Stack(
        children: [
          Bgw2(),
            PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                FAQ(nextPage: _nextPage),
            
                // Step 2: Tickets Screen
                Tickets(tickets: tickets),
            
                // Step 3: New Ticket Screen
                NewTicket(
                  images: images,
                  submitTicket: submitTicket,
                  subjectTEC: subjectTEC,
                  messageTEC: messageTEC,
                  pickScreenshotImages: pickScreenshotImages,
                  loading: loading,
                  removeImg:
                      (value) => setState(() {
                        images.removeAt(value);
                      }),
                ),
            
                // Step 4: Success Screen
                buildSuccessScreen(ch),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
