class SessionResult {
  final int position;
  final int driverNumber;
  final String broadcastName;
  final String nameAcronym;
  final String teamName;
  final String? teamColour;
  final int? points;
  final int? gridPosition; // 그리드 출발 위치
  final bool dnf;
  final bool dns;
  final bool dsq;
  final bool nc;
  final bool dnq;
  final double? gapToLeader;
  final String? headshotUrl;
  final double? q1;
  final double? q2;
  final double? q3;

  const SessionResult({
    required this.position,
    required this.driverNumber,
    required this.broadcastName,
    required this.nameAcronym,
    required this.teamName,
    this.teamColour,
    this.points,
    this.gridPosition,
    this.dnf = false,
    this.dns = false,
    this.dsq = false,
    this.nc = false,
    this.dnq = false,
    this.gapToLeader,
    this.headshotUrl,
    this.q1,
    this.q2,
    this.q3,
  });

  factory SessionResult.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final duration = json['duration'];
    double? q1;
    double? q2;
    double? q3;
    if (duration is List) {
      if (duration.isNotEmpty) q1 = asDouble(duration[0]);
      if (duration.length > 1) q2 = asDouble(duration[1]);
      if (duration.length > 2) q3 = asDouble(duration[2]);
    }

    return SessionResult(
      position: (json['position'] as num?)?.toInt() ?? 0,
      driverNumber: (json['driver_number'] as num?)?.toInt() ?? 0,
      broadcastName: json['broadcast_name'] as String? ?? '',
      nameAcronym: json['name_acronym'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
      teamColour: json['team_colour'] as String?,
      points: (json['points'] as num?)?.toInt(),
      gridPosition: (json['grid_position'] as num?)?.toInt(),
      dnf: json['dnf'] as bool? ?? false,
      dns: json['dns'] as bool? ?? false,
      dsq: json['dsq'] as bool? ?? false,
      nc: json['nc'] as bool? ?? false,
      dnq: json['dnq'] as bool? ?? false,
      gapToLeader: json['gap_to_leader'] is num
          ? (json['gap_to_leader'] as num).toDouble()
          : null,
      headshotUrl: json['headshot_url'] as String?,
      q1: q1,
      q2: q2,
      q3: q3,
    );
  }

  bool get isNonFinisher => dnf || dns || dsq || nc || dnq;

  // 순위 변동 계산 로직 강화
  int? get positionChange {
    if (gridPosition == null || gridPosition! <= 0 || position <= 0) return null;
    return gridPosition! - position;
  }

  String? get statusLabel {
    if (dsq) return 'DSQ';
    if (dnf) return 'DNF';
    if (dns) return 'DNS';
    if (nc) return 'NC';
    if (dnq) return 'DNQ';
    return null;
  }
}
