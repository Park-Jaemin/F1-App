import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/korean_locale.dart';
import '../../core/theme.dart';
import '../../providers/meetings_provider.dart';
import '../shared/error_widget.dart';
import '../shared/loading_widget.dart';
import 'widgets/pit_stops_tab.dart';
import 'widgets/result_list.dart';

class RaceDetailScreen extends ConsumerWidget {
  final int meetingKey;
  final String meetingName;

  const RaceDetailScreen({
    super.key,
    required this.meetingKey,
    required this.meetingName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider(meetingKey));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: F1Colors.background,
        appBar: AppBar(
          backgroundColor: F1Colors.background,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizeGrandPrix(meetingName),
                style: const TextStyle(
                  color: F1Colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: '결과'),
              Tab(text: '피트스톱'),
            ],
            labelColor: F1Colors.primary,
            unselectedLabelColor: F1Colors.textSecondary,
            indicatorColor: F1Colors.primary,
          ),
        ),
        body: sessionsAsync.when(
          data: (sessions) {
            // Find race session
            final raceSession = sessions
                .where((s) => s.sessionType == 'Race')
                .firstOrNull;

            if (raceSession == null) {
              // Show all sessions if no race session found
              return _SessionSelector(
                sessions: sessions,
                meetingKey: meetingKey,
              );
            }

            return _RaceDetailTabs(sessionKey: raceSession.sessionKey);
          },
          loading: () => const F1LoadingWidget(),
          error: (error, _) => F1ErrorWidget(error: error),
        ),
      ),
    );
  }
}

class _SessionSelector extends StatelessWidget {
  final List<dynamic> sessions;
  final int meetingKey;

  const _SessionSelector({
    required this.sessions,
    required this.meetingKey,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_note,
            color: F1Colors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            '레이스 데이터가 아직 없습니다',
            style: TextStyle(color: F1Colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '${sessions.length}개 세션 등록됨',
            style: const TextStyle(color: F1Colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RaceDetailTabs extends ConsumerWidget {
  final int sessionKey;

  const _RaceDetailTabs({required this.sessionKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBarView(
      children: [
        ResultList(sessionKey: sessionKey),
        PitStopsTab(sessionKey: sessionKey),
      ],
    );
  }
}
