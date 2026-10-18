import 'dart:io';

import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flexiphones/shared_widgets/smart_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NewTicket extends StatelessWidget {
  const NewTicket({
    super.key,
    required this.submitTicket,
    required this.subjectTEC,
    required this.messageTEC,
    required this.images,
    required this.pickScreenshotImages,
    required this.loading,
    required this.removeImg,
  });
  final VoidCallback submitTicket;
  final VoidCallback pickScreenshotImages;
  final TextEditingController subjectTEC;
  final TextEditingController messageTEC;
  final List<XFile> images;
  final bool loading;
  final ValueChanged<int> removeImg;
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        Text(
          'What do you need help with?',
          style: ptstyle(size: 15, weight: 600, color: ch.onSurface),
        ),
        SizedBox(height: 20),
        Text(
          'Subject:',
          style: ptstyle(size: 12, weight: 500, color: ch.onSurfaceVariant),
        ),
        SizedBox(height: 10),
        FilledInput(hintText: '. . . .', label: "", controller: subjectTEC),
        SizedBox(height: 15),
        Text(
          'Write your message here:',

          style: ptstyle(size: 12, weight: 500, color: ch.onSurfaceVariant),
        ),
        SizedBox(height: 10),
        FilledInput(
          lines: 5,
          label: '',
          hintText: ". . . .",
          controller: messageTEC,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.attach_file, color: ch.primary),
            SizedBox(width: 8),
            Text(
              'Attach a screenshot',
              style: ptstyle(size: 12, weight: 500, color: ch.primary),
            ),
            SizedBox(width: 8),
            Text('(Optional)', style: ptstyle(size: 12, weight: 400)),
          ],
        ),
        SizedBox(height: 16),
        //  if (images != null)
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3, // 👈 3 columns
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            if (images.isNotEmpty)
              for (var img in images)
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: double.infinity,
                      width: double.infinity,
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(img.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.all(2),
                        backgroundColor: ch.surface,
                      ),
                      onPressed: () {
                        removeImg.call(images.indexOf(img));
                      },
                      icon: Icon(
                        Icons.delete_forever_outlined,
                        color: ch.primary,
                      ),
                    ),
                  ],
                ),
            if (images.length < 2)
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: ch.surfaceContainerLow.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.photo_size_select_actual_outlined,
                  size: 30,
                  color: ch.onSurfaceVariant.withOpacity(0.3),
                ),
              ),
            if (images.length < 3)
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
                  ),
                ),
                onPressed: pickScreenshotImages,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 30),
                    SizedBox(height: 10),
                    Text(
                      'Add',
                      style: ptstyle(
                        size: 12,
                        weight: 600,
                        color: ch.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        Text(
          '\nThis will help use identify the issue quickly.\n',
          style: ptstyle(size: 15, weight: 400, color: ch.onSurfaceVariant),
        ),

        SizedBox(
          width: double.infinity,
          height: 40,
          child: SmartButton(
            enabled: true,
            loading: loading,
            onPressed: submitTicket,
            child: Text("Send"),
          ),
        ),
      ],
    );
  }
}
