import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/korean_locale.dart';
import '../../../core/theme.dart';
import '../../../models/meeting.dart';

class NextSessionCard extends StatefulWidget {
  final Meeting meeting;

  const NextSessionCard({super.key, required this.meeting});

  @override
  State<NextSessionCard> createState() => _NextSessionCardState();
}

class _NextSessionCardState extends State<NextSessionCard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = widget.meeting.dateStart.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_motorsports,
              color: F1Colors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              '현재 진행 중인 세션이 없습니다',
              style: TextStyle(
                color: F1Colors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '다음 그랑프리',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.meeting.flagEmoji} ${localizeGrandPrix(widget.meeting.meetingName)}',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.meeting.circuitShortName} · ${widget.meeting.location}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (diff.isNegative)
              const Text(
                '곧 시작됩니다',
                style: TextStyle(
                  color: F1Colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CountdownUnit(value: days, label: '일'),
                  _CountdownUnit(value: hours, label: '시간'),
                  _CountdownUnit(value: minutes, label: '분'),
                  _CountdownUnit(value: seconds, label: '초'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: F1Colors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value'.padLeft(2, '0'),
              style: const TextStyle(
                color: F1Colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: F1Colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
