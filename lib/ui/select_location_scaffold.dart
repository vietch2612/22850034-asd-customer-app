// 22850034 ASD Customer App Flutter

import 'package:flutter/material.dart';
import 'package:customer_app/api/google_api.dart';
import 'package:customer_app/types/resolved_address.dart';
import 'package:customer_app/ui/address_search.dart';
import 'package:customer_app/providers/location.dart';
import 'package:customer_app/ui/common.dart';

import 'package:google_maps_webservice/places.dart';
import 'package:lottie/lottie.dart';

class LocationScaffold extends StatelessWidget {
  LocationScaffold({Key? key}) : super(key: key);

  final homeAddress = ResolvedAddress(
      location: Location(lat: 10.8428625, lng: 106.8346228),
      mainText: "Vinhomes Grand Park - Origami S7.01",
      secondaryText: "Long Bình, Hồ Chí Minh, VN");

  void _setDemoLocation(BuildContext context, ResolvedAddress address) {
    final locProvider = LocationProvider.of(context, listen: false);
    locProvider.currentAddress = address;
  }

  void _selectCurrentLocation(BuildContext context) async {
    final Prediction? prd = await showSearch<Prediction?>(
        context: context, delegate: AddressSearch(), query: '');

    if (prd != null) {
      PlacesDetailsResponse placeDetails = await apiGooglePlaces
          .getDetailsByPlaceId(prd.placeId!, fields: [
        "address_component",
        "geometry",
        "type",
        "adr_address",
        "formatted_address"
      ]);

      final address = ResolvedAddress(
          location: placeDetails.result.geometry!.location,
          mainText: prd.structuredFormatting?.mainText ??
              placeDetails.result.addressComponents.join(','),
          secondaryText: prd.structuredFormatting?.secondaryText ?? '');

      // ignore: use_build_context_synchronously
      final locProvider = LocationProvider.of(context, listen: false);
      locProvider.currentAddress = address;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool pendingDetermineLocation =
        LocationProvider.of(context).pendingDetermineCurrentLocation;
    return buildAppScaffold(
        context,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(left: 64, top: 8),
              child: Text(
                "HCMUS CAB",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Expanded(child: Image.asset('assets/logo/logo.png')),
            if (pendingDetermineLocation) ...[
              const LinearProgressIndicator(),
              const Text('Finding your location...'),
            ],
            if (!pendingDetermineLocation) ...[
              Text(
                'Vui lòng chọn điểm đón',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('S701 Vinhomes Grand Park'),
                subtitle: const Text("Long Binh, Thu Duc City"),
                onTap: () => _setDemoLocation(context, homeAddress),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('HCMUS'),
                subtitle:
                    const Text("225 Nguyen Van Cu, Ward 5, Ho Chi Minh City"),
                onTap: () => _setDemoLocation(context, homeAddress),
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Tìm địa chỉ'),
                onTap: () => _selectCurrentLocation(context),
              ),
              ListTile(
                leading: const Icon(Icons.gps_fixed),
                title: const Text('Sử dụng toạ độ hiện tại'),
                onTap: () => LocationProvider.of(context, listen: false)
                    .determineCurrentLocation(),
              )
            ],
          ]),
        ),
        isLoggedIn: false);
  }
}
