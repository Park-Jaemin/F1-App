class SessionResult {
  final int position;
  final int driverNumber;
  final String broadcastName;
  final String nameAcronym;
  final String teamName;
  final String? teamColour;
  final int? points;
  final bool dnf;
  final bool dns;
  final bool dsq;
  final bool nc;
  final bool dnq;
  final double? gapToLeader;
  final String? headshotUrl;

  const SessionResult({
    required this.position,
    required this.driverNumber,
    required this.broadcastName,
    required this.nameAcronym,
    required this.teamName,
    this.teamColour,
    this.points,
    this.dnf = false,
    this.dns = false,
    this.dsq = false,
    this.nc = false,
    this.dnq = false,
    this.gapToLeader,
    this.headshotUrl,
  });

  factory SessionResult.fromJson(Map<String, dynamic> json) {
    return SessionResult(
      position: (json['position'] as num?)?.toInt() ?? 0,
      driverNumber: (json['driver_number'] as num?)?.toInt() ?? 0,
      broadcastName: json['broadcast_name'] as String? ?? '',
      nameAcronym: json['name_acronym'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
      teamColour: json['team_colour'] as String?,
      points: (json['points'] as num?)?.toInt(),
      dnf: json['dnf'] as bool? ?? false,
      dns: json['dns'] as bool? ?? false,
      dsq: json['dsq'] as bool? ?? false,
      nc: json['nc'] as bool? ?? false,
      dnq: json['dnq'] as bool? ?? false,
      gapToLeader: json['gap_to_leader'] is num
          ? (json['gap_to_leader'] as num).toDouble()
          : null,
      headshotUrl: json['headshot_url'] as String?,
    );
  }

  bool get isNonFinisher => dnf || dns || dsq || nc || dnq;

  String? get statusLabel {
    if (dsq) return 'DSQ';
    if (dnf) return 'DNF';
    if (dns) return 'DNS';
    if (nc) return 'NC';
    if (dnq) return 'DNQ';
    return null;
  }
}
