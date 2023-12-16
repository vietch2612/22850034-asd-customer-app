// 22850034 ASD Customer App Flutter

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import "package:google_maps_webservice/places.dart";
import "package:google_maps_webservice/geocoding.dart";

import 'package:google_maps_webservice/directions.dart' as dir;
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

final _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
final apiGooglePlaces = GoogleMapsPlaces(apiKey: _googleMapsApiKey);
final apiGeocoding = GoogleMapsGeocoding(apiKey: _googleMapsApiKey);
final apiDirections = dir.GoogleMapsDirections(apiKey: _googleMapsApiKey);

List<LatLng>? createPolylinePointsFromDirections(
    dir.DirectionsResponse response) {
  if (response.isOkay) {
    final polylineRawList =
        decodePolyline(response.routes[0].overviewPolyline.points);
    List<LatLng> polylinePointList = polylineRawList
        .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
        .toList();

    for (LatLng point in polylinePointList) {
      print("Latitude: ${point.latitude}, Longitude: ${point.longitude}");
    }
    return polylinePointList;
  }
  return null;
}

const String googleMapDefaultStyle = '[]';
