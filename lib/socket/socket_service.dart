// import 'dart:convert';

// import 'package:socket_io_client/socket_io_client.dart' as io;
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// import '../types/trip.dart';

// final backendHost = dotenv.env['BACKEND_HOST'];

// class SocketService {
//   static void openSocketConnection(TripDataEntity trip,
//       {required Function(ExTripStatus) updateTripStatusCallback}) {
//     final socket = io.io('$backendHost', <String, dynamic>{
//       'transports': ['websocket'],
//       'autoConnect': true,
//     });

//     socket.on('connect', (_) {
//       final message = {"tripId": trip.tripId};
//       socket.emit('new_trip', jsonEncode(message));
//     });

//     socket.on('message', (data) {
//       print('Received message: $data');
//     });

//     socket.on('finding_driver', (data) {
//       print('Received driver_found: $data');
//     });

//     socket.on('picking_up', (data) {
//       updateTripStatusCallback(ExTripStatus.allocated);
//       print('Received picking_up: $data');
//     });

//     socket.on('driver_arrived', (data) {
//       updateTripStatusCallback(ExTripStatus.arrived);
//       print('Received driver_arrived: $data');
//     });

//     socket.on('in_transit', (data) {
//       updateTripStatusCallback(ExTripStatus.driving);
//       print('Received in_transit: $data');
//     });

//     socket.on('completed', (data) {
//       updateTripStatusCallback(ExTripStatus.completed);
//       print('Received completed: $data');
//       socket.disconnect();
//     });

//     socket.on('disconnect', (_) {
//       print('Socket disconnected');
//     });
//   }
// }
