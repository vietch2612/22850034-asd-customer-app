import 'package:customer_app/socket/socket_service.dart';
import 'package:customer_app/types/driver_info.dart';
import 'package:customer_app/types/map_address.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/types/trip.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:customer_app/servivces/map_service.dart';

final backendHost = dotenv.env['BACKEND_HOST'];

io.Socket? socket;

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
    if (socket == null || socket!.disconnected) {
      socket = io.io('$backendHost', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });
    }

    socket!.on('trip_passenger_submit', (data) {
      logger.i("Received Trip passenger submit: ", data);
      activeTrip?.tripId = data['id'];
      setTripStatus(ExTripStatus.submitted);
      notifyListeners();
    });

    socket!.on('message', (data) {
      logger.i('Received message: $data');
    });

    /** Found a driver */
    socket!.on('trip_driver_allocate', (data) async {
      logger.i('allocated');
      setTripStatus(ExTripStatus.allocated);

      final DriverInfo driverInfo = DriverInfo.fromJson(data);

      activeTrip?.driverInfo = driverInfo;
      taxiMarkerLatLng = LatLng(driverInfo.currentLocation.location.lat,
          driverInfo.currentLocation.location.lng);
      redrawMapPolyline(driverInfo.currentLocation, activeTrip!.from);
      mapViewBoundsCallback?.call(taxiMarkerLatLng!, activeTrip!.from.toLatLng);

      notifyListeners();
    });

    socket!.on('trip_driver_driving', (data) async {
      logger.i('Driving', data);
      setTripStatus(ExTripStatus.driving);

      final DriverInfo driverInfo = DriverInfo.fromJson(data);

      activeTrip?.driverInfo = driverInfo;
      taxiMarkerLatLng = LatLng(driverInfo.currentLocation.location.lat,
          driverInfo.currentLocation.location.lng);
      redrawMapPolyline(driverInfo.currentLocation, activeTrip!.to);
      mapViewBoundsCallback?.call(taxiMarkerLatLng!, activeTrip!.to.toLatLng);

      notifyListeners();
    });

    socket!.on('trip_driver_driving_update', (data) async {
      logger.i('Updating driver location', data);

      taxiMarkerLatLng =
          LatLng(data['driverLocation']['lat'], data['driverLocation']['long']);
      // updateMapPolyline(driverInfo.currentLocation);
      mapViewBoundsCallback?.call(taxiMarkerLatLng!, activeTrip!.to.toLatLng);

      notifyListeners();
    });

    socket!.on('trip_driver_completed', (data) {
      setTripStatus(ExTripStatus.completed);
      stopTripWorkflow();
      notifyListeners();
    });
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
    SocketService.submitTripToSocket(socket, trip);
  }

  void redrawMapPolyline(MapAddress from, MapAddress to) async {
    Polyline newPolyline = await MapHelper.getPolyline(from, to);
    activeTrip?.polyline = newPolyline;
    notifyListeners();
  }

  void updateMapPolyline(MapAddress newLocation) {
    LatLng? lastPoint = activeTrip?.polyline.points.last;
    LatLng interpolatedPoint = LatLng(
      (lastPoint!.latitude + newLocation.location.lat) / 2,
      (lastPoint.longitude + newLocation.location.lng) / 2,
    );

    activeTrip?.polyline.points.add(interpolatedPoint);
    notifyListeners();
  }

  static TripProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<TripProvider>(context, listen: listen);
}
