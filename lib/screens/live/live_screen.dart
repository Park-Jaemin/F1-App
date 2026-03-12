import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/race_control_message.dart';
import '../../models/session.dart';
import '../../models/weather.dart';
import '../../providers/live_provider.dart';
import '../shared/error_widget.dart';
import '../shared/loading_widget.dart';
import 'widgets/live_position_row.dart';
import 'widgets/next_session_card.dart';
import 'widgets/race_control_feed.dart';
import 'widgets/session_header.dart';
import 'widgets/weather_bar.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(liveSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FORMULA 1'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(liveSessionProvider);
              ref.invalidate(sessionPositionsProvider(null));
              ref.invalidate(sessionRaceControlProvider(null));
              ref.invalidate(sessionWeatherProvider(null));
            },
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const F1LoadingWidget(),
        error: (error, _) => F1ErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(liveSessionProvider),
        ),
        data: (session) {
          if (session == null) {
            return _NoSessionView();
          }

          final isActive = !session.isCompleted;
          if (!isActive) {
            return _InactiveSessionView();
          }

          return _ActiveSessionView();
        },
      ),
    );
  }
}

class _NoSessionView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextMeeting = ref.watch(nextMeetingProvider);
    return nextMeeting.when(
      loading: () => const F1LoadingWidget(),
      error: (e, _) => F1ErrorWidget(
        error: e,
        onRetry: () => ref.invalidate(nextMeetingProvider),
      ),
      data: (meeting) {
        if (meeting == null) {
          return const Center(
            child: Text(
              '예정된 세션이 없습니다',
              style: TextStyle(color: F1Colors.textSecondary),
            ),
          );
        }
        return NextSessionCard(meeting: meeting);
      },
    );
  }
}

class _InactiveSessionView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextMeeting = ref.watch(nextMeetingProvider);
    return nextMeeting.when(
      loading: () => const F1LoadingWidget(),
      error: (e, _) => F1ErrorWidget(
        error: e,
        onRetry: () => ref.invalidate(nextMeetingProvider),
      ),
      data: (meeting) {
        if (meeting == null) {
          return const Center(
            child: Text(
              '현재 진행 중인 세션이 없습니다',
              style: TextStyle(color: F1Colors.textSecondary),
            ),
          );
        }
        return NextSessionCard(meeting: meeting);
      },
    );
  }
}

class _ActiveSessionView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start polling (null = latest session)
    ref.watch(livePollingProvider);

    final session = ref.watch(liveSessionProvider).value!;
    final positionsAsync = ref.watch(sessionPositionsProvider(null));
    final weatherAsync = ref.watch(sessionWeatherProvider(null));
    final raceControlAsync = ref.watch(sessionRaceControlProvider(null));

    return _SessionDataView(
      session: session,
      sessionKey: null,
      positionsAsync: positionsAsync,
      weatherAsync: weatherAsync,
      raceControlAsync: raceControlAsync,
    );
  }
}

/// Reusable scroll view for both live and historical sessions.
class _SessionDataView extends ConsumerWidget {
  final Session? session;
  final int? sessionKey;
  final AsyncValue<List<LiveEntry>> positionsAsync;
  final AsyncValue<Weather?> weatherAsync;
  final AsyncValue<List<RaceControlMessage>> raceControlAsync;

  const _SessionDataView({
    required this.session,
    required this.sessionKey,
    required this.positionsAsync,
    required this.weatherAsync,
    required this.raceControlAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        if (session != null)
          SliverToBoxAdapter(
            child: SessionHeader(session: session!),
          ),

        SliverToBoxAdapter(
          child: weatherAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
            data: (weather) {
              if (weather == null) return const SizedBox.shrink();
              return WeatherBar(weather: weather);
            },
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '포지션',
              style: TextStyle(
                color: F1Colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),

        positionsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: F1LoadingWidget(),
            ),
          ),
          error: (error, _) => SliverToBoxAdapter(
            child: F1ErrorWidget(
              error: error,
              onRetry: () => ref.invalidate(sessionPositionsProvider(sessionKey)),
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      '포지션 데이터가 없습니다',
                      style: TextStyle(color: F1Colors.textSecondary),
                    ),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => LivePositionRow(entry: entries[index]),
                childCount: entries.length,
              ),
            );
          },
        ),

        SliverToBoxAdapter(
          child: raceControlAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
            data: (messages) => RaceControlFeed(messages: messages),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }
}
