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
    final isCurrent = !isUpcoming &&
        now.isBefore(meeting.dateStart.add(const Duration(days: 3)));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 100, // 사이즈 키움 (84 -> 100)
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? F1Colors.primary : F1Colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? F1Colors.primary
                : isUpcoming
                    ? Colors.green.withValues(alpha: 0.6)
                    : Colors.transparent,
            width: 2.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: F1Colors.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 국가 이모지 중앙 배치 및 사이즈 확대
            Text(
              meeting.flagEmoji,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 6),
            // 라운드 정보 (진행 중일 때 NOW 표시)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.red.withValues(alpha: 0.9)
                    : isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : F1Colors.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isCurrent ? 'NOW' : 'ROUND $roundNumber',
                style: TextStyle(
                  color: isCurrent
                      ? Colors.white
                      : isSelected
                          ? Colors.white
                          : F1Colors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // 서킷 이름 중앙 배치
            SizedBox(
              height: 28,
              child: Center(
                child: Text(
                  meeting.circuitShortName.isNotEmpty
                      ? meeting.circuitShortName
                      : meeting.location,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : F1Colors.textPrimary,
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
