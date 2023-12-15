// 22850034 ASD Customer App Flutter

import 'package:flutter/material.dart';
import 'package:customer_app/api/google_api.dart';
import 'package:customer_app/types/resolved_address.dart';
import 'package:customer_app/ui/common.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  var logger = Logger(
    printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: false,
        printTime: false),
  );
  bool pendingDetermineCurrentLocation = false;

  ResolvedAddress? _currentAddress;
  set currentAddress(ResolvedAddress? newAddress) {
    _currentAddress = newAddress;
    notifyListeners();
  }

  ResolvedAddress? get currentAddress => _currentAddress;

  bool get isDemoLocationFixed => _currentAddress != null;

  void reset() {
    _currentAddress = null;
    notifyListeners();
  }

  void determineCurrentLocation() async {
    try {
      pendingDetermineCurrentLocation = true;
      notifyListeners();

      final p = await _determinePosition();
      final res = await apiGeocoding
          .searchByLocation(Location(lat: p.latitude, lng: p.longitude));
      if (!res.isOkay) {
        throw Exception(
            'Geocoding API error. Status: ${res.status} ${res.errorMessage ?? ""}');
      }
      final f = res.results.first;
      logger.i(res);

      final mainPart = (f.addressComponents.length / 2.0).floor();

      // Convert address components to strings
      final mainText = f.addressComponents.take(mainPart).map((component) {
        return component.longName;
      }).join(', ');

      final secondaryText = f.addressComponents.skip(mainPart).map((component) {
        return component.longName;
      }).join(', ');

      currentAddress = ResolvedAddress(
        mainText: mainText,
        secondaryText: secondaryText,
        location: f.geometry.location,
      );
    } catch (e) {
      showScaffoldSnackBarMessage(e.toString());
    } finally {
      pendingDetermineCurrentLocation = false;
      notifyListeners();
    }
  }

  Future<Position> _determinePosition() async {
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
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final cp = await Geolocator.getCurrentPosition();
    return cp;
  }

  static LocationProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<LocationProvider>(context, listen: listen);
}
