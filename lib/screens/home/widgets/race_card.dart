import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/korean_locale.dart';
import '../../../core/theme.dart';
import '../../../models/meeting.dart';
import '../../../models/session.dart';
import '../../../providers/meetings_provider.dart';
import '../../../providers/race_detail_provider.dart';

class RaceCard extends ConsumerWidget {
  final Meeting meeting;
  final int roundNumber;
  final VoidCallback onTap;

  const RaceCard({
    super.key,
    required this.meeting,
    required this.roundNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isPast = meeting.dateStart.isBefore(now);
    final raceSessionAsync = isPast
        ? ref.watch(raceSessionProvider(meeting.meetingKey))
        : const AsyncValue<Session?>.data(null);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: F1Colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPast ? F1Colors.divider : F1Colors.primary.withValues(alpha: 0.3),
            width: isPast ? 0 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: F1Colors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'R$roundNumber',
                      style: const TextStyle(
                        color: F1Colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd').format(meeting.dateStart),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (!isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '예정',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    meeting.flagEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizeGrandPrix(meeting.meetingName),
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          meeting.circuitShortName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: F1Colors.textSecondary,
                  ),
                ],
              ),
              if (isPast) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                raceSessionAsync.when(
                  data: (session) {
                    if (session == null) return const SizedBox.shrink();
                    return _TopThreeRow(sessionKey: session.sessionKey);
                  },
                  loading: () => const SizedBox(
                    height: 20,
                    child: Center(
                      child: LinearProgressIndicator(
                        color: F1Colors.primary,
                        backgroundColor: F1Colors.divider,
                      ),
                    ),
                  ),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopThreeRow extends ConsumerWidget {
  final int sessionKey;

  const _TopThreeRow({required this.sessionKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(sessionResultsProvider(sessionKey));

    return resultsAsync.when(
      data: (results) {
        final top3 = results.take(3).toList();
        if (top3.isEmpty) return const SizedBox.shrink();

        return Row(
          children: top3.asMap().entries.map((entry) {
            final idx = entry.key;
            final result = entry.value;
            final medals = ['🥇', '🥈', '🥉'];

            return Expanded(
              child: Row(
                children: [
                  Text(medals[idx], style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      result.nameAcronym,
                      style: const TextStyle(
                        color: F1Colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
