// 22850034 ASD Customer App Flutter

import 'package:customer_app/types/driver_info.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'resolved_address.dart';

enum ExTripStatus {
  submitted, // New trip submitted
  allocated, // Driver is found
  arrived, // Driver is arrived at the passenger location
  driving, // Driver has started the trip
  completed, // Done
  cancelled, // Either the passenger or driver cancelled the trip
}

final tripStatusDescriptions = <ExTripStatus, String>{
  ExTripStatus.submitted: "Đang tìm xe",
  ExTripStatus.allocated: "Đang tới",
  ExTripStatus.arrived: "Xe đã tới",
  ExTripStatus.driving: "Đang trên chuyến",
  ExTripStatus.completed: "Đã hoàn thành",
  ExTripStatus.cancelled: "Đã huỷ",
};

bool tripIsFinished(ExTripStatus status) =>
    [ExTripStatus.completed, ExTripStatus.cancelled].contains(status);

String getTripStatusDescription(ExTripStatus status) =>
    tripStatusDescriptions[status] ?? status.toString();

class TripDataEntity {
  int? tripId;
  final ResolvedAddress from;
  final ResolvedAddress to;
  Polyline polyline;
  final int distanceMeters;
  final String distanceText;
  ExTripStatus status;
  LatLngBounds mapLatLngBounds;
  CameraPosition? cameraPosition;
  DriverInfo? driverInfo;
  int? fare;
  int? distance;
  int? rating;

  TripDataEntity(
      {this.tripId,
      required this.from,
      required this.to,
      required this.polyline,
      required this.distanceMeters,
      required this.distanceText,
      required this.mapLatLngBounds,
      this.driverInfo,
      this.cameraPosition,
      this.fare,
      this.distance,
      this.rating,
      this.status = ExTripStatus.submitted});

//   {
//   "customerId": 1,
//   "serviceTypeId": 3,
//   "pickupLocation": "S701 Vinhomes Grand Park, Q9",
//   "pickupLocationLat": 10.8431537,
//   "pickupLocationLong": 106.8369187,
//   "dropoffLocationLat": 34.0522,
//   "dropoffLocationLong": -118.2437,
//   "dropoffLocation": "456 Second St, Another City",
//   "startTime": "2023-11-23T12:00:00Z",
//   "endTime": "2023-11-23T13:30:00Z",
//   "fare": 25,
//   "distance": 10,
//   "rating": 4
// }
  Map<String, dynamic> toJson() {
    return {
      "customerId": driverInfo == null ? 1 : driverInfo?.id,
      "serviceTypeId": 1,
      "pickupLocation": from.mainText,
      "pickupLocationLat": from.location.lat,
      "pickupLocationLong": from.location.lng,
      "dropoffLocation": to.mainText,
      "dropoffLocationLat": to.location.lat,
      "dropoffLocationLong": to.location.lng,
      "fare": fare,
      "distance": distance,
      "rating": rating
    };
  }
}
