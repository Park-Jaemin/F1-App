class CarLocation {
  final DateTime date;
  final int driverNumber;
  final double x;
  final double y;

  const CarLocation({
    required this.date,
    required this.driverNumber,
    required this.x,
    required this.y,
  });

  factory CarLocation.fromJson(Map<String, dynamic> json) {
    return CarLocation(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      driverNumber: (json['driver_number'] as num?)?.toInt() ?? 0,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }
}
