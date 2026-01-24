import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/features/maps/presantion/manger/cubit/trip_details_map_cubit.dart';
import 'package:get/get.dart';

class RouteMapView extends StatefulWidget {
  const RouteMapView({super.key});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  late final double startLat;
  late final double startLng;
  late final double endLat;
  late final double endLng;
  late final int routeIndex;

  late final TripDetailsMapCubit mapCubit;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>;
    startLat = args['startLat'];
    startLng = args['startLng'];
    endLat = args['endLat'];
    endLng = args['endLng'];
    routeIndex = args['routeIndex'];
    mapCubit = context.read<TripDetailsMapCubit>();
    mapCubit.fetchRouteByIndex(
      LatLng(startLat, startLng),
      LatLng(endLat, endLng),
      routeIndex,
    );
  }

  @override
  void dispose() {
    mapCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: mapCubit,
      child: Scaffold(
        appBar: AppBar(title: const Text("خريطة الرحلة")),
        body: BlocBuilder<TripDetailsMapCubit, TripDetailsMapState>(
          builder: (context, state) {
            if (state is TripDetailsMapLoading ||
                state is TripDetailsMapInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TripDetailsMapError) {
              return Center(child: Text("خطأ: ${state.message}"));
            } else if (state is TripDetailsMapLoaded) {
              return FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(startLat, startLng),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=QmKE1VFS8taoRXgzkP3S",
                    userAgentPackageName: "com.example.app",
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: state.path,
                        strokeWidth: 5,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(startLat, startLng),
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.location_pin,
                            color: Colors.green, size: 40),
                      ),
                      Marker(
                        point: LatLng(endLat, endLng),
                        width: 50,
                        height: 50,
                        child:
                            const Icon(Icons.flag, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
