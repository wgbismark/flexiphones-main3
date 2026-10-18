import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 100,
                color: ch.surfaceContainerHighest,
              ),
              SizedBox(height: 20),
              Text(
                "No Internet Connection",
                textAlign: TextAlign.center,
                style: ptstyle(
                  size: 25,
                  weight: 600,
                  color: ch.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  sharedProvider.connMSG,
                  textAlign: TextAlign.center,
                  style: ptstyle(
                    size: 16,
                    weight: 400,
                    color: ch.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 20),
              AbsorbPointer(
                absorbing: sharedProvider.connecting,
                child: FilledButton.tonalIcon(
                  onPressed: () => sharedProvider.hasInternetConnection(false,context),
                  icon:
                      sharedProvider.connecting
                          ? SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: ch.onSurfaceVariant,
                            ),
                          )
                          : Icon(Icons.refresh),
                  label:
                      sharedProvider.connecting
                          ? Text("  Reconnecting...")
                          : Text("Reconnect"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
