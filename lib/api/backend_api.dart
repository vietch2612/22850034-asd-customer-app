import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:customer_app/types/trip.dart';
import 'package:logger/logger.dart';

final backendHost = dotenv.env['BACKEND_HOST'];
final logger = Logger();

class ApiService {
  static Future<String> createTrip(
      String customerId, TripDataEntity trip) async {
    String tripId = "";
    const String createTripEndpoint = '/api/trip/create';

    final Map<String, dynamic> requestBody = {
      'customerId': customerId,
      'pickupLocation': trip.from.mainText,
      'pickupLat': trip.from.location.lat,
      'pickupLong': trip.from.location.lng,
      'dropoffLocation': trip.to.mainText,
      'dropoffLat': trip.to.location.lat,
      'dropoffLong': trip.to.location.lng,
      'tripLength': trip.distanceMeters
    };

    print(jsonEncode(requestBody));

    try {
      final response = await http.post(
        Uri.parse('$backendHost$createTripEndpoint'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        tripId = responseData['tripId'];
      } else {
        throw Exception(
            'Failed to create trip. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error creating trip: $error');
    }

    return tripId;
  }

  static Future<int> calculateTripFare(
      int tripDistance, int numberOfSeat, int serviceType) async {
    const String calculateFareEndpoint = '/api/trips/calculate-fare';

    int fare = 0;

    try {
      final Map<String, dynamic> requestBody = {
        'length': tripDistance,
        'numberOfSeat': numberOfSeat,
        'serviceType': serviceType
      };

      final http.Response response = await http.post(
        Uri.parse('$backendHost$calculateFareEndpoint'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer your_placeholder_token'
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        fare = responseData['fare'];
      } else {}
    } catch (error) {
      logger.e(error);
    }

    return fare;
  }
}
