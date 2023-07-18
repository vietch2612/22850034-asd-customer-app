// 22850034 ASD Customer App Flutter

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class ResolvedAddress {
  final Location location;
  final String mainText;
  final String secondaryText;

  LatLng get toLatLng => LatLng(location.lat, location.lng);

  ResolvedAddress({
    required this.location,
    required this.mainText,
    required this.secondaryText,
  });
}
