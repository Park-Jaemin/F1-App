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

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Scaffold(
            backgroundColor: F1Colors.background,
            appBar: AppBar(
              backgroundColor: F1Colors.background,
              title: Text(localizeGrandPrix(meetingName)),
            ),
            body: const Center(
              child: Text(
                '세션 정보가 없습니다',
                style: TextStyle(color: F1Colors.textSecondary),
              ),
            ),
          );
        }

        // 세션 정렬 (시간순)
        final sortedSessions = List.of(sessions)
          ..sort((a, b) => a.dateStart.compareTo(b.dateStart));

        // 레이스 세션 찾기 (피트스톱 탭을 위해)
        final raceSession = sortedSessions.where((s) => s.isRace).firstOrNull;

        // 탭 구성: 모든 세션 + (레이스가 있다면) 피트스톱
        final tabsCount = sortedSessions.length + (raceSession != null ? 1 : 0);

        return DefaultTabController(
          length: tabsCount,
          initialIndex: (sortedSessions.length - 1).clamp(0, tabsCount - 1), // 기본으로 마지막 세션(보통 레이스) 선택
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
              bottom: TabBar(
                isScrollable: true,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                tabAlignment: TabAlignment.start,
                tabs: [
                  ...sortedSessions.map((s) => Tab(text: localizeSession(s.sessionName))),
                  if (raceSession != null) const Tab(text: '피트스톱'),
                ],
                labelColor: F1Colors.primary,
                unselectedLabelColor: F1Colors.textSecondary,
                indicatorColor: F1Colors.primary,
              ),
            ),
            body: TabBarView(
              children: [
                ...sortedSessions.map((s) => ResultList(
                  sessionKey: s.sessionKey,
                  isPractice: s.sessionType == 'Practice',
                )),
                if (raceSession != null) PitStopsTab(sessionKey: raceSession.sessionKey),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: F1Colors.background,
        appBar: AppBar(backgroundColor: F1Colors.background),
        body: const F1LoadingWidget(),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: F1Colors.background,
        appBar: AppBar(backgroundColor: F1Colors.background),
        body: F1ErrorWidget(error: error),
      ),
    );
  }
}
