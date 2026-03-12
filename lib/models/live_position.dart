class LivePosition {
  final DateTime? date;
  final int driverNumber;
  final int position;

  const LivePosition({
    this.date,
    required this.driverNumber,
    required this.position,
  });

  factory LivePosition.fromJson(Map<String, dynamic> json) {
    return LivePosition(
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      driverNumber: (json['driver_number'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}
