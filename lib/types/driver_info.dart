import 'package:customer_app/types/resolved_address.dart';
import 'package:google_maps_webservice/directions.dart' as dir;

class DriverInfo {
  final String id;
  final String name;
  final String licensePlate;
  final String carInfo;
  final String phoneNumber;
  final String avatarUrl;
  final String rating;
  final ResolvedAddress currentLocation;

  DriverInfo(
    this.id,
    this.avatarUrl,
    this.rating,
    this.carInfo, {
    required this.phoneNumber,
    required this.name,
    required this.licensePlate,
    required this.currentLocation,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      json['driver']['id'],
      json['driver']['avatarUrl'],
      json['driver']['rating'],
      json['driver']['carInfo'],
      phoneNumber: json['driver']['phoneNumber'],
      name: json['driver']['name'],
      licensePlate: json['driver']['licensePlate'],
      currentLocation: ResolvedAddress(
        location: dir.Location(
          lat: json['driver']['currentLocation']['latitude'],
          lng: json['driver']['currentLocation']['longitude'],
        ),
        mainText: json['driver']['currentLocation']['address'],
        secondaryText: json['driver']['currentLocation']['address'],
      ),
    );
  }
}
