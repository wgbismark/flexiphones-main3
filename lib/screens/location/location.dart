import 'package:flexiphones/helpers/dummy_data.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flutter/material.dart';

class LocationScreen extends StatefulWidget {
  final String currentLocation;
  final ValueChanged<String> onLocationChanged;

  const LocationScreen({
    super.key,
    required this.currentLocation,
    required this.onLocationChanged,
  });

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _currentLocation = "";
  final searchCnt = TextEditingController();

  final fnode = FocusNode();

  String _searchQuery = '';
  bool search = false;
  @override
  void initState() {
    super.initState();
    _currentLocation = widget.currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    var ch = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ch.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Location'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledInput(
              focusNode: fnode,
              controller: searchCnt,
              hintText: "Enter Your location",
              label: "",
              onChange: (value) {
                search = true;

                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              suffixIcon:
                  search
                      ? SizedBox(
                        height: 40,
                        width: 40,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              search = false;
                            });
                          },
                          icon: Icon(Icons.close_rounded, size: 20),
                        ),
                      )
                      : Icon(Icons.search_rounded, size: 20),
            ),
            search
                ? Expanded(
                  child: ListView.builder(
                    itemCount:
                        _searchQuery.isEmpty
                            ? suggestedLocations.length
                            : suggestedLocations
                                .where((x) => x.contains(_searchQuery))
                                .length,
                    itemBuilder: (context, index) {
                      final location =
                          _searchQuery.isEmpty
                              ? suggestedLocations[index]
                              : suggestedLocations
                                  .where((x) => x.contains(_searchQuery))
                                  .toList()[index];
                      return ListTile(
                        title: Text(location),
                        onTap: () {
                          widget.onLocationChanged(location);
                          setState(() {
                            _currentLocation = location;
                            search = false;
                          });
                          searchCnt.clear();
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Current Location',
                                  style: TextStyle(color: ch.onSurfaceVariant),
                                ),
                                Text(
                                  _currentLocation,
                                  style: TextStyle(color: ch.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              search = true;
                            });
                          },
                          child: Text(
                            'Choose',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
