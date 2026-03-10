import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/meeting.dart';

class GpChip extends StatelessWidget {
  final Meeting meeting;
  final int roundNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const GpChip({
    super.key,
    required this.meeting,
    required this.roundNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isUpcoming = meeting.dateStart.isAfter(now);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 84,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? F1Colors.primary : F1Colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? F1Colors.primary
                : isUpcoming
                    ? Colors.green.withValues(alpha: 0.6)
                    : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: F1Colors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R$roundNumber',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white70
                        : F1Colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  meeting.flagEmoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              meeting.circuitShortName.isNotEmpty
                  ? meeting.circuitShortName
                  : meeting.location,
              style: TextStyle(
                color: isSelected ? Colors.white : F1Colors.textPrimary,
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
