import 'package:flutter/material.dart';

import 'package:get/route_manager.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_me/presantion/view/widget/trip_item.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/item_search_trip.dart';

class TripSearchList extends StatefulWidget {
  const TripSearchList({super.key});

  @override
  State<TripSearchList> createState() => _TripSearchListState();
}

class _TripSearchListState extends State<TripSearchList> {
  late final List<TripModel> trips;

  @override
  void initState() {
    trips = Get.arguments as List<TripModel>;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "الرحلات المتاحة",
          style: font20boldgray,
        ),
        backgroundColor: MyColors.primary,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          if (trips.isEmpty) {
            return Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: MyColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.airport_shuttle_outlined,
                      size: 60,
                      color: MyColors.primary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد رحلات متاحة حالياً',
                      style: TextStyle(
                        color: MyColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'حاول تغيير التاريخ أو الموقع للعثور على رحلات أخرى.',
                      style: TextStyle(
                        color: MyColors.secondary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ItemSearchTrip(
            trip: trip,
          );
        },
      ),
    );
  }
}
