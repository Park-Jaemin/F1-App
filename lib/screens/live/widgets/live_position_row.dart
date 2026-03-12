import 'package:flutter/material.dart';
import '../../../core/korean_locale.dart';
import '../../../core/theme.dart';
import '../../../providers/live_provider.dart';

class LivePositionRow extends StatelessWidget {
  final LiveEntry entry;

  const LivePositionRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final teamColor = entry.driver.teamColour != null
        ? Color(int.parse('FF${entry.driver.teamColour}', radix: 16))
        : F1Colors.getTeamColor(entry.driver.teamName);

    final isTop3 = entry.position <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: F1Colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: isTop3
            ? Border(
                left: BorderSide(
                  color: _getPositionColor(entry.position),
                  width: 3,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.position}',
              style: TextStyle(
                color: isTop3
                    ? _getPositionColor(entry.position)
                    : F1Colors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 40,
            color: teamColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizeDriver(
                      entry.driver.nameAcronym, entry.driver.broadcastName),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  localizeTeam(entry.driver.teamName),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.position == 1
                    ? 'LEADER'
                    : entry.gapToLeader ?? entry.interval ?? '',
                style: TextStyle(
                  color: entry.position == 1
                      ? F1Colors.primary
                      : F1Colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: entry.position == 1 ? 12 : 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (entry.position != 1 && entry.interval != null)
                Text(
                  entry.interval!,
                  style: const TextStyle(
                    color: F1Colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return F1Colors.textSecondary;
    }
  }
}
