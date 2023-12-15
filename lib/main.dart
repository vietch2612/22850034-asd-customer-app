import 'package:customer_app/servivces/auth_service.dart';
import 'package:customer_app/ui/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:touch_indicator/touch_indicator.dart';
import 'package:customer_app/providers/assets_loader.dart';
import 'package:customer_app/providers/location.dart';
import 'package:customer_app/ui/common.dart';
import 'package:customer_app/providers/active_trip.dart';
import 'package:customer_app/providers/theme.dart';

void main() async {
  await dotenv.load();
  final authService = AuthService();

  runApp(MultiProvider(
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
            return LoginPage(authService: authService);
          },
        ),
      ),
    ),
  ));
}
