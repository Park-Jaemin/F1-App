class PitStop {
  final int driverNumber;
  final int lapNumber;
  final double? pitDuration;
  final DateTime? date;

  const PitStop({
    required this.driverNumber,
    required this.lapNumber,
    this.pitDuration,
    this.date,
  });

  factory PitStop.fromJson(Map<String, dynamic> json) {
    return PitStop(
      driverNumber: json['driver_number'] as int? ?? 0,
      lapNumber: json['lap_number'] as int? ?? 0,
      pitDuration: (json['pit_duration'] as num?)?.toDouble(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
    );
  }

  String get formattedDuration {
    if (pitDuration == null) return '--.-s';
    return '${pitDuration!.toStringAsFixed(1)}s';
  }
}
