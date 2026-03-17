import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/korean_locale.dart';
import '../../core/theme.dart';
import '../../models/driver.dart';
import '../../providers/replay_provider.dart';
import '../live/widgets/weather_bar.dart';
import '../shared/error_widget.dart';
import '../shared/loading_widget.dart';

class ReplayScreen extends ConsumerStatefulWidget {
  final int sessionKey;
  final String meetingName;
  final String sessionName;

  const ReplayScreen({
    super.key,
    required this.sessionKey,
    required this.meetingName,
    required this.sessionName,
  });

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  bool _playing = false;
  double _progress = 0.0; // 0.0 to 1.0
  double _speed = 30.0; // 30x real-time
  Timer? _timer;
  Map<int, int> _lastPositions = {};
  final Map<int, _ChangeFlash> _positionChangeFlashes = {};
  final ScrollController _rankingScrollController = ScrollController();

  static const _tickMs = 50; // 20 fps

  @override
  void dispose() {
    _timer?.cancel();
    _rankingScrollController.dispose();
    super.dispose();
  }

  void _togglePlay(Duration totalDuration) {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
        if (!mounted) return;
        final totalMs = totalDuration.inMilliseconds;
        if (totalMs <= 0) return;
        final increment = (_tickMs * _speed) / totalMs;
        setState(() {
          _progress += increment;
          if (_progress >= 1.0) {
            _progress = 1.0;
            _playing = false;
            _timer?.cancel();
          }
        });
      });
    }
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(replayDriversProvider(widget.sessionKey));
    final timelineAsync = ref.watch(replayTimelineProvider(widget.sessionKey));
    final sessionRangeAsync =
        ref.watch(replaySessionRangeProvider(widget.sessionKey));
    final positionsAsync =
        ref.watch(replayPositionsProvider(widget.sessionKey));
    final weatherAsync = ref.watch(replayWeatherProvider(widget.sessionKey));

    return sessionRangeAsync.when(
      loading: () => Scaffold(
        backgroundColor: F1Colors.background,
        appBar: _buildAppBar(),
        body: const F1LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: F1Colors.background,
        appBar: _buildAppBar(),
        body: F1ErrorWidget(error: e),
      ),
      data: (range) {
        if (range == null) {
          return Scaffold(
            backgroundColor: F1Colors.background,
            appBar: _buildAppBar(),
            body: const Center(
              child: Text(
                '세션 정보를 불러올 수 없습니다',
                style: TextStyle(color: F1Colors.textSecondary),
              ),
            ),
          );
        }

        final totalDuration = range.end.difference(range.start);
        final currentTime = range.start.add(Duration(
          milliseconds: (totalDuration.inMilliseconds * _progress).round(),
        ));
        final weatherSection = weatherAsync.when(
          loading: () => const SizedBox(
            height: 46,
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stackTrace) => const SizedBox.shrink(),
          data: (weatherList) {
            final weather = weatherAtTime(weatherList, currentTime);
            if (weather == null) return const SizedBox.shrink();
            return WeatherBar(weather: weather);
          },
        );

        return Scaffold(
          backgroundColor: F1Colors.background,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              weatherSection,
              Expanded(
                child: _buildSplitContent(
                  timelineAsync: timelineAsync,
                  driversAsync: driversAsync,
                  positionsAsync: positionsAsync,
                  sessionStart: range.start,
                  currentTime: currentTime,
                ),
              ),
              _buildControls(
                currentTime.difference(range.start),
                totalDuration,
                totalDuration,
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: F1Colors.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizeGrandPrix(widget.meetingName),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'REPLAY · ${localizeSession(widget.sessionName)}',
            style: const TextStyle(
              fontSize: 12,
              color: F1Colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitContent({
    required AsyncValue<List<ReplayTimelineEvent>> timelineAsync,
    required AsyncValue<Map<int, Driver>> driversAsync,
    required AsyncValue<Map<int, List<PositionSample>>> positionsAsync,
    required DateTime? sessionStart,
    required DateTime currentTime,
  }) {
    if (driversAsync.isLoading ||
        timelineAsync.isLoading ||
        positionsAsync.isLoading) {
      return const F1LoadingWidget();
    }
    if (driversAsync.hasError) {
      return F1ErrorWidget(error: driversAsync.error ?? 'Unknown error');
    }
    if (timelineAsync.hasError) {
      return F1ErrorWidget(error: timelineAsync.error ?? 'Unknown error');
    }
    if (positionsAsync.hasError) {
      return F1ErrorWidget(error: positionsAsync.error ?? 'Unknown error');
    }

    final drivers = driversAsync.value ?? {};
    final events = timelineAsync.value ?? [];
    final positions = positionsAsync.value ?? {};
    final visibleEvents =
        events.where((e) => !e.time.isAfter(currentTime)).toList();
    final ranking = _positionsAtTime(positions, currentTime);
    final now = DateTime.now();
    final positionChanges = <int, int>{};
    for (final entry in ranking) {
      final previous = _lastPositions[entry.driverNumber];
      if (previous != null && previous != entry.position) {
        final change = previous - entry.position;
        _positionChangeFlashes[entry.driverNumber] =
            _ChangeFlash(change: change, timestamp: now);
      }
    }
    _positionChangeFlashes.removeWhere(
      (_, flash) => now.difference(flash.timestamp).inMilliseconds > 1500,
    );
    for (final entry in ranking) {
      final flash = _positionChangeFlashes[entry.driverNumber];
      if (flash != null) {
        positionChanges[entry.driverNumber] = flash.change;
      }
    }
    _lastPositions = {
      for (final entry in ranking) entry.driverNumber: entry.position,
    };

        final rankingPane =
            _buildRankingList(ranking, drivers, positionChanges);
        final eventsPane = _buildEventsList(
          visibleEvents,
          drivers,
          sessionStart,
          currentTime,
          _speed,
        );

    return Row(
      children: [
        Expanded(child: rankingPane),
        const VerticalDivider(width: 1, color: F1Colors.divider),
        Expanded(child: eventsPane),
      ],
    );
  }

  String _formatEventTime(DateTime time, DateTime? sessionStart) {
    if (sessionStart == null) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      final s = time.second.toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    final diff = time.difference(sessionStart);
    if (diff.isNegative) return '0:00';
    return _formatDuration(diff);
  }

  List<({int driverNumber, int position})> _positionsAtTime(
    Map<int, List<PositionSample>> positions,
    DateTime time,
  ) {
    final list = <({int driverNumber, int position})>[];
    for (final entry in positions.entries) {
      final samples = entry.value;
      if (samples.isEmpty) continue;
      PositionSample? current;
      for (final s in samples) {
        if (s.time.isAfter(time)) break;
        current = s;
      }
      if (current != null) {
        list.add((driverNumber: entry.key, position: current.position));
      }
    }
    list.sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  Widget _buildRankingList(
    List<({int driverNumber, int position})> ranking,
    Map<int, Driver> drivers,
    Map<int, int> positionChanges,
  ) {
    if (ranking.isEmpty) {
      return const Center(
        child: Text(
          '순위 데이터가 없습니다',
          style: TextStyle(color: F1Colors.textSecondary),
        ),
      );
    }
    return Container(
      color: F1Colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'CURRENT POSITIONS',
              style: TextStyle(
                color: F1Colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const itemHeight = 44.0;
                final contentHeight = itemHeight * ranking.length;
                return Scrollbar(
                  controller: _rankingScrollController,
                  child: SingleChildScrollView(
                    controller: _rankingScrollController,
                    primary: false,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      height: contentHeight,
                      child: Stack(
                        children: [
                          for (var i = 0; i < ranking.length; i++)
                            AnimatedPositioned(
                              key: ValueKey(ranking[i].driverNumber),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              top: i * itemHeight,
                              left: 0,
                              right: 0,
                              height: itemHeight,
                              child: _RankingRow(
                                entry: ranking[i],
                                driver: drivers[ranking[i].driverNumber],
                                positionChange:
                                    positionChanges[ranking[i].driverNumber],
                                showDivider: i != ranking.length - 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
    List<ReplayTimelineEvent> events,
    Map<int, Driver> drivers,
    DateTime? sessionStart,
    DateTime currentTime,
    double speed,
  ) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          '이벤트 데이터가 없습니다',
          style: TextStyle(color: F1Colors.textSecondary),
        ),
      );
    }

    final ordered = events.reversed.toList();
    final highlightWindow =
        Duration(seconds: (speed * 3).round().clamp(3, 180));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'TIMELINE',
            style: TextStyle(
              color: F1Colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            primary: false,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: ordered.length,
            itemBuilder: (context, index) {
              final event = ordered[index];
              final age = currentTime.difference(event.time);
              final isHighlighted =
                  !age.isNegative && age <= highlightWindow;
              final driver = event.driverNumber != null
                  ? drivers[event.driverNumber]
                  : null;
              final timeLabel = _formatEventTime(event.time, sessionStart);
              final title = driver != null
                  ? '${event.title} · ${driver.nameAcronym}'
                  : event.title;
              final detail = event.detail;

              return _TimelineEventCard(
                key: ValueKey(
                  '${event.time.toIso8601String()}|${event.type}|${event.driverNumber ?? ''}|${event.lapNumber ?? ''}',
                ),
                timeLabel: timeLabel,
                title: title,
                detail: detail,
                isHighlighted: isHighlighted,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControls(Duration elapsed, Duration total, Duration totalDuration) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: F1Colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: F1Colors.primary,
              inactiveTrackColor: F1Colors.divider,
              thumbColor: F1Colors.primary,
              overlayColor: F1Colors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _progress,
              onChanged: (v) {
                setState(() => _progress = v);
              },
              onChangeStart: (_) {
                if (_playing) {
                  _timer?.cancel();
                }
              },
              onChangeEnd: (_) {
                if (_playing) {
                  _togglePlay(totalDuration);
                }
              },
            ),
          ),

          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(elapsed),
                  style: const TextStyle(
                    color: F1Colors.textSecondary,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _formatDuration(total),
                  style: const TextStyle(
                    color: F1Colors.textSecondary,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Play/pause + speed controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed controls
              _SpeedButton(
                label: '10x',
                selected: _speed == 10,
                onTap: () => _setSpeed(10),
              ),
              _SpeedButton(
                label: '30x',
                selected: _speed == 30,
                onTap: () => _setSpeed(30),
              ),
              const SizedBox(width: 16),

              // Play/pause
              IconButton(
                onPressed: () => _togglePlay(totalDuration),
                icon: Icon(
                  _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 48,
                  color: F1Colors.primary,
                ),
              ),

              const SizedBox(width: 16),
              _SpeedButton(
                label: '60x',
                selected: _speed == 60,
                onTap: () => _setSpeed(60),
              ),
              _SpeedButton(
                label: '120x',
                selected: _speed == 120,
                onTap: () => _setSpeed(120),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final ({int driverNumber, int position}) entry;
  final Driver? driver;
  final int? positionChange;
  final bool showDivider;

  const _RankingRow({
    required this.entry,
    required this.driver,
    required this.positionChange,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: F1Colors.divider, width: 0.8),
              ),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              entry.position.toString(),
              style: const TextStyle(
                color: F1Colors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    driver?.nameAcronym ?? entry.driverNumber.toString(),
                    style: const TextStyle(
                      color: F1Colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _PositionChangeIndicator(change: positionChange),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              driver?.teamName ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: F1Colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionChangeIndicator extends StatelessWidget {
  final int? change;

  const _PositionChangeIndicator({required this.change});

  @override
  Widget build(BuildContext context) {
    if (change == null) {
      return const SizedBox.shrink();
    }
    if (change == 0) {
      return const SizedBox.shrink();
    }
    final isPositive = change! > 0;
    return Icon(
      isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
      color: isPositive ? Colors.green : Colors.red,
      size: 18,
    );
  }
}

class _ChangeFlash {
  final int change;
  final DateTime timestamp;

  const _ChangeFlash({
    required this.change,
    required this.timestamp,
  });
}

class _TimelineEventCard extends StatefulWidget {
  final String timeLabel;
  final String title;
  final String? detail;
  final bool isHighlighted;

  const _TimelineEventCard({
    super.key,
    required this.timeLabel,
    required this.title,
    required this.detail,
    required this.isHighlighted,
  });

  @override
  State<_TimelineEventCard> createState() => _TimelineEventCardState();
}

class _TimelineEventCardState extends State<_TimelineEventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = F1Colors.primary.withValues(alpha: 0.15);
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isHighlighted ? highlightColor : F1Colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: widget.isHighlighted
                ? Border.all(color: F1Colors.primary, width: 1)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  widget.timeLabel,
                  style: const TextStyle(
                    color: F1Colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: F1Colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.detail != null && widget.detail!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.detail!,
                          style: const TextStyle(
                            color: F1Colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? F1Colors.primary.withValues(alpha: 0.2)
              : F1Colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: F1Colors.primary, width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? F1Colors.primary : F1Colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
