import 'package:alatarekak/core/utils/functions/json_parse.dart';

class BookingModel {
  final int id;
  final String userName;
  final int userId;
  final String? avatar;
  final double rating;
  final int seats;
  final String status;

  /// إجمالي الحجز — من الخادم إن أرسله، وإلا سعر المقعد × عدد المقاعد.
  final int totaPrice;
  final String bookingat;
  final String numberPhone;

  BookingModel(
      {required this.id,
      required this.userName,
      required this.userId,
      required this.avatar,
      required this.rating,
      required this.seats,
      required this.status,
      required this.totaPrice,
      required this.bookingat,
      required this.numberPhone});

  /// كان الاحتياطي هنا `?? ""` على حقول رقمية — وهو لا يقي من الغياب بل
  /// يحوّله إلى انهيار نوعي عند أول حجز ينقصه حقل. الاحتياطي الآن من
  /// النوع نفسه، و`user` قد يغيب كاملاً فيُقرأ ككائن فارغ.
  ///
  /// [pricePerSeat] سعر مقعد الرحلة الحاضنة — يُحسب به الإجمالي حين لا
  /// يرسله الخادم مع الحجز. انظر [totaPrice].
  factory BookingModel.fromJson(Map<String, dynamic> json,
      {int? pricePerSeat}) {
    // الراكب يصل تحت `user` في مسار، وتحت `passenger` في
    // `GET /rides/{id}/passengers` — وقراءة الأول وحده كانت تُظهر بطاقات
    // بلا اسم ولا صورة رغم وصولهما كاملين.
    final user = asMap(pick(json, const ['user', 'passenger'])) ??
        const <String, dynamic>{};

    final seats = asInt(json['seats']) ?? 0;

    // `GET /rides/{id}/passengers` لا يرسل `total_price` إطلاقاً — الحجز
    // فيه معرّف وحالة ومقاعد ورقم تواصل وراكب، لا أكثر. فكانت كل بطاقة
    // في «حجوزات رحلتي» تعرض «0 ل.س» مهما بلغ سعر المقعد. الإجمالي
    // يُحسب حينها من سعر مقعد الرحلة، والمرسَل من الخادم يبقى المرجع.
    final sent = asInt(pick(json, const ['total_price', 'total_amount']));
    final total =
        (sent == null || sent == 0) ? (pricePerSeat ?? 0) * seats : sent;

    return BookingModel(
        id: asInt(json['id']) ?? 0,
        userName: asString(pick(user, const ['name', 'full_name'])) ?? "",
        userId: asInt(user['id']) ?? 0,
        avatar: asString(user['avatar']),
        rating: asDouble(user['rating']) ?? 0,
        seats: seats,
        status: asString(json['status']) ?? "",
        totaPrice: total,
        bookingat: asString(json['booked_at']) ?? "",
        // رقم التواصل حقل في الحجز لا في الراكب في المسار الجديد
        numberPhone: asString(pick(json, const ['communication_number'])) ??
            asString(user['communication_number']) ??
            "");
  }
}

// "bookings": [
//             {
//                 "id": 3,
//                 "user": {
//                     "id": 4,
//                     "name": "صلاح التيناوي",
//                     "avatar": null,
//                     "rating": 0
//                 },
//                 "seats": 1,
//                 "status": "pending",
//                 "booked_at": "2025-08-13T21:52:11+00:00",
//                 "total_price": 1000
//             },
//             {
//                 "id": 4,
//                 "user": {
//                     "id": 3,
//                     "name": "صلاح التيناوي",
//                     "avatar": null,
//                     "rating": 0
//                 },
//                 "seats": 1,
//                 "status": "pending",
//                 "booked_at": "2025-08-13T21:54:38+00:00",
//                 "total_price": 1000
//             }
//         ]
