import '../core/korean_locale.dart';

class Meeting {
  final int meetingKey;
  final String meetingName;
  final String meetingOfficialName;
  final String location;
  final String countryName;
  final String countryCode;
  final String circuitShortName;
  final DateTime dateStart;
  final int year;

  const Meeting({
    required this.meetingKey,
    required this.meetingName,
    required this.meetingOfficialName,
    required this.location,
    required this.countryName,
    required this.countryCode,
    required this.circuitShortName,
    required this.dateStart,
    required this.year,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      meetingKey: json['meeting_key'] as int,
      meetingName: json['meeting_name'] as String? ?? '',
      meetingOfficialName:
          json['meeting_official_name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      circuitShortName: json['circuit_short_name'] as String? ?? '',
      dateStart: DateTime.tryParse(json['date_start'] as String? ?? '') ??
          DateTime.now(),
      year: json['year'] as int? ?? 0,
    );
  }

  String get flagEmoji {
    final emoji = countryCodeToFlag(countryCode);
    return emoji.isEmpty ? '🏁' : emoji;
  }
}
