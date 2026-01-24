class CarEntity {
  final String? type;
  final String? color;
  final int? seats;
  final bool hasRadio;
  final bool allowsSmoking;
  final String? image;

  const CarEntity({
    this.type,
    this.color,
    this.seats,
    this.hasRadio = false,
    this.allowsSmoking = false,
    this.image,
  });

  CarEntity copyWith({
    String? type,
    String? color,
    int? seats,
    bool? hasRadio,
    bool? allowsSmoking,
    String? image,
  }) {
    return CarEntity(
      type: type ?? this.type,
      color: color ?? this.color,
      seats: seats ?? this.seats,
      hasRadio: hasRadio ?? this.hasRadio,
      allowsSmoking: allowsSmoking ?? this.allowsSmoking,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return 'CarEntity(type: $type, color: $color, seats: $seats, hasRadio: $hasRadio, allowsSmoking: $allowsSmoking, image: $image)';
  }
}
