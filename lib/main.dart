import 'package:flutter/material.dart';
import 'package:customer_app/types/trip.dart';
import 'package:customer_app/ui/active_trip_scaffold.dart';
import 'package:customer_app/providers/assets_loader.dart';
import 'package:customer_app/providers/location.dart';
import 'package:customer_app/ui/new_trip_scaffold.dart';
import 'package:customer_app/ui/common.dart';
import 'package:customer_app/providers/active_trip.dart';
import 'package:customer_app/ui/select_location_scaffold.dart';
import 'package:customer_app/providers/theme.dart';
import 'package:customer_app/ui/trip_finished_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:touch_indicator/touch_indicator.dart';

void main() => runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider<AssetLoaderProvider>(
            create: (_) => AssetLoaderProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(),
        ),
        ChangeNotifierProvider<TripProvider>(
          create: (_) => TripProvider(),
        )
      ],
      child: Consumer<ThemeProvider>(
          builder: (context, ThemeProvider themeProvider, child) => MaterialApp(
              theme: themeProvider.currentThemeData,
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              builder: (context, child) => TouchIndicator(child: child!),
              home: Builder(
                builder: (ctx) {
                  // Get Current Location Provider
                  final locProvider = LocationProvider.of(context);

                  // Get Current Trip Provider
                  final currentTrip = TripProvider.of(context);

                  // if Current location is not known
                  if (!locProvider.isDemoLocationFixed)
                    // show Location Selection screen
                    return LocationScaffold();

                  // else if there is an Active Trip
                  if (currentTrip.isActive) {
                    // and if this trip is finished
                    return tripIsFinished(currentTrip.activeTrip!.status)
                        // show Rate the Trip screen
                        ? tripFinishedScaffold(context)
                        // if not finished - show the trip in progress screen
                        : ActiveTrip();
                  }

                  // else if there is no active trip - display UI for new trip creation
                  return NewTrip();
                },
              ))),
    ));
