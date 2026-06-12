import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/maps/data/model/place_suggestion.dart';
import 'package:alatarekak/features/maps/presantion/manger/push_ride_map/map_cubit.dart';
import 'package:alatarekak/features/maps/presantion/manger/push_ride_map/map_state.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

class PushRideMap extends StatefulWidget {
  const PushRideMap({super.key});

  @override
  State<PushRideMap> createState() => _PushRideMapState();
}

class _PushRideMapState extends State<PushRideMap> {
  static const _defaultCenter = LatLng(33.5138, 36.2765);
  static const _initialZoom = 9.0;

  late final MapController _mapController;
  late TripFrom _tripFrom;

  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _startFocus = FocusNode();
  final _endFocus = FocusNode();

  List<PlaceSuggestion> _suggestions = [];
  bool _showStartSuggestions = false;
  bool _showEndSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    try {
      _tripFrom = Get.arguments as TripFrom;
    } catch (_) {
      _tripFrom = TripFrom();
    }

    _startFocus.addListener(() {
      if (_startFocus.hasFocus) {
        context.read<MapCubit>().setSearchMode(true);
        setState(() {
          _showStartSuggestions = true;
          _showEndSuggestions = false;
        });
      }
    });

    _endFocus.addListener(() {
      if (_endFocus.hasFocus) {
        context.read<MapCubit>().setSearchMode(false);
        setState(() {
          _showEndSuggestions = true;
          _showStartSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _startFocus.dispose();
    _endFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, bool isStart) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 2) {
        context.read<MapCubit>().searchPlaces(query);
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  void _selectSuggestion(PlaceSuggestion place, bool isStart) {
    final cubit = context.read<MapCubit>();
    cubit.setSearchMode(isStart);
    cubit.selectFromSearch(place);

    final shortName = place.displayName.split(',').first;
    if (isStart) {
      _startController.text = shortName;
    } else {
      _endController.text = shortName;
    }

    setState(() {
      _suggestions = [];
      _showStartSuggestions = false;
      _showEndSuggestions = false;
    });
    FocusScope.of(context).unfocus();
    _mapController.move(LatLng(place.lat, place.lng), 11.0);
  }

  void _dismissSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showStartSuggestions = false;
      _showEndSuggestions = false;
      _suggestions = [];
    });
  }

  void _onConfirm(MapLoaded state) {
    _tripFrom
      ..startLat = '${state.start!.latitude}'
      ..startLng = '${state.start!.longitude}'
      ..endLat = '${state.end!.latitude}'
      ..endLng = '${state.end!.longitude}'
      ..startName = state.startName
      ..endName = state.endName
      ..distance =
          (state.routeInfos[state.currentRouteIndex]['distance'] as num) / 1000
      ..duration =
          (state.routeInfos[state.currentRouteIndex]['duration'] as num) / 60
      ..path = state.currentRouteIndex;

    Get.toNamed(RouteName.tripCreateWizard, arguments: _tripFrom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BlocConsumer<MapCubit, MapState>(
        listener: (context, state) {
          if (state is MapError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: MyColors.error,
            ));
          }
          if (state is MapSearchResults) {
            setState(() => _suggestions = state.suggestions);
          }
          if (state is MapLoaded) {
            if (state.start != null && state.end != null) {
              final bounds =
                  LatLngBounds.fromPoints([state.start!, state.end!]);
              _mapController.fitCamera(
                CameraFit.bounds(
                    bounds: bounds, padding: const EdgeInsets.all(80)),
              );
            } else if (state.start != null) {
              _mapController.move(state.start!, 12.0);
            }
            // clear end field if reset
            if (state.end == null && _endController.text.isNotEmpty) {
              _endController.clear();
            }
          }
          if (state is MapInitial) {
            _startController.clear();
            _endController.clear();
          }
        },
        builder: (context, state) {
          final cubit = context.read<MapCubit>();
          final center = cubit.startLocation ?? _defaultCenter;
          final showRoutePanel =
              state is MapLoaded && state.routes.isNotEmpty;
          final showHint = state is MapInitial;

          return Stack(
            children: [
              _buildMap(center, cubit, state),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(state, cubit),
              ),
              if (state is MapLoading) _buildLoadingOverlay(),
              if (showHint) _buildHintBadge(),
              if (showRoutePanel)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildRoutePanel(state, cubit),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Map ────────────────────────────────────────────────────────────────────

  Widget _buildMap(LatLng center, MapCubit cubit, MapState state) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _initialZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, point) {
          _dismissSearch();
          cubit.tapOnMap(point);
        },
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
                color: MyColors.primary,
                strokeWidth: 4.0,
              ),
            ],
          ),
        MarkerLayer(markers: _buildMarkers(state)),
      ],
    );
  }

  List<Marker> _buildMarkers(MapState state) {
    if (state is! MapLoaded) return const [];
    return [
      if (state.start != null)
        Marker(
          point: state.start!,
          width: 30,
          height: 30,
          child: _MapPin(color: MyColors.success, icon: Icons.my_location),
        ),
      if (state.end != null)
        Marker(
          point: state.end!,
          width: 30,
          height: 30,
          child: _MapPin(color: MyColors.accent, icon: Icons.flag_rounded),
        ),
    ];
  }

  // ─── Top overlay (back + step badge + search card + suggestions) ────────────

  Widget _buildTopOverlay(MapState state, MapCubit cubit) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: () => Get.back(),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _StepBadge(label: "الخطوة 1 من 4 — تحديد المسار"),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _SearchCard(
              startController: _startController,
              endController: _endController,
              startFocus: _startFocus,
              endFocus: _endFocus,
              onStartChanged: (q) => _onSearchChanged(q, true),
              onEndChanged: (q) => _onSearchChanged(q, false),
              onClearStart: () {
                _startController.clear();
                cubit.resetAll();
              },
              onClearEnd: () => _endController.clear(),
            ),
            if (_suggestions.isNotEmpty &&
                (_showStartSuggestions || _showEndSuggestions))
              _SuggestionsList(
                suggestions: _suggestions,
                isForStart: _showStartSuggestions,
                onSelect: (place) =>
                    _selectSuggestion(place, _showStartSuggestions),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Route info panel ───────────────────────────────────────────────────────

  Widget _buildRoutePanel(MapLoaded state, MapCubit cubit) {
    final info = state.routeInfos[state.currentRouteIndex];
    final distKm = (info['distance'] as num) / 1000;
    final durationMin = (info['duration'] as num) / 60;

    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowMedium,
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MyColors.surfaceAlt,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RouteInfoItem(
                icon: Icons.route_outlined,
                label: "المسافة",
                value: "${distKm.toStringAsFixed(1)} كم",
                color: MyColors.primary,
              ),
              Container(width: 1, height: 50, color: MyColors.divider),
              _RouteInfoItem(
                icon: Icons.timer_outlined,
                label: "المدة",
                value: "${durationMin.toStringAsFixed(0)} دقيقة",
                color: MyColors.accent,
              ),
              if (state.routes.length > 1) ...[
                Container(width: 1, height: 50, color: MyColors.divider),
                _RouteInfoItem(
                  icon: Icons.swap_calls_rounded,
                  label: "تغيير المسار",
                  value: "${state.currentRouteIndex + 1}/${state.routes.length}",
                  color: MyColors.blue,
                  onTap: () => _tripFrom.path = cubit.switchRoute(),
                ),
              ],
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: () => _onConfirm(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
              label: Text("تأكيد المسار والمتابعة",
                  style: AppTextStyles.buttonLarge),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black26,
        child: Center(
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(MyColors.primary),
                  strokeWidth: 3,
                ),
                SizedBox(height: 12.h),
                Text("جاري تحديد المسار...",
                    style: AppTextStyles.labelMedium
                        .copyWith(color: MyColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintBadge() {
    return Positioned(
      bottom: 30.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: MyColors.primary.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_outlined,
                color: Colors.white, size: 18),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "انقر على الخريطة أو ابحث في الأعلى لتحديد نقطة الانطلاق",
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _MapPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: MyColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: MyColors.shadowMedium, blurRadius: 6)
          ],
        ),
        child: Icon(icon, size: 18, color: MyColors.primary),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final String label;
  const _StepBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: MyColors.shadowMedium, blurRadius: 6)
        ],
      ),
      child: Text(label,
          style:
              AppTextStyles.labelMedium.copyWith(color: MyColors.primary),
          textAlign: TextAlign.center),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final FocusNode startFocus;
  final FocusNode endFocus;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final VoidCallback onClearStart;
  final VoidCallback onClearEnd;

  const _SearchCard({
    required this.startController,
    required this.endController,
    required this.startFocus,
    required this.endFocus,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onClearStart,
    required this.onClearEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MyColors.border),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowMedium,
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const _RouteConnector(),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              children: [
                _SearchField(
                  controller: startController,
                  focusNode: startFocus,
                  hint: "من أين تنطلق؟",
                  onChanged: onStartChanged,
                  onClear: onClearStart,
                ),
                Divider(height: 1, color: MyColors.divider),
                _SearchField(
                  controller: endController,
                  focusNode: endFocus,
                  hint: "إلى أين تتجه؟",
                  onChanged: onEndChanged,
                  onClear: onClearEnd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Start dot → dotted line → destination pin, like mainstream ride apps.
class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.radio_button_checked, color: MyColors.success, size: 18),
        ...List.generate(
          3,
          (_) => Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 2.5),
            decoration: BoxDecoration(
              color: MyColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Icon(Icons.location_on_rounded, color: MyColors.accent, size: 20),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  AppTextStyles.bodyMedium.copyWith(color: MyColors.textHint),
              border: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 13.h),
            ),
          ),
        ),
        if (controller.text.isNotEmpty)
          GestureDetector(
            onTap: onClear,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: MyColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 14, color: MyColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final List<PlaceSuggestion> suggestions;
  final bool isForStart;
  final ValueChanged<PlaceSuggestion> onSelect;

  const _SuggestionsList({
    required this.suggestions,
    required this.isForStart,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      constraints: BoxConstraints(maxHeight: 220.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyColors.border),
        boxShadow: [
          BoxShadow(color: MyColors.shadowMedium, blurRadius: 10)
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        itemCount: suggestions.length,
        separatorBuilder: (context, i) => Divider(
            height: 1,
            color: MyColors.divider,
            indent: 16,
            endIndent: 16),
        itemBuilder: (_, i) {
          final place = suggestions[i];
          return ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isForStart
                    ? MyColors.successLight
                    : MyColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.place_outlined,
                color: isForStart ? MyColors.success : MyColors.accent,
                size: 16,
              ),
            ),
            title: Text(
              place.displayName.split(',').first,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              place.displayName,
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSelect(place),
          );
        },
      ),
    );
  }
}

class _RouteInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _RouteInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          SizedBox(height: 4.h),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary)),
          SizedBox(height: 2.h),
          Text(value,
              style: AppTextStyles.labelLarge.copyWith(
                  color: MyColors.textPrimary,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
