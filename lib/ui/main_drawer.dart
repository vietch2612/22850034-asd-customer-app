// 22850034 ASD Customer App Flutter

import 'package:flutter/material.dart';
import 'package:customer_app/providers/active_trip.dart';
import 'package:customer_app/providers/location.dart';
import 'package:customer_app/providers/theme.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

Widget mainDrawer(BuildContext context, {bool isLoggedIn = true}) => Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    child: Expanded(
                        child:
                            Lottie.asset('assets/lottie/taxi-animation.json')),
                  ),
                  Text(
                    "HCMUSCab Driver",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.black),
                  ),
                ],
              )),
          ListTile(
            leading: const Icon(Icons.local_taxi),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Toggle theme'),
            onTap: () {
              final tp = Provider.of<ThemeProvider>(context, listen: false);
              tp.isDark = !tp.isDark;
              Navigator.pop(context);
            },
          ),
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  TripProvider.of(context, listen: false).deactivateTrip();
                  LocationProvider.of(context, listen: false).reset();
                });
                Navigator.pop(context);
              },
            ),
          const Divider(
            height: 10,
            thickness: 1,
          ),
        ],
      ),
    );
