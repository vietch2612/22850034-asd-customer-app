import 'package:customer_app/providers/active_trip.dart';
import 'package:customer_app/types/resolved_address.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart' as dir;
import 'package:customer_app/api/google_api.dart';

class MapHelper {
  static Future<Polyline> getPolyline(
      ResolvedAddress? from, ResolvedAddress? to) async {
    const Polyline temp = Polyline(
      polylineId: PolylineId('polyline-1'),
      width: 5,
      color: Colors.blue,
      points: [],
    );
    if (from == null || to == null) {
      return temp;
    }

    dir.DirectionsResponse response =
        await apiDirections.directionsWithLocation(from.location, to.location);

    if (!response.isOkay) {
      final error =
          'Directions API error. Status: ${response.status} ${response.errorMessage ?? ""}';
      logger.e(error);
    }

    final polylinePoints = createPolylinePointsFromDirections(response);

    if (polylinePoints == null) {
      // TODO Handle the case where polylinePoints is null.
      return temp;
    }

    logger.i("All good ulti here!");

    return Polyline(
      polylineId: const PolylineId('polyline-1'),
      width: 5,
      color: Colors.black,
      points: polylinePoints,
    );
  }

  static void moveCameraToBounds({
    required GoogleMapController controller,
    required LatLngBounds bounds,
    double padding = 30.0,
  }) {
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        padding,
      ),
    );
  }

  static void addMarker({
    required GoogleMapController controller,
    required LatLng position,
    required String markerId,
    required BitmapDescriptor icon,
  }) {
    final Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: icon,
    );

    // controller.addMarker(marker);
  }
}
