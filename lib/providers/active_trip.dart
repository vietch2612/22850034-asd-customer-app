// 22850034 ASD Customer App Flutter

import 'dart:math';

import 'package:customer_app/socket/socket_service.dart';
import 'package:customer_app/types/driver_info.dart';
import 'package:customer_app/types/resolved_address.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/types/trip.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:convert';
import 'package:customer_app/servivces/map_service.dart';

final backendHost = dotenv.env['BACKEND_HOST'];

var logger = Logger(
  printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      printTime: false),
);

typedef MapViewBoundsCallback = void Function(
    LatLng driverLocation, LatLng passengerLocation);

class TripProvider with ChangeNotifier {
  MapViewBoundsCallback? mapViewBoundsCallback;

  void setMapViewBoundsCallback(MapViewBoundsCallback callback) {
    mapViewBoundsCallback = callback;
  }

  ExTripStatus get currentTripStatus {
    return activeTrip?.status ?? ExTripStatus.allocated;
  }

  void openSocketForNewTrip(TripDataEntity trip) {
    final socket = io.io('$backendHost', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.on('connect', (_) {
      SocketService.submitTripToSocket(socket, trip);
    });

    socket.on('trip_passenger_submit', (data) {
      logger.i("Received Trip passenger submit: ", data);
      activeTrip?.tripId = data['id'];
      setTripStatus(ExTripStatus.submitted);
      notifyListeners();
    });

    socket.on('message', (data) {
      logger.i('Received message: $data');
    });

    /** Found a driver */
    socket.on('trip_driver_allocate', (data) async {
      logger.i('allocated');
      setTripStatus(ExTripStatus.allocated);

      final DriverInfo driverInfo = DriverInfo.fromJson(data);

      activeTrip?.driverInfo = driverInfo;
      taxiMarkerLatLng = LatLng(driverInfo.currentLocation.location.lat,
          driverInfo.currentLocation.location.lng);
      updateMapPoyline(driverInfo.currentLocation, activeTrip!.from);
      mapViewBoundsCallback?.call(taxiMarkerLatLng!, activeTrip!.from.toLatLng);

      notifyListeners();
    });

    socket.on('trip_driver_driving', (data) async {
      logger.i('Driving', data);
      setTripStatus(ExTripStatus.driving);

      final DriverInfo driverInfo = DriverInfo.fromJson(data);

      activeTrip?.driverInfo = driverInfo;
      taxiMarkerLatLng = LatLng(driverInfo.currentLocation.location.lat,
          driverInfo.currentLocation.location.lng);
      updateMapPoyline(driverInfo.currentLocation, activeTrip!.to);
      mapViewBoundsCallback?.call(taxiMarkerLatLng!, activeTrip!.to.toLatLng);

      notifyListeners();
    });

    // Driver sends
    socket.on('driving', (data) {
      // logger.i('[$tripId] Driving!');
      setTripStatus(ExTripStatus.driving);

      final DriverInfo driverInfo =
          DriverInfo.fromJson(jsonDecode(data)['driver']);

      activeTrip?.driverInfo = driverInfo;

      taxiMarkerLatLng = LatLng(driverInfo.currentLocation.location.lat,
          driverInfo.currentLocation.location.lng);

      //       if (driverLocation != null) {
      //   // Re-update the polyline from taxi to the destination
      //   updateMapPoyline(driverLocation, activeTrip!.to);
      //   // Update the taxi maker
      //   taxiMarkerLatLng =
      //       LatLng(driverLocation.location.lat, driverLocation.location.lng);
      // }

      notifyListeners();
    });

    socket.on('trip_driver_completed', (data) {
      setTripStatus(ExTripStatus.completed);
      notifyListeners();
      socket.disconnect();
    });

    socket.on('disconnect', (_) {});
  }

  TripDataEntity? activeTrip;

  bool get isActive => activeTrip != null;

  LatLng? taxiMarkerLatLng;

  LatLng getTaxiDrivePosition(double animationValue) {
    assert(activeTrip != null);
    final points = activeTrip!.polyline.points;
    int pointIndex = ((points.length - 1) * animationValue).round();
    return points[pointIndex];
  }

  void stopTripWorkflow() {
    taxiMarkerLatLng = null;
  }

  void setTripStatus(ExTripStatus newStatus) {
    if (activeTrip == null) return;
    if (tripIsFinished(newStatus)) stopTripWorkflow();
    activeTrip!.status = newStatus;
    notifyListeners();
  }

  void cancelTrip() => setTripStatus(ExTripStatus.cancelled);

  void deactivateTrip() {
    if (activeTrip == null) return;
    if (!tripIsFinished(activeTrip!.status)) {
      cancelTrip();
    }
    activeTrip = null;
    notifyListeners();
  }

  void activateTrip(TripDataEntity trip) {
    stopTripWorkflow();
    activeTrip = trip;
    openSocketForNewTrip(trip);
  }

  void updateMapPoyline(ResolvedAddress from, ResolvedAddress to) async {
    Polyline newPolyline = await MapHelper.getPolyline(from, to);
    activeTrip?.polyline = newPolyline;
    notifyListeners();
  }

  static TripProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<TripProvider>(context, listen: listen);
}
