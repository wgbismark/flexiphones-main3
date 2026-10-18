import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<bool> showConfirmationDialog({
  required BuildContext context,
  String title = 'Confirm',
  String content = 'Are you sure you want to proceed?',
  String confirmText = 'Yes',
  String cancelText = 'Cancel',

  required VoidCallback confirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => CNDi(
          title: title,
          content: content,
          confirmText: confirmText,
          cancelText: cancelText,
          confirm: confirm,
        ),
  );

  return result ?? false;
}

class CNDi extends StatelessWidget {
  const CNDi({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.confirm,
  });

  final String title;
  final String content;
  final String confirmText;
  final String cancelText;

  final VoidCallback confirm;
  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return AbsorbPointer(
      absorbing: sharedProvider.dialogueLoading,
      child: AlertDialog(
        backgroundColor: ch.surface,
        titlePadding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
        actionsPadding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 0,
          bottom: 10,
        ),
        contentPadding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 0,
          bottom: 10,
        ),
        title: Text(
          title,
          style: ptstyle(size: 20, weight: 600, color: ch.onSurface),
        ),
        content: Text(
          content,
          style: ptstyle(color: ch.onSurface, size: 12, weight: 400),
        ),
        actions: [
          Opacity(
            opacity: sharedProvider.dialogueLoading ? 0.3 : 1,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(elevation: 0),
              child: Text(cancelText, style: ptstyle(size: 12, weight: 500)),
            ),
          ),
          SizedBox(width: 2),
          sharedProvider.dialogueLoading
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(),
              )
              : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: ch.onSurfaceVariant.withOpacity(0.02),
                ),
                onPressed: confirm,
                child: Text(
                  confirmText,
                  style: ptstyle(
                    size: 12,
                    weight: 400,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
