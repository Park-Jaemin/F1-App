class Weather {
  final DateTime? date;
  final double airTemperature;
  final double trackTemperature;
  final double humidity;
  final int rainfall;
  final double windSpeed;
  final int windDirection;

  const Weather({
    this.date,
    required this.airTemperature,
    required this.trackTemperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.windDirection,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      airTemperature: (json['air_temperature'] as num?)?.toDouble() ?? 0,
      trackTemperature: (json['track_temperature'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      rainfall: (json['rainfall'] as num?)?.toInt() ?? 0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0,
      windDirection: (json['wind_direction'] as num?)?.toInt() ?? 0,
    );
  }
}
