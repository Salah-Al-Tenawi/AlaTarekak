class DistanceModel {
  final int meters;
  final double kilometers;

  DistanceModel({
    required this.meters,
    required this.kilometers,
  });

  factory DistanceModel.fromJson(Map<String, dynamic> json) {
    return DistanceModel(
      meters: json['meters'],
      kilometers: json['kilometers'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meters': meters,
      'kilometers': kilometers,
    };
  }
}
