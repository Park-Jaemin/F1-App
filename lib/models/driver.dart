class Driver {
  final int driverNumber;
  final String broadcastName;
  final String fullName;
  final String nameAcronym;
  final String teamName;
  final String? teamColour;
  final String? headshotUrl;
  final String? countryCode;

  const Driver({
    required this.driverNumber,
    required this.broadcastName,
    required this.fullName,
    required this.nameAcronym,
    required this.teamName,
    this.teamColour,
    this.headshotUrl,
    this.countryCode,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverNumber: json['driver_number'] as int? ?? 0,
      broadcastName: json['broadcast_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      nameAcronym: json['name_acronym'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
      teamColour: json['team_colour'] as String?,
      headshotUrl: json['headshot_url'] as String?,
      countryCode: json['country_code'] as String?,
    );
  }
}
