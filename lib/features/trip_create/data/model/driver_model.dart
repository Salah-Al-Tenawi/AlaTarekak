class DriverModel {
  final int id;
  final String name;
  final String? avatar;
  final int rating;

  DriverModel({
    required this.id,
    required this.name,
    this.avatar,
    required this.rating,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      rating: json['rating'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'rating': rating,
    };
  }
}
