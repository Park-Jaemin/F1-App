import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/openf1_client.dart';
import '../models/meeting.dart';
import '../models/session.dart';

final openF1ClientProvider = Provider<OpenF1Client>((ref) => OpenF1Client());

final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final meetingsProvider =
    FutureProvider.family<List<Meeting>, int>((ref, year) async {
  final client = ref.read(openF1ClientProvider);
  try {
    final data = await client.getMeetings(year);
    final meetings = data
        .map((json) {
          try {
            return Meeting.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing meeting: $e, data: $json');
            rethrow;
          }
        })
        .where((m) => !_isTestingMeeting(m.meetingName))
        .toList();
    meetings.sort((a, b) => a.dateStart.compareTo(b.dateStart));
    return meetings;
  } catch (e, stack) {
    debugPrint('Error fetching meetings for year $year: $e');
    debugPrint(stack.toString());
    rethrow;
  }
});

bool _isTestingMeeting(String name) {
  final lower = name.toLowerCase();
  return lower.contains('testing') || lower.contains('pre-season');
}

final sessionsProvider =
    FutureProvider.family<List<Session>, int>((ref, meetingKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getSessions(meetingKey);
  final sessions = data.map((json) => Session.fromJson(json)).toList();
  sessions.sort((a, b) => a.dateStart.compareTo(b.dateStart));
  return sessions;
});

final raceSessionProvider =
    FutureProvider.family<Session?, int>((ref, meetingKey) async {
  final sessions = await ref.watch(sessionsProvider(meetingKey).future);
  try {
    return sessions.firstWhere((s) => s.isRace);
  } catch (_) {
    return null;
  }
});
