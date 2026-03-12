import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/korean_locale.dart';
import '../../core/theme.dart';
import '../../models/driver.dart';
import '../../models/weather.dart';
import '../../providers/replay_provider.dart';
import '../live/widgets/weather_bar.dart';
import '../shared/error_widget.dart';
import '../shared/loading_widget.dart';
import 'widgets/circuit_map.dart';

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
  int? _lastBufferSecond;

  static const _tickMs = 50; // 20 fps

  @override
  void dispose() {
    _timer?.cancel();
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
    final bufferState = ref.watch(replayBufferProvider(widget.sessionKey));
    final driversAsync = ref.watch(replayDriversProvider(widget.sessionKey));
    final weatherAsync = ref.watch(replayWeatherProvider(widget.sessionKey));

    return Scaffold(
      backgroundColor: F1Colors.background,
      appBar: AppBar(
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
      ),
      body: _buildBody(bufferState, driversAsync, weatherAsync),
    );
  }

  Widget _buildBody(
    ReplayBufferState bufferState,
    AsyncValue<Map<int, Driver>> driversAsync,
    AsyncValue<List<Weather>> weatherAsync,
  ) {
    if (bufferState.error != null) {
      return F1ErrorWidget(
        error: bufferState.error ?? 'Unknown error',
        onRetry: () => ref.invalidate(replayBufferProvider(widget.sessionKey)),
      );
    }

    final locations = bufferState.locations;
    final sessionStart = bufferState.sessionStart;
    final sessionEnd = bufferState.sessionEnd;

    if (bufferState.isLoading && locations.isEmpty) {
      return const F1LoadingWidget();
    }

    if (locations.isEmpty || sessionStart == null || sessionEnd == null) {
      return const Center(
        child: Text(
          '위치 데이터가 없습니다',
          style: TextStyle(color: F1Colors.textSecondary),
        ),
      );
    }

    final drivers = driversAsync.valueOrNull ?? {};
    final weatherList = weatherAsync.valueOrNull ?? [];

    final totalDuration = sessionEnd.difference(sessionStart);
    if (totalDuration.inMilliseconds <= 0) {
      return const Center(child: F1LoadingWidget());
    }

    // Compute current replay time
    final currentTime = sessionStart.add(Duration(
      milliseconds: (totalDuration.inMilliseconds * _progress).round(),
    ));
    _maybeUpdateBuffer(currentTime);

          // Build track outline from the driver with most data points
    final trackDriverNum = locations.entries
        .reduce((a, b) => a.value.length > b.value.length ? a : b)
        .key;
    final trackPoints = locations[trackDriverNum] ?? [];

          // Interpolate all car positions at current time
          final cars = <ReplayCarState>[];
          for (final entry in locations.entries) {
            final state = interpolateAt(
              entry.value,
              currentTime,
              entry.key,
              drivers[entry.key],
            );
            if (state != null) cars.add(state);
          }

          // Current weather
          final currentWeather = weatherAtTime(weatherList, currentTime);

    final elapsed = Duration(
      milliseconds: (totalDuration.inMilliseconds * _progress).round(),
    );
    final total = totalDuration;

    return Column(
      children: [
        if (currentWeather != null) WeatherBar(weather: currentWeather),
        Expanded(
          child: CircuitMap(
            trackPoints: trackPoints,
            cars: cars,
          ),
        ),
        _buildControls(elapsed, total, totalDuration),
      ],
    );
  }

  void _maybeUpdateBuffer(DateTime currentTime) {
    final seconds = currentTime.millisecondsSinceEpoch ~/ 1000;
    if (_lastBufferSecond == seconds) return;
    _lastBufferSecond = seconds;
    ref
        .read(replayBufferProvider(widget.sessionKey).notifier)
        .updatePlaybackTime(currentTime);
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
