# FSM1 Flutter App

Denne app er bygget med Flutter og inkluderer følgende funktioner:

- Geolocation og Google Maps
- Stregkodescanning med Barcode Scanner
- Tidsregistrering for hver opgave

## main.dart
```dart
// main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:barcode_scan2/barcode_scan2.dart';

void main() {
  runApp(const MyApp());
}
...
// rest of your code here
