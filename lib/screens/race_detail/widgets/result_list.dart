import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/korean_locale.dart';
import '../../../core/theme.dart';
import '../../../providers/race_detail_provider.dart';
import '../../shared/error_widget.dart';
import '../../shared/loading_widget.dart';

class ResultList extends ConsumerWidget {
  final int sessionKey;
  final bool isPractice;

  const ResultList({
    super.key,
    required this.sessionKey,
    this.isPractice = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(sessionResultsProvider(sessionKey));

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text(
              '결과 데이터 없음',
              style: TextStyle(color: F1Colors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            final isTop3 = result.position <= 3;
            final teamColor = result.teamColour != null
                ? Color(int.parse('FF${result.teamColour}', radix: 16))
                : F1Colors.getTeamColor(result.teamName);

            // 연습주행이 아니고 그리드 정보가 있을 때만 변동폭 계산
            final change = isPractice ? null : result.positionChange;
            final showGridInfo = !isPractice && result.gridPosition != null && result.gridPosition! > 0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: F1Colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: isTop3
                    ? Border(
                        left: BorderSide(
                          color: _getPositionColor(result.position),
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // 최종 순위
                  SizedBox(
                    width: 28,
                    child: Text(
                      result.position > 0 ? '${result.position}' : '-',
                      style: TextStyle(
                        color: isTop3 && result.position > 0
                            ? _getPositionColor(result.position)
                            : F1Colors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 등강폭 또는 그리드 정보 표시
                  SizedBox(
                    width: 36,
                    child: showGridInfo
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (change != null) ...[
                                Icon(
                                  change > 0
                                      ? Icons.arrow_drop_up
                                      : (change < 0
                                          ? Icons.arrow_drop_down
                                          : Icons.remove),
                                  color: change > 0
                                      ? Colors.green
                                      : (change < 0 ? Colors.red : Colors.grey),
                                  size: 22,
                                ),
                                Text(
                                  change == 0 ? 'G${result.gridPosition}' : '${change.abs()}',
                                  style: TextStyle(
                                    color: change > 0
                                        ? Colors.green
                                        : (change < 0 ? Colors.red : Colors.grey),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else ...[
                                // change가 계산되지 않았지만 gridPosition은 있는 경우
                                Text(
                                  'G${result.gridPosition}',
                                  style: const TextStyle(
                                    color: F1Colors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 3,
                    height: 36,
                    color: teamColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizeDriver(result.nameAcronym, result.broadcastName),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          localizeTeam(result.teamName),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (result.isNonFinisher)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        result.statusLabel ?? '',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  else if (result.points != null && result.points! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: F1Colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${result.points} pts',
                        style: const TextStyle(
                          color: F1Colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const F1LoadingWidget(),
      error: (error, _) => F1ErrorWidget(error: error),
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
