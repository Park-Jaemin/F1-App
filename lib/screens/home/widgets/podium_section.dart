import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/korean_locale.dart';
import '../../../core/theme.dart';
import '../../../models/meeting.dart';
import '../../../models/session.dart';
import '../../../models/session_result.dart';
import '../../../providers/meetings_provider.dart';
import '../../../providers/race_detail_provider.dart';
import '../../shared/loading_widget.dart';

class PodiumSection extends ConsumerWidget {
  final Meeting meeting;

  const PodiumSection({super.key, required this.meeting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isPast = meeting.dateStart.isBefore(now);

    if (!isPast) {
      return _UpcomingInfo(meeting: meeting);
    }

    final sessionsAsync = ref.watch(sessionsProvider(meeting.meetingKey));

    return sessionsAsync.when(
      data: (sessions) {
        final now = DateTime.now();
        final completed = sessions
            .where((s) => s.dateEnd != null && s.dateEnd!.isBefore(now))
            .toList()
          ..sort((a, b) => a.dateStart.compareTo(b.dateStart));

        if (completed.isEmpty) {
          return const Center(
            child: Text(
              '결과 데이터 없음',
              style: TextStyle(color: F1Colors.textSecondary),
            ),
          );
        }

        final replayTargets =
            completed.where((s) => s.isReplayTarget).toList()
              ..sort((a, b) => a.dateStart.compareTo(b.dateStart));

        return Column(
          children: [
            Expanded(
              child: _SessionTabsPodium(
                sessions: completed,
                meeting: meeting,
              ),
            ),
            if (replayTargets.isNotEmpty)
              replayTargets.length == 1
                  ? _ReplayButton(
                      meetingKey: meeting.meetingKey,
                      meetingName: meeting.meetingName,
                      sessionKey: replayTargets.first.sessionKey,
                      sessionName: replayTargets.first.sessionName,
                    )
                  : _ReplayButtons(
                      meeting: meeting,
                      sessions: replayTargets,
                    ),
          ],
        );
      },
      loading: () => const F1LoadingWidget(),
      error: (e, _) => const Center(
        child: Text(
          '결과를 불러올 수 없습니다',
          style: TextStyle(color: F1Colors.textSecondary),
        ),
      ),
    );
  }
}

// ─── 세션 탭 + 포디엄 ────────────────────────────────────────────────
class _SessionTabsPodium extends StatelessWidget {
  final List<Session> sessions;
  final Meeting meeting;

  const _SessionTabsPodium({
    required this.sessions,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: sessions.length,
      initialIndex: sessions.length - 1, // 가장 최신 세션이 디폴트
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizeGrandPrix(meeting.meetingName),
                        style: const TextStyle(
                          color: F1Colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy년 M월 d일').format(meeting.dateStart),
                        style: const TextStyle(
                          color: F1Colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(
                    '/race/${meeting.meetingKey}/${meeting.meetingName}',
                  ),
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('전체 결과'),
                  style: TextButton.styleFrom(
                    foregroundColor: F1Colors.primary,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // 세션 탭
          TabBar(
            isScrollable: true,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabAlignment: TabAlignment.start,
            tabs: sessions
                .map((s) => Tab(text: localizeSession(s.sessionName)))
                .toList(),
            labelColor: F1Colors.primary,
            unselectedLabelColor: F1Colors.textSecondary,
            indicatorColor: F1Colors.primary,
            dividerHeight: 0,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
          ),
          // 포디엄 표시
          Expanded(
            child: TabBarView(
              children: sessions
                  .map((s) => _PodiumTab(sessionKey: s.sessionKey))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumTab extends ConsumerWidget {
  final int sessionKey;

  const _PodiumTab({required this.sessionKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top3Async = ref.watch(sessionTop3Provider(sessionKey));

    return top3Async.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text(
              '결과 데이터 없음',
              style: TextStyle(color: F1Colors.textSecondary),
            ),
          );
        }
        return _PodiumDisplay(results: results);
      },
      loading: () => const F1LoadingWidget(),
      error: (e, _) => const Center(
        child: Text(
          '결과를 불러올 수 없습니다',
          style: TextStyle(color: F1Colors.textSecondary),
        ),
      ),
    );
  }
}

// ─── 포디엄 메인 표시 ───────────────────────────────────────────────
class _PodiumDisplay extends StatelessWidget {
  final List<SessionResult> results;

  const _PodiumDisplay({required this.results});

  @override
  Widget build(BuildContext context) {
    // 2nd | 1st | 3rd 순서로 정렬
    final first = results.firstWhere((r) => r.position == 1,
        orElse: () => results[0]);
    final second = results.firstWhere((r) => r.position == 2,
        orElse: () => results.length > 1 ? results[1] : results[0]);
    final third = results.firstWhere((r) => r.position == 3,
        orElse: () => results.length > 2 ? results[2] : results[0]);
    final ordered = [second, first, third];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _DriverPodiumColumn(
              result: ordered[0],
              platformHeight: 72,
            ),
            _DriverPodiumColumn(
              result: ordered[1],
              platformHeight: 104,
              showTrophy: true,
            ),
            _DriverPodiumColumn(
              result: ordered[2],
              platformHeight: 52,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayButton extends StatelessWidget {
  final int meetingKey;
  final String meetingName;
  final int sessionKey;
  final String sessionName;

  const _ReplayButton({
    required this.meetingKey,
    required this.meetingName,
    required this.sessionKey,
    required this.sessionName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: F1Colors.surface,
          border: Border(top: BorderSide(color: F1Colors.divider)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              final encodedMeeting = Uri.encodeComponent(meetingName);
              final encodedSession = Uri.encodeComponent(sessionName);
              context.push(
                '/replay/$encodedMeeting/$sessionKey/$encodedSession',
              );
            },
            icon: const Icon(Icons.replay, size: 20),
            label: const Text(
              'REPLAY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: F1Colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplayButtons extends StatelessWidget {
  final Meeting meeting;
  final List<Session> sessions;

  const _ReplayButtons({
    required this.meeting,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: F1Colors.surface,
          border: Border(top: BorderSide(color: F1Colors.divider)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < sessions.length; i++) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final encodedMeeting =
                        Uri.encodeComponent(meeting.meetingName);
                    final encodedSession =
                        Uri.encodeComponent(sessions[i].sessionName);
                    context.push(
                      '/replay/$encodedMeeting/${sessions[i].sessionKey}/$encodedSession',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: F1Colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _labelFor(sessions[i]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (i != sessions.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }

  String _labelFor(Session session) {
    if (session.isSprint) return 'SPRINT REPLAY';
    if (session.isRace) return 'RACE REPLAY';
    return '${localizeSession(session.sessionName).toUpperCase()} REPLAY';
  }
}

// ─── 드라이버 포디엄 컬럼 ───────────────────────────────────────────
class _DriverPodiumColumn extends StatelessWidget {
  final SessionResult result;
  final double platformHeight;
  final bool showTrophy;

  const _DriverPodiumColumn({
    required this.result,
    required this.platformHeight,
    this.showTrophy = false,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = result.teamColour != null
        ? Color(int.parse('FF${result.teamColour}', radix: 16))
        : F1Colors.getTeamColor(result.teamName);

    final medalColor = _medalColor(result.position);
    final driverName =
        localizeDriver(result.nameAcronym, result.broadcastName);
    final teamName = localizeTeam(result.teamName);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 트로피 (1위만)
          if (showTrophy)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('🏆', style: TextStyle(fontSize: 24)),
            ),
          // 드라이버 이미지
          _DriverAvatar(
            headshotUrl: result.headshotUrl,
            teamColor: teamColor,
            size: showTrophy ? 76 : 64,
          ),
          const SizedBox(height: 8),
          // 포지션 메달
          Text(
            _positionEmoji(result.position),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 4),
          // 드라이버 이름
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              driverName,
              style: TextStyle(
                color: F1Colors.textPrimary,
                fontSize: showTrophy ? 13 : 12,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              teamName,
              style: const TextStyle(
                color: F1Colors.textSecondary,
                fontSize: 10,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // 포디엄 단상
          Container(
            width: double.infinity,
            height: platformHeight,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  medalColor.withValues(alpha: 0.35),
                  medalColor.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(
                color: medalColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Center(
              child: Text(
                '${result.position}',
                style: TextStyle(
                  color: medalColor,
                  fontSize: showTrophy ? 28 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _medalColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFB8C4CC);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return F1Colors.textSecondary;
    }
  }

  String _positionEmoji(int position) {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}

// ─── 드라이버 아바타 ────────────────────────────────────────────────
class _DriverAvatar extends StatelessWidget {
  final String? headshotUrl;
  final Color teamColor;
  final double size;

  const _DriverAvatar({
    required this.headshotUrl,
    required this.teamColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: teamColor, width: 2.5),
        color: F1Colors.surfaceVariant,
      ),
      child: ClipOval(
        child: headshotUrl != null
            ? Image.network(
                headshotUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _placeholder(),
                errorBuilder: (context, error, stack) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.person,
      color: F1Colors.textSecondary,
      size: size * 0.55,
    );
  }
}

// ─── 예정 레이스 정보 ───────────────────────────────────────────────
class _UpcomingInfo extends StatelessWidget {
  final Meeting meeting;

  const _UpcomingInfo({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      meeting.dateStart.year,
      meeting.dateStart.month,
      meeting.dateStart.day,
    );
    final daysUntil = eventDate.difference(today).inDays;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            meeting.flagEmoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            localizeGrandPrix(meeting.meetingName),
            style: const TextStyle(
              color: F1Colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('yyyy년 M월 d일').format(meeting.dateStart),
            style: const TextStyle(
              color: F1Colors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.green.withValues(alpha: 0.5), width: 1),
            ),
            child: Text(
              daysUntil == 0
                  ? '오늘 개최'
                  : daysUntil == 1
                      ? '내일 개최'
                      : '$daysUntil일 후 개최',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
