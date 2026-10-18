import 'dart:io';

import 'package:flexiphones/helpers/navigation_helper.dart';
import 'package:flexiphones/screens/profile/sub_pages/help_and_support/view_ticket.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

class Tickets extends StatefulWidget {
  const Tickets({super.key, required this.tickets});
  final List tickets;

  @override
  State<Tickets> createState() => _TicketsState();
}

class _TicketsState extends State<Tickets> {
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text('Inbox', style: ptstyle(size: 18, weight: 600)),
          SizedBox(height: 20),
          Expanded(
            child:
                widget.tickets.isEmpty
                    ? Center(
                      child: Text(
                        'No tickets found. Tap the + button to create a new one.',
                      ),
                    )
                    : ListView.separated(
                      itemCount: widget.tickets.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final ticket = widget.tickets[index];
                        return ListTile(
                          onTap:
                              () => NavigationHelper.push(
                                context,
                                TicketDetailPage(ticketData: ticket),
                              ),
                          contentPadding: EdgeInsets.all(0),
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ticket['subject'],
                                  overflow: TextOverflow.ellipsis,
                                  style: ptstyle(size: 12, weight: 600),
                                ),
                              ),
                              SizedBox(width: 50),
                              Text(
                                "Ticket ID: ${ticket['id']}",
                                style: ptstyle(size: 12, weight: 400),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ticket['messages'][0]['text'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: ptstyle(
                                        size: 12,
                                        weight: 400,
                                        color: ch.onSurfaceVariant,
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.keyboard_arrow_right_rounded,
                                      size: 25,
                                      color: ch.onSurfaceVariant.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),

                              Row(
                                children: [
                                  Text(
                                    'Last updated: ',
                                    style: TextStyle(
                                      color: ch.onSurfaceVariant.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ticket["date"].toString(),
                                    style: TextStyle(
                                      color: ch.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 3, // 👈 3 columns
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                children: List.generate(
                                  ticket['attachments'].length,
                                  (index) => SizedBox(
                                    height: 50,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(ticket['attachments'][index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
