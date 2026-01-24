class TripFrom {
  String? startLat;
  String? endLat;
  String? startLng;
  String? endLng;
  int path;
  String? date;
  int numberSeats;
  int price;
  double recomandedPrice;
  String? numberPhone;
  String bookingType;
  bool reverseTripRoute;
  dynamic distance;
  dynamic duration;
  String cashType;
  String notes;

  TripFrom(
      {this.startLat,
      this.startLng,
      this.endLat,
      this.endLng,
      this.path = 0,
      this.date,
      this.numberSeats = 0,
      this.price = 0,
      this.recomandedPrice = 0,
      this.numberPhone,
      this.reverseTripRoute = false,
      this.bookingType = "Direct",
      this.distance,
      this.duration,
      this.cashType = "cash" ,
      this.notes =""});
}
