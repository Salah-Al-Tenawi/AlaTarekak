import 'package:alatarekak/core/utils/functions/json_parse.dart';

class BookingModel {
  final int id;
  final String userName;
  final int userId;
  final String? avatar;
  final double rating;
  final int seats;
  final String status;
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
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // الراكب يصل تحت `user` في مسار، وتحت `passenger` في
    // `GET /rides/{id}/passangers` — وقراءة الأول وحده كانت تُظهر بطاقات
    // بلا اسم ولا صورة رغم وصولهما كاملين.
    final user = asMap(pick(json, const ['user', 'passenger'])) ??
        const <String, dynamic>{};

    return BookingModel(
        id: asInt(json['id']) ?? 0,
        userName: asString(pick(user, const ['name', 'full_name'])) ?? "",
        userId: asInt(user['id']) ?? 0,
        avatar: asString(user['avatar']),
        rating: asDouble(user['rating']) ?? 0,
        seats: asInt(json['seats']) ?? 0,
        status: asString(json['status']) ?? "",
        totaPrice: asInt(json['total_price']) ?? 0,
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
