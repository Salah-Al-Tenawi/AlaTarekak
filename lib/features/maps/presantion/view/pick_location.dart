import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/maps/data/model/place_suggestion.dart';
import 'package:alatarekak/features/maps/presantion/manger/pick_location/cubit/pick_location_cubit.dart';

class PickLocation extends StatefulWidget {
  const PickLocation({super.key});

  @override
  State<PickLocation> createState() => _PickLocationState();
}

class _PickLocationState extends State<PickLocation> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<PickLocationCubit>().searchByText(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PickLocationCubit, PickLocationState>(
        builder: (context, state) {
          LatLng? selectedPoint;
          String? placeName;
          bool isLoadingPoint = false;
          bool isSearching = false;
          List<PlaceSuggestion> suggestions = [];

          if (state is PickLocationLoading) {
            selectedPoint = state.point;
            isLoadingPoint = true;
          } else if (state is PickLocationLoaded) {
            selectedPoint = state.point;
            placeName = state.placeName;
          } else if (state is PickLocationError) {
            selectedPoint = state.point;
          } else if (state is PickLocationSearchLoading) {
            isSearching = true;
          } else if (state is PickLocationSearchResults) {
            suggestions = state.results;
          }

          return Stack(
            children: [
              // ━━ الخريطة ━━
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(33.5138, 36.2765),
                  initialZoom: 9.2,
                  onTap: (tapPosition, point) {
                    _searchController.clear();
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
                        ),
                      ],
                    ),
                ],
              ),

              // ━━ شريط البحث + النتائج ━━
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16.w,
                right: 16.w,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن موقع...',
                          hintStyle: AppTextStyles.bodySmall
                              .copyWith(color: MyColors.textHint),
                          prefixIcon: isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: MyColors.primary,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.search_rounded,
                                  color: MyColors.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: MyColors.textHint, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<PickLocationCubit>()
                                        .searchByText('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),

                    // ━━ قائمة النتائج ━━
                    if (suggestions.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: suggestions.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 0,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final s = suggestions[index];
                            return InkWell(
                              onTap: () {
                                _searchController.text = s.displayName;
                                context
                                    .read<PickLocationCubit>()
                                    .selectSuggestion(s);
                                _mapController.move(LatLng(s.lat, s.lng), 14);
                                FocusScope.of(context).unfocus();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 18, color: MyColors.accent),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        s.displayName,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: MyColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // ━━ تفاصيل الموقع + زر التأكيد ━━
              if (selectedPoint != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding:
                        EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.r),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoadingPoint)
                          const CircularProgressIndicator(
                              color: MyColors.primary)
                        else if (placeName != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: MyColors.accent, size: 20),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  placeName,
                                  style: AppTextStyles.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 14.h),
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: placeName != null
                                ? () {
                                    final point = selectedPoint!;
                                    final type =
                                        Get.arguments?["type"] ?? "source";
                                    Get.back(result: {
                                      "type": type,
                                      "placeName": placeName,
                                      "lat": point.latitude.toString(),
                                      "lng": point.longitude.toString(),
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'تأكيد الموقع',
                              style: AppTextStyles.buttonLarge,
                            ),
                          ),
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
