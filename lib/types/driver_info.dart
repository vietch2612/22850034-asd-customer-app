import 'package:customer_app/types/resolved_address.dart';
import 'package:google_maps_webservice/directions.dart' as dir;

class DriverInfo {
  final int id;
  final String name;
  final String licensePlate;
  final String carInfo;
  final String phoneNumber;
  final String avatarUrl;
  final int rating;
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
      json['Driver']['id'],
      json['Driver']['avatarUrl'],
      json['Driver']['rating'],
      json['Driver']['Car']['name'],
      phoneNumber: json['Driver']['phoneNumber'],
      name: json['Driver']['name'],
      licensePlate: json['Driver']['licensePlateNumber'],
      currentLocation: ResolvedAddress(
        location: dir.Location(
          lat: json['Driver']['DriverLocations'][0]['lat'],
          lng: json['Driver']['DriverLocations'][0]['long'],
        ),
        mainText: "",
        secondaryText: "",
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Driver': {
        'id': id,
        'avatarUrl': avatarUrl,
        'rating': rating,
        'DriverLocations': [
          {
            'lat': currentLocation.location.lat,
            'long': currentLocation.location.lng,
          },
        ],
      },
    };
  }
}
