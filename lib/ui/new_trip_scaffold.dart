// 22850034 ASD Customer App Flutter

import 'dart:math';
import 'package:customer_app/api/backend_api.dart';
import 'package:customer_app/servivces/formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/api/google_api.dart';
import 'package:customer_app/types/resolved_address.dart';
import 'package:customer_app/types/trip.dart';
import 'package:customer_app/ui/address_search.dart';
import 'package:customer_app/providers/assets_loader.dart';
import 'package:customer_app/providers/location.dart';
import 'package:customer_app/providers/active_trip.dart';
import 'package:customer_app/ui/common.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/providers/theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:google_maps_webservice/directions.dart' as dir;
import 'package:google_maps_webservice/places.dart';
import 'package:shimmer/shimmer.dart';

import 'package:logger/logger.dart';

final logger = Logger();

class NewTrip extends StatefulWidget {
  final TripProvider tripProvider;

  const NewTrip({Key? key, required this.tripProvider}) : super(key: key);

  Future<void> recalculateRoute() async {
    await _newTripState?.recalcRoute(); // Use _newTripState instance
  }

  void initiateNewTrip(BuildContext context) {
    _newTripState?.startNewTrip(context); // Use _newTripState instance
  }

  @override
  // ignore: no_logic_in_create_state, library_private_types_in_public_api
  _NewTripState createState() {
    _newTripState = _NewTripState();
    return _newTripState!;
  }
}

class _NewTripState extends State<NewTrip> {
  LatLngBounds? cameraViewportLatLngBounds;

  ResolvedAddress? from;
  ResolvedAddress? to;

  Polyline? tripPolyline;
  int tripDistanceMeters = 0;
  String tripDistanceText = '';
  int tripFare = 0;
  String tripFareText = '';
  int numberOfSeat = 4;
  int serviceType = 0;
  String selectedSeatType = '4 Chỗ';
  String selectedServiceType = 'Tiết kiệm'; // 0 == Regular, 1 = VIP

  // Calculate the fare
  Future<void> calculateFare() async {
    tripFare = await ApiService.calculateTripFare(
        tripDistanceMeters, numberOfSeat, serviceType);
    tripFareText = await formatCurrency(tripFare);
  }

  Future<void> recalcRoute() async {
    tripPolyline = null;
    tripDistanceText = '';
    tripDistanceMeters = 0;
    tripFare = 0;
    tripFareText = '';

    if (from == null || to == null) {
      return;
    }
    dir.DirectionsResponse response = await apiDirections
        .directionsWithLocation(from!.location, to!.location);
    if (response.isOkay) {
      tripDistanceMeters =
          response.routes.first.legs.first.distance.value.round();
      tripDistanceText = response.routes.first.legs.first.distance.text;

      if (!response.isOkay) {
        final error =
            'Directions API error. Status: ${response.status} ${response.errorMessage ?? ""}';
        showScaffoldSnackBarMessage(error);

        if (mounted) setState(() {});
      }

      calculateFare();

      final polylinePoints = createPolylinePointsFromDirections(response)!;

      tripPolyline = Polyline(
          polylineId: const PolylineId('polyline-1'),
          width: 5,
          color: Colors.blue,
          points: polylinePoints);
      adjustMapViewBounds();
      if (mounted) setState(() {});
    }
  }

  LatLngBounds? _mapCameraViewBounds;

  void adjustMapViewBounds() {
    logger.i('adjustMapViewBounds()');
    if (!mounted) return;

    //0.001 ~= 100 m
    const double deltaLatLngPointBound = 0.0015;

    double minx = 180, miny = 180, maxx = -180, maxy = -180;
    if (from == null && to == null) return;
    if (from == null ||
        to == null ||
        from!.location.lat == to!.location.lat &&
            from!.location.lng == to!.location.lng) {
      double lat = from?.toLatLng.latitude ?? to?.toLatLng.latitude ?? 0;
      double lng = from?.toLatLng.longitude ?? to?.toLatLng.longitude ?? 0;
      minx = lng - deltaLatLngPointBound;
      maxx = lng + deltaLatLngPointBound;
      miny = lat - deltaLatLngPointBound;
      maxy = lat + deltaLatLngPointBound;

      if (minx < -180) minx = -180;
      if (miny < -90) miny = -90;
      if (maxx > 180) minx = 180;
      if (maxy > 90) maxy = 90;
    } else {
      for (var p in [
        from!.toLatLng,
        to!.toLatLng,
        if (tripPolyline != null) ...tripPolyline!.points
      ]) {
        minx = min(minx, p.longitude);
        maxx = max(maxx, p.longitude);

        miny = min(miny, p.latitude);
        maxy = max(maxy, p.latitude);
      }
    }

    final newCameraViewBounds = LatLngBounds(
      northeast: LatLng(maxy, maxx),
      southwest: LatLng(miny, minx),
    );
    if (_mapCameraViewBounds == null ||
        _mapCameraViewBounds != newCameraViewBounds) {
      _mapCameraViewBounds = newCameraViewBounds;

      if (mapControllerCompleter.isCompleted == false) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _mapCameraViewBounds == null) return;

        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            _mapCameraViewBounds!,
            30,
          ),
        );
      });
    }
  }

  bool isDarkMapThemeSelected = false;
  List<Marker> mapRouteMarkers = List.empty(growable: true);
  List<Marker> avaliableTaxiMarkers = List.empty(growable: true);

  final mapControllerCompleter = Completer<GoogleMapController>();
  GoogleMapController? mapController;
  CameraPosition? _latestCameraPosition;

  void autocompleteAddress(bool isFromAdr, Location searchLocation) async {
    final Prediction? p = await showSearch<Prediction?>(
        context: context,
        delegate: AddressSearch(searchLocation: searchLocation),
        query: (isFromAdr ? from : to)?.mainText ?? '');
    if (p != null) {
      PlacesDetailsResponse placeDetails = await apiGooglePlaces
          .getDetailsByPlaceId(p.placeId!, fields: [
        "address_component",
        "geometry",
        "type",
        "adr_address",
        "formatted_address"
      ]);

      if (!mounted) return;

      final placeAddress = ResolvedAddress(
          location: placeDetails.result.geometry!.location,
          mainText: p.structuredFormatting?.mainText ??
              placeDetails.result.addressComponents.join(','),
          secondaryText: p.structuredFormatting?.secondaryText ?? '');

      setState(() {
        if (isFromAdr) {
          from = placeAddress;
        } else {
          to = placeAddress;
        }
      });

      await recalcRoute();
      adjustMapViewBounds();
      if (mounted) setState(() {});
    }
  }

  void startNewTrip(BuildContext context) async {
    final newTrip = TripDataEntity(
        from: from!,
        to: to!,
        polyline: tripPolyline!,
        distanceMeters: tripDistanceMeters,
        distanceText: tripDistanceText,
        mapLatLngBounds: _mapCameraViewBounds!,
        cameraPosition: _latestCameraPosition,
        fare: tripFare,
        distance: tripDistanceMeters);

    final trip = TripProvider.of(context, listen: false);
    trip.activateTrip(newTrip);
  }

  BitmapDescriptor? fromMarker;
  BitmapDescriptor? toMarker;

  @override
  void initState() {
    from = LocationProvider.of(context, listen: false).currentAddress;
    isDarkMapThemeSelected = false;

    super.initState();
  }

  @override
  void didChangeDependencies() {
    final isDark = ThemeProvider.of(context, listen: false).isDark;
    if (isDark != isDarkMapThemeSelected && mapController != null) {
      mapController!.setMapStyle(ThemeProvider.of(context, listen: false).isDark
          ? googleMapDarkStyle
          : googleMapDefaultStyle);
      isDarkMapThemeSelected = isDark;
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return buildAppScaffold(
      context,
      Column(
        children: [
          Expanded(
            child: GoogleMap(
              onCameraMove: (pos) => _latestCameraPosition = pos,
              initialCameraPosition: CameraPosition(
                  target: LocationProvider.of(context, listen: false)
                      .currentAddress!
                      .toLatLng,
                  zoom: 15),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              scrollGesturesEnabled: true,
              markers: {
                if (from != null &&
                    AssetLoaderProvider.of(context).markerIconFrom != null)
                  Marker(
                    icon: AssetLoaderProvider.of(context).markerIconFrom!,
                    position: from!.toLatLng,
                    markerId: MarkerId(
                        'marker-From${kIsWeb ? DateTime.now().toIso8601String() : ""}'), // Flutter Google Maps for Web does not update marker position properly
                  ),
                if (to != null)
                  Marker(
                    icon: AssetLoaderProvider.of(context).markerIconTo,
                    position: to!.toLatLng,
                    markerId: MarkerId(
                        'marker-To${kIsWeb ? DateTime.now().toIso8601String() : ""}'),
                  ),
              },
              polylines: tripPolyline != null
                  ? <Polyline>{tripPolyline!}
                  : const <Polyline>{},
              onMapCreated: (GoogleMapController controller) {
                mapControllerCompleter.complete(controller);
                mapController = controller;
                if (mounted) {
                  final isDark =
                      ThemeProvider.of(context, listen: false).isDark;
                  if (isDark != isDarkMapThemeSelected) {
                    controller.setMapStyle(
                        ThemeProvider.of(context, listen: false).isDark
                            ? googleMapDarkStyle
                            : googleMapDefaultStyle);
                    isDarkMapThemeSelected = isDark;
                  }
                  setState(() {
                    adjustMapViewBounds();
                  });
                }
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 3,
                  offset: const Offset(0, -3), // changes position of shadow
                ),
              ],
            ),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.person_pin_circle),
                title: Text(
                  from?.mainText ?? "",
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.white)),
                    Text(from?.secondaryText ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 8))
                  ],
                ),
                onTap: () => autocompleteAddress(
                    true,
                    LocationProvider.of(context, listen: false)
                        .currentAddress!
                        .location),
              ),
              const SizedBox(
                height: 4,
              ),
              (to == null)
                  ? ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Điểm đến'),
                      subtitle: const Text(''),
                      onTap: () => autocompleteAddress(
                          false,
                          LocationProvider.of(context, listen: false)
                              .currentAddress!
                              .location),
                    )
                  : ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(
                        to!.mainText,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.white)),
                          Text(to!.secondaryText,
                              overflow: TextOverflow.fade,
                              style: const TextStyle(fontSize: 8))
                        ],
                      ),
                      onTap: () => autocompleteAddress(
                          false,
                          LocationProvider.of(context, listen: false)
                              .currentAddress!
                              .location),
                    ),
              const Divider(height: 1),
              SizedBox(
                  height: 80,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            child: DropdownButton<String>(
                          padding: const EdgeInsets.all(20.0),
                          value: selectedSeatType,
                          icon: const Icon(Icons.local_taxi),
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(color: Colors.black),
                          underline: Container(
                            height: 0,
                            color: Colors.transparent,
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSeatType =
                                  newValue!; // Update the selected value
                              if (newValue == "4 Chỗ") {
                                numberOfSeat = 4;
                              } else {
                                numberOfSeat = 7;
                              }
                              calculateFare();
                            });
                          },
                          items: <String>['4 Chỗ', '7 Chỗ']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        )),
                        Expanded(
                          child: DropdownButton<String>(
                            padding: const EdgeInsets.all(20.0),
                            value: selectedServiceType,
                            icon: const Icon(Icons.currency_pound),
                            iconSize: 24,
                            elevation: 16,
                            style: const TextStyle(color: Colors.black),
                            underline: Container(
                              height: 0,
                              color: Colors.transparent,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedServiceType =
                                    newValue!; // Update the selected value
                                if (newValue == "Tiết kiệm") {
                                  serviceType = 0;
                                } else {
                                  serviceType = 1;
                                }
                                calculateFare();
                              });
                            },
                            items: <String>['Tiết kiệm', 'VIP']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        )
                      ])),
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
                            if (from == null || to == null)
                              Shimmer.fromColors(
                                  baseColor: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .color ??
                                      Colors.black,
                                  highlightColor:
                                      Theme.of(context).colorScheme.secondary,
                                  child: Text(
                                    'Vui lòng chọn điểm đến',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).hintColor),
                                  )),
                            if (from != null &&
                                to != null &&
                                tripDistanceText.isEmpty)
                              Text(
                                'Đang tính toán quãng đường',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            if (from != null &&
                                to != null &&
                                tripDistanceText.isNotEmpty)
                              Text(
                                '$tripDistanceText, $tripFareText',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                          ],
                        ),
                      )),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                            style: ThemeProvider.of(context).roundButtonStyle,
                            onPressed: (tripDistanceText.isEmpty)
                                ? null
                                : () => startNewTrip(context),
                            child: const Row(children: [
                              Icon(Icons.taxi_alert),
                              SizedBox(width: 10),
                              Text('Đặt xe')
                            ])),
                      )
                    ],
                  )),
            ]),
          )
        ],
      ),
    );
  }
}

_NewTripState? _newTripState;
