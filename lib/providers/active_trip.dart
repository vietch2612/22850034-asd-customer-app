// 22850034 ASD Customer App Flutter

import 'package:flutter/material.dart';
import 'package:customer_app/types/trip.dart';
import 'package:customer_app/api/backend_api.dart';
import 'package:customer_app/socket/socket_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final backendHost = dotenv.env['BACKEND_HOST'];

// demo trip
class TripProvider with ChangeNotifier {
  void openSocketConnection(TripDataEntity trip,
      {required Function(ExTripStatus) updateTripStatusCallback}) {
    final socket = io.io('$backendHost', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.on('connect', (_) {
      final message = {"tripId": trip.tripId};
      socket.emit('new_trip', jsonEncode(message));
    });

    socket.on('message', (data) {
      print('Received message: $data');
    });

    socket.on('finding_driver', (data) {
      print('Received driver_found: $data');
    });

    socket.on('picking_up', (data) {
      setTripStatus(ExTripStatus.allocated);
      print('Received picking_up: $data');
    });

    socket.on('driver_arrived', (data) {
      setTripStatus(ExTripStatus.arrived);
      print('Received driver_arrived: $data');
    });

    socket.on('in_transit', (data) {
      setTripStatus(ExTripStatus.driving);
      const drivingDuration = Duration(seconds: 15);
      final drivingStartTime = DateTime.now();
      final drivingEndTime = DateTime.now().add(drivingDuration);
      completedStateTimer =
          Timer(drivingDuration, () => setTripStatus(ExTripStatus.completed));

      drivingProgressTimer =
          Timer.periodic(const Duration(milliseconds: 300), (timer) {
        final now = DateTime.now();
        if (trip.status != ExTripStatus.driving ||
            DateTime.now().compareTo(drivingEndTime) >= 0) {
          timer.cancel();
          return;
        }
        double drivingAnimationValue =
            now.difference(drivingStartTime).inMilliseconds.toDouble() /
                drivingDuration.inMilliseconds.toDouble();
        taxiMarkerLatLng = getTaxiDrivePosition(drivingAnimationValue);
        notifyListeners();
      });
      print('Received in_transit: $data');
    });

    socket.on('completed', (data) {
      updateTripStatusCallback(ExTripStatus.completed);
      print('Received completed: $data');
      socket.disconnect();
    });

    socket.on('disconnect', (_) {
      print('Socket disconnected');
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

  void updateTripStatusFromSocket(ExTripStatus newStatus) {
    setTripStatus(newStatus);
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
    // Make API call to start the trip
    const String customerId = "022848e7-a724-4692-bb94-9f377a182fea";
    ApiService.createTrip(customerId, trip).then((tripId) {
      trip.tripId = tripId;
      // Successful API call, start socket connection
      openSocketConnection(trip,
          updateTripStatusCallback: updateTripStatusFromSocket);

      // allocatedStateTimer = Timer(const Duration(seconds: 1),
      //     () => setTripStatus(ExTripStatus.allocated));
      // arrivedStateTimer = Timer(const Duration(seconds: 2),
      //     () => setTripStatus(ExTripStatus.arrived));
      // const drivingDuration = Duration(seconds: 15);

      // drivingStateTimer = Timer(const Duration(seconds: 3), () {
      //   setTripStatus(ExTripStatus.driving);

      //   final drivingStartTime = DateTime.now();
      //   final drivingEndTime = DateTime.now().add(drivingDuration);
      //   completedStateTimer =
      //       Timer(drivingDuration, () => setTripStatus(ExTripStatus.completed));

      //   drivingProgressTimer =
      //       Timer.periodic(const Duration(milliseconds: 300), (timer) {
      //     final now = DateTime.now();
      //     if (trip.status != ExTripStatus.driving ||
      //         DateTime.now().compareTo(drivingEndTime) >= 0) {
      //       timer.cancel();
      //       return;
      //     }
      //     double drivingAnimationValue =
      //         now.difference(drivingStartTime).inMilliseconds.toDouble() /
      //             drivingDuration.inMilliseconds.toDouble();
      //     taxiMarkerLatLng = getTaxiDrivePosition(drivingAnimationValue);
      //     notifyListeners();
      //   });
      // });

      notifyListeners();
    }).catchError((apiError) {
      // Handle API call error
      print('Error starting trip (API): $apiError');
    });
  }

  static TripProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<TripProvider>(context, listen: listen);
}
