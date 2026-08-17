import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/maps/data/model/place_suggestion.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit(this.mapsRepo) : super(MapInitial());

  final MapRepoIm mapsRepo;

  LatLng? startLocation;
  LatLng? endLocation;
  String? startPlaceName;
  String? endPlaceName;
  List<List<LatLng>> allRoutes = [];
  List<Map<String, dynamic>> routeInfos = [];
  int currentRouteIndex = 0;
  bool _searchingForStart = true;

  void setSearchMode(bool forStart) {
    _searchingForStart = forStart;
  }

  Future<void> searchPlaces(String query) async {
    if (query.trim().length < 2) return;
    final result = await mapsRepo.searchPlaces(query);
    result.fold(
      (_) {},
      (suggestions) =>
          emit(MapSearchResults(suggestions, isForStart: _searchingForStart)),
    );
  }

  void selectFromSearch(PlaceSuggestion place) {
    final point = LatLng(place.lat, place.lng);
    pendingPoint = null;

    if (_searchingForStart) {
      startLocation = point;
      startPlaceName = place.displayName;
      // الوجهة تبقى كما هي: تغيير نقطة الانطلاق تصحيحٌ لا بداية جديدة،
      // وكانت تُمسح هنا فيضطر السائق لإعادة اختيار وجهته من الصفر.
      _clearRoutes();
      if (endLocation != null) {
        _fetchRoutes();
      } else {
        _emitCurrent();
      }
      return;
    }

    endLocation = point;
    endPlaceName = place.displayName;

    // اختيار الوجهة قبل الانطلاق وارد تماماً — ورسم المسار حينها كان
    // يمرّ startLocation! فينهار التطبيق. نكتفي بإظهار الوجهة وننتظر
    // تحديد نقطة الانطلاق.
    if (startLocation == null) {
      _emitCurrent();
      return;
    }
    _fetchRoutes();
  }

  /// نقطة بانتظار التأكيد — تُحرَّك بأي نقرة جديدة بلا رسم مسار.
  LatLng? pendingPoint;

  /// النقر على الخريطة يقترح نقطة فقط ولا يلتزم بها.
  ///
  /// كان النقر يثبّت النقطة فوراً ويرسم المسار، فمن أخطأ في نقطة
  /// الانطلاق كان عليه إكمال اختيار الوجهة وانتظار رسم المسار ثم النقر
  /// من جديد ليعيد الكرّة. الآن تتحرّك النقطة المقترحة بكل نقرة، ولا
  /// يقع أي طلب شبكة حتى يضغط «تأكيد».
  void tapOnMap(LatLng point) {
    pendingPoint = point;
    _emitCurrent();
  }

  /// تثبيت النقطة المقترحة في خانتها، ورسم المسار متى اكتملت النقطتان.
  void confirmPending() {
    final point = pendingPoint;
    if (point == null) return;

    if (_isChoosingStart) {
      startLocation = point;
      startPlaceName = null; // اسم جديد يُجلب عند رسم المسار
    } else {
      endLocation = point;
      endPlaceName = null;
    }
    pendingPoint = null;

    if (startLocation != null && endLocation != null) {
      _fetchRoutes();
    } else {
      _emitCurrent();
    }
  }

  /// إلغاء الاقتراح والإبقاء على ما ثُبِّت سابقاً.
  void cancelPending() {
    pendingPoint = null;
    _emitCurrent();
  }

  /// إعادة اختيار نقطة الانطلاق وحدها — الوجهة تبقى كما هي.
  void resetStart() {
    startLocation = null;
    startPlaceName = null;
    pendingPoint = null;
    _clearRoutes();
    _emitCurrent();
  }

  /// إعادة اختيار الوجهة وحدها — نقطة الانطلاق تبقى كما هي.
  void resetEnd() {
    endLocation = null;
    endPlaceName = null;
    pendingPoint = null;
    _clearRoutes();
    _emitCurrent();
  }

  /// المسار المرسوم لم يعد يعني شيئاً بعد تغيير أي من طرفيه.
  void _clearRoutes() {
    allRoutes = [];
    routeInfos = [];
    currentRouteIndex = 0;
  }

  /// الخانة التي تنتظر التحديد الآن.
  bool get _isChoosingStart => startLocation == null;

  void _emitCurrent() {
    emit(MapLoaded(
      routes: allRoutes,
      routeInfos: routeInfos,
      currentRouteIndex: currentRouteIndex,
      start: startLocation,
      end: endLocation,
      startName: startPlaceName,
      endName: endPlaceName,
      pending: pendingPoint,
      pendingIsStart: _isChoosingStart,
    ));
  }

  int switchRoute() {
    if (allRoutes.length > 1) {
      currentRouteIndex = (currentRouteIndex + 1) % allRoutes.length;
      emit(MapLoaded(
        routes: allRoutes,
        routeInfos: routeInfos,
        currentRouteIndex: currentRouteIndex,
        start: startLocation,
        end: endLocation,
        startName: startPlaceName,
        endName: endPlaceName,
      ));
    }
    return currentRouteIndex;
  }

  void resetAll() {
    startLocation = null;
    endLocation = null;
    startPlaceName = null;
    endPlaceName = null;
    allRoutes = [];
    routeInfos = [];
    currentRouteIndex = 0;
    emit(MapInitial());
  }

  Future<void> _fetchRoutes() async {
    // حارس: لا مسار بلا طرفين. بدونه كان `startLocation!` أدناه يرمي
    // استثناء null ويُسقط التطبيق.
    if (startLocation == null || endLocation == null) {
      _emitCurrent();
      return;
    }
    emit(MapLoading());

    // Resolve names for tap-placed pins (no name from search)
    final futures = <Future>[];
    if (startPlaceName == null && startLocation != null) {
      futures.add(mapsRepo
          .getPlaceName(startLocation!)
          .then((r) => r.fold((_) {}, (n) => startPlaceName = n)));
    }
    if (endPlaceName == null && endLocation != null) {
      futures.add(mapsRepo
          .getPlaceName(endLocation!)
          .then((r) => r.fold((_) {}, (n) => endPlaceName = n)));
    }
    if (futures.isNotEmpty) await Future.wait(futures);

    final double dist = _calcDistanceKm(startLocation!, endLocation!);
    final response = dist < 100
        ? await mapsRepo.fetchRouteBYOpenRouteServices(
            startLocation!, endLocation!)
        : await mapsRepo.fetchRouteBYgraphHopper(
            startLocation!, endLocation!);

    response.fold(
      (failure) => emit(MapError(HandelErorrMessage.routeOptions(failure.message))),
      (routes) {
        if (routes.isEmpty) {
          emit(MapError("لم يتم العثور على مسارات"));
        } else {
          allRoutes = routes.map((r) => r.path).toList();
          routeInfos = routes
              .map((r) => {'distance': r.distance, 'duration': r.duration})
              .toList();
          currentRouteIndex = 0;
          emit(MapLoaded(
            routes: allRoutes,
            routeInfos: routeInfos,
            currentRouteIndex: 0,
            start: startLocation,
            end: endLocation,
            startName: startPlaceName,
            endName: endPlaceName,
          ));
        }
      },
    );
  }

  double _calcDistanceKm(LatLng a, LatLng b) {
    const Distance d = Distance();
    return d(a, b) / 1000;
  }
}
