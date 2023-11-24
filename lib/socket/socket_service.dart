import 'package:customer_app/types/trip.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SocketService {
  static void submitTripToSocket(socket, TripDataEntity trip) async {
    socket.emit('trip_passenger_submit', trip.toJson());

    logger.i('Started a new trip!: ', trip.toJson());
  }
}
