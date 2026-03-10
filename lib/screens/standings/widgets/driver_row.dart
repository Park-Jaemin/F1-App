import 'package:flutter/material.dart';
import '../../../core/korean_locale.dart';
import '../../../core/theme.dart';
import '../../../providers/standings_provider.dart';

class DriverRow extends StatelessWidget {
  final DriverStanding standing;

  const DriverRow({super.key, required this.standing});

  @override
  Widget build(BuildContext context) {
    final teamColor = standing.teamColour != null
        ? Color(int.parse('FF${standing.teamColour}', radix: 16))
        : F1Colors.getTeamColor(standing.teamName);

    final isTop3 = standing.positionCurrent <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: F1Colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: isTop3
            ? Border(
                left: BorderSide(
                  color: _getPositionColor(standing.positionCurrent),
                  width: 3,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${standing.positionCurrent}',
                  style: TextStyle(
                    color: isTop3
                        ? _getPositionColor(standing.positionCurrent)
                        : F1Colors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                _PositionChangeIndicator(change: standing.positionChange),
              ],
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
                  localizeDriver(standing.nameAcronym, standing.broadcastName),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  localizeTeam(standing.teamName),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${standing.pointsCurrent}',
                style: const TextStyle(
                  color: F1Colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(
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

class _PositionChangeIndicator extends StatelessWidget {
  final int change;

  const _PositionChangeIndicator({required this.change});

  @override
  Widget build(BuildContext context) {
    if (change == 0) {
      return const Icon(Icons.remove, size: 12, color: F1Colors.textSecondary);
    }

    final isPositive = change > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: isPositive ? Colors.green : Colors.red,
          size: 16,
        ),
        Text(
          '${change.abs()}',
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
