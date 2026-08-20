import 'package:flutter/foundation.dart';

import 'package:alatarekak/core/utils/functions/json_parse.dart';
import 'package:alatarekak/features/trip_create/data/model/booking_model.dart';
import 'package:alatarekak/features/trip_create/data/model/distan_model.dart';
import 'package:alatarekak/features/trip_create/data/model/driver_model.dart';
import 'package:alatarekak/features/trip_create/data/model/duration_model.dart';
import 'package:alatarekak/features/trip_create/data/model/location_model.dart';

/// الرحلة كما تصل من الخادم — بشكليها.
///
/// الخادم يرسل الرحلة بصورتين مختلفتين حسب المسار:
///
/// * **محوَّلة** (البحث وتفاصيل الرحلة): كائنات متداخلة —
///   `driver: {...}`، `pickup: {address, coordinates}`،
///   `distance: {meters, kilometers}`، `departure`.
/// * **خام** (إنشاء الرحلة وبعض المسارات الأخرى): صفّ قاعدة بيانات مسطّح —
///   `driver_id`، `pickup_address` + `pickup_location`، `distance` بالأمتار،
///   `departure_time`، `available_seats`.
///
/// التفكيك يقبل الشكلين لأن الفرق بينهما قرار في الخادم لا في الواجهة،
/// وقد تغيّر أكثر من مرة. ما يستحيل بدونه بناء الرحلة (المعرّف وموعد
/// الانطلاق) يرفع خطأً يسمّي الحقل ويعدّد ما وصل فعلاً — فيُشخَّص أي
/// تغيير لاحق من رسالة واحدة.
class TripModel {
  final int id;
  final DriverModel driver;
  final LocationModel pickup;
  final LocationModel destination;
  final DateTime departure;
  final int seatsAvailable;
  final int seatsBooked;
  final String pricePerSeat;
  final String status;
  final DistanceModel distance;
  final DurationInfoModel duration;
  final String vehicleType;
  final String paymentMethod;
  final String bookingType;
  final String? notes;

  /// اختياري: الصفّ الخام لا يحمل `created_at` دائماً، وهو يُستعمل للعرض
  /// فقط («أُنشئت قبل ساعة») فلا يُبرَّر إسقاط الشاشة لغيابه.
  final DateTime? createdAt;

  final int chosenRouteIndex;
  final String communicationNumber;
  final List<BookingModel> booking;

  /// عدد الحجوزات على الرحلة.
  ///
  /// الصفّ الخام (`GET /rides`) يرسل عدّاداً `bookings_count` بلا قائمة
  /// الحجوزات، والشكل المحوَّل يرسل القائمة بلا عدّاد. كلاهما يجيب عن
  /// السؤال نفسه في بطاقة «رحلاتي»: كم حجزاً على هذه الرحلة. وهو غير
  /// [seatsBooked] — الحجز الواحد قد يحمل أكثر من مقعد.
  final int bookingsCount;

  TripModel({
    required this.id,
    required this.driver,
    required this.pickup,
    required this.destination,
    required this.departure,
    required this.seatsAvailable,
    required this.seatsBooked,
    required this.pricePerSeat,
    required this.status,
    required this.distance,
    required this.duration,
    required this.vehicleType,
    required this.paymentMethod,
    required this.bookingType,
    required this.notes,
    required this.createdAt,
    required this.chosenRouteIndex,
    required this.communicationNumber,
    required this.booking,
    this.bookingsCount = 0,
  });

  /// المفاتيح التي قد تُغلَّف بها رحلة مفردة.
  static const _objectWrappers = ['data', 'ride', 'trip'];

  /// المفاتيح التي قد تُغلَّف بها قائمة رحلات.
  static const _listWrappers = ['data', 'rides', 'trips'];

  /// يزيل المغلَّف إن وُجد: `{status, message, ride: {...}}` وما شابهه.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    for (final key in _objectWrappers) {
      final inner = asMap(json[key]);
      // مُرقِّم Laravel يضع قائمة تحت `data` لا كائناً — ليس مغلَّف رحلة
      if (inner != null && inner['data'] is! List) return inner;
    }
    return json;
  }

  /// يُنبّه في وضع التطوير حين لا يُطابَق حقل مهم بأيّ من أسمائه المعروفة،
  /// فيُقرأ الاسم الفعلي من سطر واحد بدل تخمين المفاتيح.
  static void _warnIfUnread(String field, dynamic value,
      Map<String, dynamic> data) {
    assert(() {
      if (value == null) {
        debugPrint('⚠️ TripModel: «$field» لم يُطابَق. '
            'مفاتيح الرد: ${data.keys.join(', ')}');
      }
      return true;
    }());
  }

  /// المقاعد المحجوزة من قائمة الحجوزات حين لا يرسل الخادم عدّاداً لها.
  ///
  /// رد البحث لا يحمل `seats_booked` إطلاقاً، و`passengers_confirmed` شيء
  /// آخر (عدد من أكّد *انتهاء* الرحلة). فحين تصل قائمة الحجوزات تُجمع
  /// مقاعد الحجوزات القائمة منها بدل عرض صفر مضلِّل.
  static int _bookedFrom(List<dynamic> bookings) {
    var total = 0;
    for (final b in bookings.whereType<Map>()) {
      final status = asString(b['status'])?.toLowerCase() ?? '';
      if (status == 'cancelled' || status == 'rejected') continue;
      total += asInt(b['seats']) ?? 0;
    }
    return total;
  }

  /// قائمة الحجوزات أياً كان موضعها وشكلها.
  ///
  /// ثلاثة أشكال وصلت من الخادم للحقل نفسه:
  ///   • قائمة داخل الرحلة:      `{..., bookings: [...]}`
  ///   • كائن شقيق لـ`data`:      `{data: {...}, bookings: {list: [...]}}`
  ///   • كائن داخل الرحلة:        `{..., bookings: {list: [...]}}`
  ///
  /// الشكل الثاني هو ما يرسله `GET /rides/{id}/passengers`، وكان يضيع
  /// كاملاً: `_unwrap` ينزل إلى `data` فتبقى `bookings` خارجها فلا
  /// تُقرأ — وتظهر شاشة «حجوزات الرحلة» فارغة مهما بلغ عدد الحجوزات.
  static List<dynamic> _bookingsFrom(
      Map<String, dynamic> outer, Map<String, dynamic> data) {
    for (final source in [data['bookings'], outer['bookings']]) {
      final list = asList(source);
      if (list != null) return list;

      final map = asMap(source);
      if (map != null) {
        final inner = asList(pick(map, const ['list', 'data', 'items']));
        if (inner != null) return inner;
      }
    }
    return const [];
  }

  /// ملخّص المقاعد المرسَل مع قائمة الحجوزات، إن وُجد.
  static Map<String, dynamic> _seatSummary(
      Map<String, dynamic> outer, Map<String, dynamic> data) {
    for (final source in [data['bookings'], outer['bookings']]) {
      final map = asMap(source);
      if (map == null) continue;
      final summary = asMap(map['seat_summary']);
      if (summary != null) return summary;
    }
    return const <String, dynamic>{};
  }

  /// المحجوز من الملخّص: المؤكَّد والمعلَّق كلاهما يشغل مقعداً.
  static int? _bookedFromSummary(Map<String, dynamic> summary) {
    final confirmed = asInt(summary['confirmed']);
    final pending = asInt(summary['pending']);
    if (confirmed == null && pending == null) return null;
    return (confirmed ?? 0) + (pending ?? 0);
  }

  static dynamic _bookingsCountFrom(
      Map<String, dynamic> outer, Map<String, dynamic> data) {
    for (final source in [data['bookings'], outer['bookings']]) {
      final map = asMap(source);
      if (map != null && map['total_bookings'] != null) {
        return map['total_bookings'];
      }
    }
    return null;
  }

  /// لتحويل JSON كائن رحلة واحدة
  factory TripModel.fromMap(Map<String, dynamic> json) {
    final data = _unwrap(json);
    final rawBookings = _bookingsFrom(json, data);
    final summary = _seatSummary(json, data);

    // الشكل الغنيّ يجمع المقاعد في كائن `{available, booked, total}`،
    // والمسطّح يبعثرها حقولاً مفردة. والمسار كذلك: `route.index` هنا
    // مقابل `chosen_route_index` هناك.
    final seats = asMap(data['seats']) ?? const <String, dynamic>{};
    final route = asMap(data['route']) ?? const <String, dynamic>{};

    // `driver_id` وحده شكل معروف لا عيب، فلا يُنبَّه عليه
    _warnIfUnread('driver', pick(data, const ['driver', 'driver_id']), data);
    _warnIfUnread(
        'seats',
        seats['available'] ??
            pick(data, const [
              'seats_available',
              'available_seats',
              'remaining_seats',
              'seats_left',
            ]),
        data);

    return TripModel(
      id: requireField(asInt(data['id']), 'TripModel', 'id', data),
      driver: DriverModel.fromAny(pick(data, ['driver', 'driver_id'])),
      pickup: LocationModel.fromTrip(data, 'pickup'),
      destination: LocationModel.fromTrip(data, 'destination'),
      departure: requireField(asDate(pick(data, ['departure', 'departure_time'])),
          'TripModel', 'departure', data),
      seatsAvailable: asInt(seats['available']) ??
          asInt(pick(data, const [
            'seats_available',
            'available_seats',
            'remaining_seats',
            'seats_left',
          ])) ??
          asInt(summary['available']) ??
          0,
      // `seat_summary` يفصل المؤكَّد عن المعلَّق، وكلاهما مقعد محجوز
      seatsBooked: asInt(seats['booked']) ??
          asInt(pick(data, const [
            'seats_booked',
            'booked_seats',
            'reserved_seats',
          ])) ??
          _bookedFromSummary(summary) ??
          _bookedFrom(rawBookings),
      pricePerSeat: asString(data['price_per_seat']) ?? '0',
      status: asString(data['status']) ?? '',
      distance: DistanceModel.fromAny(data['distance']),
      duration: DurationInfoModel.fromAny(data['duration']),
      vehicleType: asString(data['vehicle_type']) ?? '',
      paymentMethod: asString(data['payment_method']) ?? '',
      bookingType: asString(data['booking_type']) ?? '',
      notes: asString(data['notes']),
      createdAt: asDate(data['created_at']),
      chosenRouteIndex:
          asInt(route['index']) ?? asInt(data['chosen_route_index']) ?? 0,
      communicationNumber: asString(data['communication_number']) ?? '',
      booking: rawBookings
          .whereType<Map>()
          .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      bookingsCount: asInt(pick(data, const [
            'bookings_count',
            'booking_count',
            'total_bookings',
          ])) ??
          asInt(_bookingsCountFrom(json, data)) ??
          rawBookings.length,
    );
  }

  static List<TripModel> fromJson(dynamic json) {
    if (json is List) return _mapAll(json);

    if (json is Map<String, dynamic>) {
      for (final key in _listWrappers) {
        final value = json[key];

        final list = asList(value);
        if (list != null) return _mapAll(list);

        // مُرقِّم Laravel: `{rides: {current_page: .., data: [...]}}`
        final paginated = asList(asMap(value)?['data']);
        if (paginated != null) return _mapAll(paginated);
      }
      // رحلة مفردة، مغلَّفة أو غير مغلَّفة — يتكفّل بها `_unwrap`
      return [TripModel.fromMap(json)];
    }

    throw Exception("صيغة JSON غير مدعومة");
  }

  static List<TripModel> _mapAll(List<dynamic> items) => items
      .whereType<Map>()
      .map((e) => TripModel.fromMap(Map<String, dynamic>.from(e)))
      .toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver': driver.toJson(),
      'pickup': pickup.toJson(),
      'destination': destination.toJson(),
      'departure': departure.toIso8601String(),
      'seats_available': seatsAvailable,
      'seats_booked': seatsBooked,
      'price_per_seat': pricePerSeat,
      'status': status,
      'distance': distance.toJson(),
      'duration': duration.toJson(),
      'vehicle_type': vehicleType,
      'payment_method': paymentMethod,
      'booking_type': bookingType,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'chosen_route_index': chosenRouteIndex,
      'communication_number': communicationNumber,
      'bookings_count': bookingsCount,
    };
  }
}
