class Lap {
  final int lapNumber;
  final int driverNumber;
  final double? lapDuration;
  final double? sector1Duration;
  final double? sector2Duration;
  final double? sector3Duration;
  final bool isPitOutLap;
  final String? compound;

  const Lap({
    required this.lapNumber,
    required this.driverNumber,
    this.lapDuration,
    this.sector1Duration,
    this.sector2Duration,
    this.sector3Duration,
    this.isPitOutLap = false,
    this.compound,
  });

  factory Lap.fromJson(Map<String, dynamic> json) {
    return Lap(
      lapNumber: json['lap_number'] as int? ?? 0,
      driverNumber: json['driver_number'] as int? ?? 0,
      lapDuration: (json['lap_duration'] as num?)?.toDouble(),
      sector1Duration: (json['duration_sector_1'] as num?)?.toDouble(),
      sector2Duration: (json['duration_sector_2'] as num?)?.toDouble(),
      sector3Duration: (json['duration_sector_3'] as num?)?.toDouble(),
      isPitOutLap: json['is_pit_out_lap'] as bool? ?? false,
      compound: json['compound'] as String?,
    );
  }

  String get formattedLapTime {
    if (lapDuration == null) return '--:--.---';
    final minutes = lapDuration! ~/ 60;
    final seconds = lapDuration! % 60;
    return '$minutes:${seconds.toStringAsFixed(3).padLeft(6, '0')}';
  }
}
