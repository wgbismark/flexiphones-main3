import 'dart:io';

import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

class TicketDetailPage extends StatelessWidget {
  const TicketDetailPage({super.key, required this.ticketData});

  final Map<String, dynamic> ticketData;

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Support Ticket', style: ptstyle(size: 16, weight: 400)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${ticketData['id']}',
                  style: ptstyle(size: 16, weight: 600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subject: ${ticketData['subject']}',
                  style: ptstyle(size: 12, weight: 600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${ticketData['status']}',
                  style: ptstyle(size: 12, weight: 600, color: ch.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${ticketData['date']}',
                  style: ptstyle(size: 12, weight: 400),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text('Messages:', style: ptstyle(size: 18, weight: 600)),

            // Messages List
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => SizedBox(height: 10),
                itemCount: ticketData['messages'].length,
                itemBuilder: (context, index) {
                  final message = ticketData['messages'][index];
                  final isCustomer = message['sender'] == 'Customer';
                  return MessageBubble(
                    text: message['text'],
                    time: message['time'],
                    isCustomer: isCustomer,
                    attachments: ticketData["attachments"],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Message Bubble Widget
class MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final List attachments;
  final bool isCustomer;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isCustomer,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: !isCustomer ? ch.primaryContainer : ch.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment:
                  !isCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Text(
                  !isCustomer ? "Support" : "You",
                  style: ptstyle(
                    size: 12,
                    weight: 600,
                    color: ch.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(text, style: ptstyle(size: 12, weight: 400)),
            SizedBox(height: 10),
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            SizedBox(height: 5),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3, // 👈 3 columns
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: List.generate(
                attachments.length,
                (index) => SizedBox(
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(attachments[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
