class UserCarEntity {
  final int id;
  final String name;
  final String plateNumber;
  final String? fuelType;
  final String? engineSize;
  final String? image;
  final bool isVerified;
  final String? color;

  const UserCarEntity({
    required this.id,
    required this.name,
    required this.plateNumber,
    this.fuelType,
    this.engineSize,
    this.image,
    this.isVerified = false,
    this.color,
  });
}
