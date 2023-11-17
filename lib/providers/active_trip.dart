// 22850034 ASD Customer App Flutter

import 'package:flutter/material.dart';
import 'package:customer_app/types/trip.dart';
import 'package:customer_app/api/backend_api.dart';
import 'package:customer_app/servivces/map_service.dart';
import 'package:customer_app/types/resolved_address.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:google_maps_webservice/directions.dart' as dir;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final backendHost = dotenv.env['BACKEND_HOST'];
var logger = Logger(
  printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: false, // Print an emoji for each log message
      printTime: false // Should each log print contain a timestamp
      ),
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
      final tripId = trip.tripId;
      final message = {"tripId": tripId};
      socket.emit('new_trip', jsonEncode(message));
      logger.i('Started a new trip: $tripId');
    });

    socket.on('message', (data) {
      logger.i('Received message: $data');
    });

    socket.on('finding_driver', (data) {
      logger.i('Received finding_driver: $data');
      // Re-update the map
      // Remove the marker from the destination
      // Remove the line
      // Adjust the view point
      notifyListeners();
    });

    socket.on('picking_up', (data) {
      setTripStatus(ExTripStatus.allocated);

      final driverLocation = getDriverLocation(data);
      if (driverLocation != null) {
        updateMapPoyline(activeTrip!.from, driverLocation);
        taxiMarkerLatLng =
            LatLng(driverLocation.location.lat, driverLocation.location.lng);
      }

      mapViewBoundsCallback?.call(
        taxiMarkerLatLng!,
        activeTrip!.from.toLatLng,
      );

      notifyListeners();
    });

    socket.on('driver_arrived', (data) {
      setTripStatus(ExTripStatus.arrived);
      logger.i('Received driver_arrived: $data');
      notifyListeners();
    });

    // Driver sends
    socket.on('in_transit', (data) {
      logger.i('Received in_transit: $data');
      // Update trip status to Driving
      setTripStatus(ExTripStatus.driving);

      final driverLocation = getDriverLocation(data);

      if (driverLocation != null) {
        // Re-update the polyline from taxi to the destination
        updateMapPoyline(driverLocation, activeTrip!.to);
        // Update the taxi maker
        taxiMarkerLatLng =
            LatLng(driverLocation.location.lat, driverLocation.location.lng);
      }

      notifyListeners();
    });

    socket.on('completed', (data) {
      setTripStatus(ExTripStatus.completed);
      notifyListeners();
      logger.i('Received completed: $data');
      socket.disconnect();
    });

    socket.on('disconnect', (_) {
      logger.i('Socket disconnected');
    });
  }

  TripDataEntity? activeTrip;

  bool get isActive => activeTrip != null;

  Timer? allocatedStateTimer;
  Timer? arrivedStateTimer;
  Timer? drivingStateTimer;
  Timer? completedStateTimer;
  Timer? drivingProgressTimer;

  LatLng? taxiMarkerLatLng;

  LatLng getTaxiDrivePosition(double animationValue) {
    assert(activeTrip != null);
    final points = activeTrip!.polyline.points;
    int pointIndex = ((points.length - 1) * animationValue).round();
    return points[pointIndex];
  }

  ResolvedAddress? getDriverLocation(Map<String, dynamic> data) {
    final Map<String, dynamic>? locationData =
        data['location'] as Map<String, dynamic>?;

    if (locationData != null) {
      final double? latitude = locationData['lat'] as double?;
      final double? longitude = locationData['long'] as double?;

      if (latitude != null && longitude != null) {
        return ResolvedAddress(
            location: dir.Location(lat: latitude, lng: longitude),
            mainText: "driver location",
            secondaryText: "driver location");
      }
    }

    return null;
  }

  void stopTripWorkflow() {
    for (var t in [
      allocatedStateTimer,
      arrivedStateTimer,
      drivingStateTimer,
      completedStateTimer,
      drivingProgressTimer,
    ]) {
      t?.cancel();
    }
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
    const String customerId = "022848e7-a724-4692-bb94-9f377a182fea";
    ApiService.createTrip(customerId, trip).then((tripId) {
      trip.tripId = tripId;
      openSocketForNewTrip(trip);
    }).catchError((apiError) {
      logger.e('Error starting trip (API): $apiError');
    });
  }

  void updateMapPoyline(ResolvedAddress from, ResolvedAddress to) async {
    Polyline newPolyline = await MapHelper.getPolyline(from, to);
    activeTrip?.polyline = newPolyline;
    notifyListeners();
  }

  static TripProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<TripProvider>(context, listen: listen);
}
