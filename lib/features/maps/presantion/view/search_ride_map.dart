import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/maps/presantion/manger/push_ride_map/map_cubit.dart';
import 'package:alatarekak/features/maps/presantion/manger/push_ride_map/map_state.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

class SearchRideMap extends StatefulWidget {
  const SearchRideMap({super.key});

  @override
  State<SearchRideMap> createState() => _SearchRideMapState();
}

class _SearchRideMapState extends State<SearchRideMap> {
  static const _defaultCenter = LatLng(33.5138, 36.2765);
  static const _initialZoom = 9.2;
  static const _markerSize = 40.0;
  static const _polylineStrokeWidth = 4.0;

  late final MapController _mapController;
  late TripFrom tripFrom;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    tripFrom = Get.arguments as TripFrom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocListener<MapCubit, MapState>(
        listenWhen: (previous, current) => current is MapError,
        listener: _handleMapError,
        child: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            final cubit = context.read<MapCubit>();
            final center = cubit.startLocation ?? _defaultCenter;

            return Stack(
              children: [
                _buildMap(center, cubit, state),
                if (state is MapLoaded && state.routes.isNotEmpty)
                  _buildRouteInfoCard(context, state),
                if (state is MapLoaded && state.routes.length > 1)
                  _buildSwitchRouteButton(context, cubit),
                if (state is MapLoading) _buildLoadingIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("الخريطة"),
      centerTitle: true,
      backgroundColor: MyColors.primary,
      foregroundColor: Colors.white,
    );
  }

  void _handleMapError(BuildContext context, MapState state) {
    if (state is MapError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildMap(LatLng center, MapCubit cubit, MapState state) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _initialZoom,
        onTap: (_, point) => cubit.tapOnMap(point),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=QmKE1VFS8taoRXgzkP3S',
          userAgentPackageName: 'com.example.app',
        ),
        if (state is MapLoaded && state.routes.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: state.routes[state.currentRouteIndex],
                color: Colors.blue[700]!,
                strokeWidth: _polylineStrokeWidth,
              ),
            ],
          ),
        MarkerLayer(markers: _buildMarkers(state)),
      ],
    );
  }

  List<Marker> _buildMarkers(MapState state) {
    if (state is! MapLoaded) return [];

    final markers = <Marker>[];
    final start = state.start;
    final end = state.end;

    if (start != null) {
      markers.add(
        Marker(
          point: start,
          width: _markerSize,
          height: _markerSize,
          child: const Icon(Icons.location_pin,
              color: Colors.green, size: _markerSize),
        ),
      );
    }

    if (end != null) {
      markers.add(
        Marker(
          point: end,
          width: _markerSize,
          height: _markerSize,
          child: const Icon(Icons.flag, color: Colors.red, size: _markerSize),
        ),
      );
    }

    return markers;
  }

  Widget _buildRouteInfoCard(BuildContext context, MapLoaded state) {
    final info = state.routeInfos[state.currentRouteIndex];
    final distance = info['distance'] / 1000;
    final duration = info['duration'] / 60;
    tripFrom.startLat = "${state.start!.latitude}";
    tripFrom.startLng = "${state.start!.longitude}";
    tripFrom.endLat = "${state.end!.latitude}";
    tripFrom.endLng = "${state.end!.longitude}";
    tripFrom.distance = distance;
    tripFrom.duration = duration;

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "المسار ${state.currentRouteIndex + 1}/${state.routes.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MyColors.primary,
                    ),
                  ),
                  const Icon(Icons.route, color: MyColors.accent, size: 30),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    Icons.directions_car,
                    "المسافة",
                    "${distance.toStringAsFixed(2)} كم",
                  ),
                  _buildInfoItem(
                    Icons.access_time_filled,
                    "المدة",
                    "${duration.toStringAsFixed(1)} دقيقة",
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsetsGeometry.only(right: 20.w, top: 10.h),
                child: MyButton(
                  onPressed: () {
                    if (tripFrom.startLat != null && tripFrom.endLat != null) {
                      Get.toNamed(RouteName.tripSelectDateAndSeats,
                          arguments: tripFrom);
                    }
                  },
                  color: MyColors.primaryText,
                  width: 130.w,
                  height: 50.h,
                  borderRadius: true,
                  splashcolor: MyColors.primary,
                  child: const Text(
                    "التالي",
                    style: font13boldwhite,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: MyColors.accent, size: 30),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSwitchRouteButton(BuildContext context, MapCubit cubit) {
    return Positioned(
      bottom: 30,
      right: 20,
      child: FloatingActionButton(
        onPressed: () {
          tripFrom.path = cubit.switchRoute();
        },
        backgroundColor: Colors.white,
        elevation: 8,
        child: Icon(Icons.swap_horiz, color: Colors.blue[700], size: 30),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "يتم تحديد الطريق",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              strokeWidth: 3.0,
            ),
            const SizedBox(height: 8),
            const Text(
              "يرجى الانتظار...",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
