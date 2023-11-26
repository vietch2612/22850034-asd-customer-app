// 22850034 ASD Customer App Flutter

import 'package:flutter/material.dart';
import 'package:customer_app/types/trip.dart';
import 'package:customer_app/providers/active_trip.dart';
import 'package:customer_app/ui/common.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:customer_app/providers/theme.dart';
import 'package:lottie/lottie.dart';

Widget tripFinishedScaffold(BuildContext context) {
  final trip = TripProvider.of(context);

  return buildAppScaffold(
      context,
      SafeArea(
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(getTripStatusDescription(trip.activeTrip!.status),
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Image.asset('assets/logo/logo.png'),
          Text('Vui lòng đánh giá về chuyến đi',
              style: Theme.of(context).textTheme.titleMedium),
          RatingBar.builder(
            initialRating: 3,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {},
          ),
          // tripFromTo(context, trip.activeTrip!),
          Expanded(
            child: Container(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: ElevatedButton(
                style: ThemeProvider.of(context).roundButtonStyle,
                onPressed: () => trip.deactivateTrip(),
                child: const Text('Hoàn thành')),
          )
        ],
      )));
}
