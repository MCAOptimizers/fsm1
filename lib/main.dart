import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart'; // For geocoding addresses
import 'package:barcode_scan2/barcode_scan2.dart'; // Importer stregkodescanner biblioteket

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location and Google Maps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

// Item Model (global list to share between pages)
class Item {
  final String act;
  final String part;
  final String address;
  final String phone;
  final String time;
  bool isRunning = false;
  bool isCompleted = false;
  String elapsedTime = '';
  Timer? timer;
  int seconds = 0;

  Item({required this.act, required this.part, required this.address, required this.phone, required this.time});
}

// Global list of items (for both map markers and the list page)
final List<Item> items = [
  Item(act: '12322245', part: '56789', address: 'H.C. Andersens Boulevard 50, 1553 København', phone: '+45 1234 5678', time: '12:30'),
  Item(act: '23456', part: '67890, 12345', address: 'Nørrebrogade 72, 2200 København N', phone: '+45 8765 4321', time: '14:45'),
  Item(act: '34567', part: '78901', address: 'Gothersgade 15, 1123 København', phone: '+45 9988 7766', time: '10:30'),
  Item(act: '45678', part: '89012', address: 'Strandvejen 210, 2900 Hellerup', phone: '+45 1122 3344', time: '08:45'),
  Item(act: '56789', part: '90123', address: 'Vester Voldgade 83, 1552 København V', phone: '+45 4455 6677', time: '11:15'),
  Item(act: '67890', part: '01234', address: 'Amagerbrogade 130, 2300 København S', phone: '+45 2233 4455', time: '13:00'),
  Item(act: '78901', part: '12345', address: 'Ryesgade 58, 2100 København Ø', phone: '+45 5566 7788', time: '09:30'),
];

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position? _currentPosition;
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  final List<Marker> _markers = [];

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(55.6761, 12.5683), // Starting point: Copenhagen
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _getLocationPermission();
    _addMarkersForItems(); // Add markers to the map
  }

  Future<void> _addMarkersForItems() async {
    for (var item in items) {
      try {
        // Convert address to coordinates using geocoding
        List<Location> locations = await locationFromAddress(item.address);
        final marker = Marker(
          markerId: MarkerId(item.act),
          position: LatLng(locations[0].latitude, locations[0].longitude),
          infoWindow: InfoWindow(
            title: 'Act: ${item.act}',
            snippet: 'Part: ${item.part}\n${item.address}',
          ),
        );
        setState(() {
          _markers.add(marker);
        });
      } catch (e) {
        print('Could not find location for ${item.address}: $e');
      }
    }
  }

  Future<void> _getLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16,
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: Set<Marker>.of(_markers), // Display the markers on the map
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    16,
                  ),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.deepPurple,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.list, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ListPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white),
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      16,
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _getCurrentLocation();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// List Page with start/stop functionality
class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of Locations'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ItemCard(item: items[index]);
        },
      ),
    );
  }
}

// Item Card
class ItemCard extends StatefulWidget {
  final Item item;
  const ItemCard({super.key, required this.item});

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool hasCalled = false; // Track if the call button was pressed
  bool isPartMatched = false; // Track if scanned barcode matches the part number

  void startTimer() {
    setState(() {
      widget.item.isRunning = true; // Set running state to true
    });

    widget.item.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        widget.item.seconds++;
        widget.item.elapsedTime = formatDuration(widget.item.seconds);
      });
    });
  }

  void stopTimer() {
    setState(() {
      widget.item.isRunning = false;
      widget.item.isCompleted = true; // Mark the item as completed
      widget.item.timer?.cancel();
    });
  }

  String formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes min $remainingSeconds sec';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    // Opens phone app with number and marks as called
    await launchUrl(launchUri);

    setState(() {
      hasCalled = true;
    });
  }

  Future<void> scanBarcode() async {
    try {
      // Start scanning barcode
      var result = await BarcodeScanner.scan();

      if (result.rawContent == widget.item.part) {
        // If scanned barcode matches the part number
        setState(() {
          isPartMatched = true; // Set the matched status to true
        });
      } else {
        // If it doesn't match
        setState(() {
          isPartMatched = false;
        });
      }
    } catch (e) {
      print('Error scanning barcode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3, // Light shadow
      color: widget.item.isCompleted ? Colors.green : Colors.white, // Green if completed, white otherwise
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Padding around the card
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.item.isCompleted ? Colors.green : Colors.white, // Green background if completed
              borderRadius: BorderRadius.circular(15), // Same rounded corners for the container
            ),
            padding: const EdgeInsets.all(16), // Padding inside the card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Act: ${widget.item.act}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Part: ${widget.item.part}', style: TextStyle(color: isPartMatched ? Colors.green : Colors.black)), // Green if matched
                const SizedBox(height: 4),
                Text('Adresse: ${widget.item.address}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 4),
                    Text(widget.item.time),
                  ],
                ),
                const SizedBox(height: 16), // Space between info and buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(widget.item.phone),
                      icon: const Icon(Icons.phone, color: Colors.black), // Black icon
                      label: const Text('Ring', style: TextStyle(color: Colors.black)), // Black text
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasCalled ? Colors.green : Colors.white, // Green if called
                        elevation: 2, // Light shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded button corners
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openMaps(widget.item.address),
                      icon: const Icon(Icons.map, color: Colors.black), // Black icon
                      label: const Text('Vis vej', style: TextStyle(color: Colors.black)), // Black text
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // White button
                        elevation: 2, // Light shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded button corners
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.item.isRunning ? stopTimer : startTimer,
                      icon: widget.item.isRunning
                          ? const Icon(Icons.stop, color: Colors.black)
                          : const Icon(Icons.play_arrow, color: Colors.black), // Black icon
                      label: widget.item.isRunning
                          ? const Text('Stop', style: TextStyle(color: Colors.black))
                          : const Text('Start', style: TextStyle(color: Colors.black)), // Black text
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.item.isRunning
                            ? Colors.yellow
                            : widget.item.isCompleted
                                ? Colors.green
                                : Colors.white, // Yellow when running, green when completed
                        elevation: 2, // Light shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded button corners
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.item.isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Tid: ${widget.item.elapsedTime}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.qr_code, color: Colors.black),
              onPressed: scanBarcode, // Open camera to scan barcode
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(String address) async {
    final Uri mapsUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {'api': '1', 'query': address},
    );
    await launchUrl(mapsUri);
  }
}