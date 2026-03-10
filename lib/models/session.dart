class Session {
  final int sessionKey;
  final int meetingKey;
  final String sessionName;
  final String sessionType;
  final DateTime dateStart;
  final DateTime? dateEnd;
  final int year;

  const Session({
    required this.sessionKey,
    required this.meetingKey,
    required this.sessionName,
    required this.sessionType,
    required this.dateStart,
    this.dateEnd,
    required this.year,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionKey: json['session_key'] as int,
      meetingKey: json['meeting_key'] as int,
      sessionName: json['session_name'] as String? ?? '',
      sessionType: json['session_type'] as String? ?? '',
      dateStart: DateTime.tryParse(json['date_start'] as String? ?? '') ??
          DateTime.now(),
      dateEnd: json['date_end'] != null
          ? DateTime.tryParse(json['date_end'] as String)
          : null,
      year: json['year'] as int? ?? 0,
    );
  }

  bool get isRace => sessionType == 'Race';
  bool get isQualifying => sessionType == 'Qualifying';
  bool get isCompleted =>
      dateEnd != null && dateEnd!.isBefore(DateTime.now());
}
