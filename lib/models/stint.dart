class Stint {
  final int driverNumber;
  final int stintNumber;
  final String? compound;
  final int? lapStart;
  final int? lapEnd;
  final int? tyreAgeAtStart;

  const Stint({
    required this.driverNumber,
    required this.stintNumber,
    this.compound,
    this.lapStart,
    this.lapEnd,
    this.tyreAgeAtStart,
  });

  factory Stint.fromJson(Map<String, dynamic> json) {
    return Stint(
      driverNumber: json['driver_number'] as int? ?? 0,
      stintNumber: json['stint_number'] as int? ?? 0,
      compound: json['compound'] as String?,
      lapStart: json['lap_start'] as int?,
      lapEnd: json['lap_end'] as int?,
      tyreAgeAtStart: json['tyre_age_at_start'] as int?,
    );
  }

  int get lapCount => (lapEnd ?? 0) - (lapStart ?? 0) + 1;
}
