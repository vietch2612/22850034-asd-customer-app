import 'package:flutter/foundation.dart';
import 'package:customer_app/api/google_api.dart';
import 'package:customer_app/types/trip.dart';
import 'package:customer_app/providers/active_trip.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/providers/assets_loader.dart';
import 'package:customer_app/ui/common.dart';
import 'package:customer_app/providers/theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

import 'package:shimmer/shimmer.dart';

Widget tripFromTo(BuildContext context, TripDataEntity tripData) =>
    Column(children: [
      if (tripData.driverInfo != null)
        ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(tripData.driverInfo!.avatarUrl),
            ),
            title: Text(
              tripData.driverInfo!.name,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(children: [
              Text(
                tripData.driverInfo!.phoneNumber,
                style: const TextStyle(color: Colors.green),
              ),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white)),
              Text(
                  "${tripData.driverInfo!.licensePlate} ${tripData.driverInfo!.carInfo}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5), // Adjust spacing
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 18,
                  ),
                  Text(
                    "${tripData.driverInfo!.rating}/5",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ])),
      ListTile(
          leading: const Icon(Icons.person_pin_circle),
          title: Text(
            tripData.from.mainText,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(children: [
            const Text(
              'From',
              style: TextStyle(color: Colors.green),
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white)),
            Text(tripData.from.secondaryText,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))
          ])),
      ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(
            tripData.to.mainText,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(children: [
            const Text(
              'To',
              style: TextStyle(color: Colors.green),
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white)),
            Text(tripData.to.secondaryText,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))
          ]))
    ]);

class ActiveTrip extends StatefulWidget {
  const ActiveTrip({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ActiveTripState createState() => _ActiveTripState();
}

class _ActiveTripState extends State<ActiveTrip> {
  List<Marker> mapRouteMarkers = List.empty(growable: true);
  List<Marker> avaliableTaxiMarkers = List.empty(growable: true);

  final mapControllerCompleter = Completer<GoogleMapController>();
  GoogleMapController? mapController;

  List<String> errors = List.empty();

  bool pendingUpdate = false;

  @override
  Widget build(BuildContext context) {
    final trip = TripProvider.of(context);

    return buildAppScaffold(
        context,
        Column(
          children: [
            Expanded(
                child: GoogleMap(
              initialCameraPosition: trip.activeTrip!.cameraPosition ??
                  CameraPosition(
                      target: trip.activeTrip!.from.toLatLng, zoom: 15),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              scrollGesturesEnabled: true,
              markers: {
                if (trip.currentTripStatus != ExTripStatus.driving)
                  Marker(
                    icon: AssetLoaderProvider.of(context).markerIconFrom!,
                    position:
                        TripProvider.of(context).activeTrip!.from.toLatLng,
                    markerId: MarkerId(
                        'fromMarker ${kIsWeb ? DateTime.now().toIso8601String() : ''}'),
                  ),
                if (trip.currentTripStatus != ExTripStatus.allocated &&
                    trip.currentTripStatus != ExTripStatus.arrived)
                  Marker(
                    icon: AssetLoaderProvider.of(context).markerIconTo,
                    position: TripProvider.of(context).activeTrip!.to.toLatLng,
                    //smooth marker update does not work on flutter web
                    markerId: MarkerId(
                        'toMarker ${kIsWeb ? DateTime.now().toIso8601String() : ''}'),
                  ),
                if ((trip.currentTripStatus == ExTripStatus.allocated ||
                        trip.currentTripStatus == ExTripStatus.driving) &&
                    trip.taxiMarkerLatLng != null)
                  Marker(
                    icon: AssetLoaderProvider.of(context).markerIconTaxi,
                    position: TripProvider.of(context).taxiMarkerLatLng!,
                    markerId: MarkerId(
                        'taxiMarker ${kIsWeb ? DateTime.now().toIso8601String() : ''}'),
                  ),
              },
              polylines: <Polyline>{trip.activeTrip!.polyline},
              onMapCreated: (GoogleMapController controller) {
                mapControllerCompleter.complete(controller);
                mapController = controller;
                if (mounted) {
                  mapController!.animateCamera(CameraUpdate.newLatLngBounds(
                      trip.activeTrip!.mapLatLngBounds, 10));

                  final isDark =
                      ThemeProvider.of(context, listen: false).isDark;

                  controller.setMapStyle(
                      isDark ? googleMapDarkStyle : googleMapDefaultStyle);

                  setState(() {});
                }
              },
            )),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, -3), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                children: [
                  tripFromTo(context, trip.activeTrip!),
                  const Divider(height: 1),
                  SizedBox(
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Shimmer.fromColors(
                                  baseColor: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .color ??
                                      Colors.black,
                                  highlightColor:
                                      Theme.of(context).colorScheme.secondary,
                                  child: Text(
                                      getTripStatusDescription(
                                          trip.activeTrip!.status),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Theme.of(context).hintColor)),
                                ),
                              ],
                            ),
                          )),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: OutlinedButton(
                                style: ThemeProvider.of(context)
                                    .roundOutlinedButtonStyle,
                                onPressed: pendingUpdate
                                    ? null
                                    : () => trip.cancelTrip(),
                                child: const Text('Cancel Order')),
                          )
                        ],
                      )),
                ],
              ),
            )
          ],
        ));
  }
}
