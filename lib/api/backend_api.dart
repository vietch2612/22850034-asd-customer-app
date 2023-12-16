import 'dart:convert';
import 'package:customer_app/global.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:customer_app/types/trip.dart';
import 'package:logger/logger.dart';

final backendHost = dotenv.env['GATEWAY_HOST'];
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

  static void ratingTrip(tripId, rating) async {
    final Map<String, dynamic> requestBody = {'rating': rating};

    try {
      final response = await http.post(
        Uri.parse('$backendHost/api/trip/$tripId/rating'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authentication': 'Bearer ${globalCustomer?.token}'
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        tripId = responseData['tripId'];
      } else {
        throw Exception(
            'Failed to rating trip. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error creating trip: $error');
    }
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
          'Authorization': 'Bearer ${globalCustomer?.token}'
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        fare = int.parse(responseData['fare']);
      } else {}
    } catch (error) {
      logger.e(error);
    }

    return fare;
  }
}
