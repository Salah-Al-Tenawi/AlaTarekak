import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/features/maps/presantion/manger/pick_location/cubit/pick_location_cubit.dart';

class PickLocation extends StatelessWidget {
  const PickLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PickLocationCubit, PickLocationState>(
        builder: (context, state) {
          LatLng? selectedPoint;
          String? placeName;
          bool isLoading = false;
          String? error;

          if (state is PickLocationLoading) {
            selectedPoint = state.point;
            isLoading = true;
          } else if (state is PickLocationLoaded) {
            selectedPoint = state.point;
            placeName = state.placeName;
          } else if (state is PickLocationError) {
            selectedPoint = state.point;
            error = state.message;
          }

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(33.5138, 36.2765),
                  initialZoom: 9.2,
                  onTap: (tapPosition, point) {
                    context.read<PickLocationCubit>().selectPoint(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=QmKE1VFS8taoRXgzkP3S',
                    userAgentPackageName: 'com.example.app',
                  ),
                  if (selectedPoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedPoint,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.location_pin,
                            size: 40,
                            color: Colors.red,
                          ),
                        )
                      ],
                    ),
                ],
              ),

              /// --- الأسفل: تفاصيل الموقع + زر التأكيد ---
              if (selectedPoint != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: const Border(
                        top: BorderSide(color: Colors.black12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          const CircularProgressIndicator()
                        else if (placeName != null)
                          Text(
                            "🏠 $placeName",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: selectedPoint != null && placeName != null
                              ? () {
                                  final type =
                                      Get.arguments?["type"] ?? "source";
                                  Get.back(result: {
                                    "type": type,
                                    "placeName": placeName,
                                    "lat": selectedPoint!.latitude.toString(),
                                    "lng": selectedPoint!.longitude.toString(),
                                  });
                                }
                              : null,
                          child: const Text("تأكيد الموقع"),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
