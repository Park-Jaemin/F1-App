class RaceControlMessage {
  final DateTime? date;
  final int? driverNumber;
  final int? lapNumber;
  final String category;
  final String? flag;
  final String message;

  const RaceControlMessage({
    this.date,
    this.driverNumber,
    this.lapNumber,
    required this.category,
    this.flag,
    required this.message,
  });

  factory RaceControlMessage.fromJson(Map<String, dynamic> json) {
    return RaceControlMessage(
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      driverNumber: (json['driver_number'] as num?)?.toInt(),
      lapNumber: (json['lap_number'] as num?)?.toInt(),
      category: json['category'] as String? ?? '',
      flag: json['flag'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}
