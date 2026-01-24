class BookingModel {
  final int id;
  final String userName;
  final int userId;
  final String? avatar;
  final int rating;
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

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
        id: json['id'],
        userName: json['user']['name'] ?? "",
        userId: json['user']['id'] ?? "",
        avatar: json['user']['avatar'],
        rating: json['user']['rating'] ?? "",
        seats: json['seats'] ?? "",
        status: json['status'] ?? "",
        totaPrice: json['total_price'] ?? "",
        bookingat: json['booked_at'] ?? "",
        numberPhone: json['user']['communication_number'] ?? "0988626577");
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
