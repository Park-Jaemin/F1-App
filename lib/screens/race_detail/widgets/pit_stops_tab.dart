import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/korean_locale.dart';
import '../../../core/theme.dart';
import '../../../providers/race_detail_provider.dart';
import '../../shared/error_widget.dart';
import '../../shared/loading_widget.dart';

class PitStopsTab extends ConsumerWidget {
  final int sessionKey;

  const PitStopsTab({super.key, required this.sessionKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pitStopsAsync = ref.watch(pitStopsProvider(sessionKey));
    final stintsAsync = ref.watch(stintsProvider(sessionKey));
    final resultsAsync = ref.watch(sessionResultsProvider(sessionKey));

    if (pitStopsAsync.isLoading ||
        stintsAsync.isLoading ||
        resultsAsync.isLoading) {
      return const F1LoadingWidget();
    }

    if (pitStopsAsync.hasError) {
      return F1ErrorWidget(error: pitStopsAsync.error!);
    }

    final pitStops = pitStopsAsync.value ?? [];
    final stints = stintsAsync.value ?? [];
    final results = resultsAsync.value ?? [];

    // Group pit stops by driver
    final pitsByDriver = <int, List<dynamic>>{};
    for (final pit in pitStops) {
      pitsByDriver.putIfAbsent(pit.driverNumber, () => []).add(pit);
    }

    // Group stints by driver
    final stintsByDriver = <int, List<dynamic>>{};
    for (final stint in stints) {
      stintsByDriver.putIfAbsent(stint.driverNumber, () => []).add(stint);
    }

    // 결과를 기반으로 드라이버 순서 결정 (DNF 포함)
    final sortedDriverNumbers = results.map((r) => r.driverNumber).toList();
    final resultDriverMap = {for (final r in results) r.driverNumber: r};

    if (sortedDriverNumbers.isEmpty) {
      return const Center(
        child: Text(
          '피트스톱 데이터 없음',
          style: TextStyle(color: F1Colors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedDriverNumbers.length,
      itemBuilder: (context, index) {
        final driverNumber = sortedDriverNumbers[index];
        final result = resultDriverMap[driverNumber];
        final driverPits = pitsByDriver[driverNumber] ?? [];
        final driverStints = stintsByDriver[driverNumber] ?? [];

        // 데이터가 아예 없는 경우 표시하지 않음 (DNS 등)
        if (driverPits.isEmpty && driverStints.isEmpty) {
          return const SizedBox.shrink();
        }

        final teamColor = result?.teamColour != null
            ? Color(int.parse('FF${result!.teamColour}', radix: 16))
            : F1Colors.getTeamColor(result?.teamName);

        final driverName = result != null 
            ? localizeDriver(result.nameAcronym, result.broadcastName)
            : '#$driverNumber';
        final teamName = result != null ? localizeTeam(result.teamName) : '';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: F1Colors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 24,
                      color: teamColor,
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    Text(
                      driverName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result?.nameAcronym ?? '',
                      style: const TextStyle(
                        color: F1Colors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      teamName,
                      style: const TextStyle(
                        color: F1Colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (driverStints.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '타이어 스틴트',
                    style: TextStyle(
                      color: F1Colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: driverStints.map((stint) {
                      final compound = stint.compound ?? 'UNKNOWN';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCompoundColor(compound)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getCompoundColor(compound),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: _getCompoundColor(compound),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _localizeCompound(compound),
                              style: TextStyle(
                                color: _getCompoundColor(compound),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'L${stint.lapStart}-L${stint.lapEnd ?? '?'}',
                              style: const TextStyle(
                                color: F1Colors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (driverPits.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '피트스톱',
                    style: TextStyle(
                      color: F1Colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ...driverPits.map((pit) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tire_repair,
                            color: F1Colors.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '랩 ${pit.lapNumber}',
                            style: const TextStyle(
                              color: F1Colors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            pit.formattedDuration,
                            style: const TextStyle(
                              color: F1Colors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _localizeCompound(String compound) {
    switch (compound.toUpperCase()) {
      case 'SOFT':
        return '소프트';
      case 'MEDIUM':
        return '미디엄';
      case 'HARD':
        return '하드';
      case 'INTERMEDIATE':
        return '인터미디어트';
      case 'WET':
        return '풀 웻';
      default:
        return compound;
    }
  }

  Color _getCompoundColor(String compound) {
    switch (compound.toUpperCase()) {
      case 'SOFT':
        return Colors.red;
      case 'MEDIUM':
        return Colors.yellow;
      case 'HARD':
        return Colors.white;
      case 'INTERMEDIATE':
        return Colors.green;
      case 'WET':
        return Colors.blue;
      default:
        return F1Colors.textSecondary;
    }
  }
}
