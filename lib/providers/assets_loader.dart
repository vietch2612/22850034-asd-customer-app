// 22850034 ASD Customer App Flutter

import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class AssetLoaderProvider with ChangeNotifier {
  AssetLoaderProvider() {
    loadAssets();
  }

  BitmapDescriptor? get markerIconFrom => _markerIconFrom;
  BitmapDescriptor get markerIconTo =>
      _markerIconTo ?? BitmapDescriptor.defaultMarker;
  BitmapDescriptor get markerIconTaxi =>
      _markerIconTaxi ?? BitmapDescriptor.defaultMarker;

  BitmapDescriptor? _markerIconFrom;
  BitmapDescriptor? _markerIconTo;
  BitmapDescriptor? _markerIconTaxi;

  Future<void> loadAssets() async {
    //TODO: a temporary hack, device pixel ratio does not work on some devices. to be fixed later
    final imgPlatform = !kIsWeb && Platform.isAndroid ? "l" : "s";
    _markerIconFrom = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1),
        'assets/markers/from_$imgPlatform.png',
        mipmaps: false);
    _markerIconTo = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1),
        'assets/markers/to_$imgPlatform.png');
    _markerIconTaxi = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 1),
        'assets/markers/taxi_$imgPlatform.png');

    notifyListeners();
  }

  static AssetLoaderProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<AssetLoaderProvider>(context, listen: listen);
}
