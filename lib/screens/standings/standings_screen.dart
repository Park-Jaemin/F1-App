import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/meetings_provider.dart';
import '../../providers/standings_provider.dart';
import '../shared/error_widget.dart';
import '../shared/loading_widget.dart';
import '../shared/year_selector.dart';
import 'widgets/driver_row.dart';
import 'widgets/team_row.dart';

class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedYearProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: F1Colors.background,
        appBar: AppBar(
          backgroundColor: F1Colors.background,
          title: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                color: F1Colors.primary,
                margin: const EdgeInsets.only(right: 10),
              ),
              const Text(
                '챔피언십 순위',
                style: TextStyle(
                  color: F1Colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: F1YearSelector(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.person, size: 18),
                text: '드라이버',
              ),
              Tab(
                icon: Icon(Icons.groups, size: 18),
                text: '컨스트럭터',
              ),
            ],
            labelColor: F1Colors.primary,
            unselectedLabelColor: F1Colors.textSecondary,
            indicatorColor: F1Colors.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _DriverStandingsView(year: selectedYear),
            _TeamStandingsView(year: selectedYear),
          ],
        ),
      ),
    );
  }
}

class _DriverStandingsView extends ConsumerWidget {
  final int year;

  const _DriverStandingsView({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(driverStandingsProvider(year));

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return const Center(
            child: Text(
              '순위 데이터 없음',
              style: TextStyle(color: F1Colors.textSecondary),
            ),
          );
        }
        return RefreshIndicator(
          color: F1Colors.primary,
          backgroundColor: F1Colors.surface,
          onRefresh: () async {
            ref.invalidate(driverStandingsProvider(year));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: standings.length,
            itemBuilder: (context, index) =>
                DriverRow(standing: standings[index]),
          ),
        );
      },
      loading: () => const F1LoadingWidget(),
      error: (error, _) => F1ErrorWidget(
        error: error,
        onRetry: () => ref.invalidate(driverStandingsProvider(year)),
      ),
    );
  }
}

class _TeamStandingsView extends ConsumerWidget {
  final int year;

  const _TeamStandingsView({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(teamStandingsProvider(year));

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return const Center(
            child: Text(
              '순위 데이터 없음',
              style: TextStyle(color: F1Colors.textSecondary),
            ),
          );
        }
        return RefreshIndicator(
          color: F1Colors.primary,
          backgroundColor: F1Colors.surface,
          onRefresh: () async {
            ref.invalidate(teamStandingsProvider(year));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: standings.length,
            itemBuilder: (context, index) =>
                TeamRow(standing: standings[index]),
          ),
        );
      },
      loading: () => const F1LoadingWidget(),
      error: (error, _) => F1ErrorWidget(
        error: error,
        onRetry: () => ref.invalidate(teamStandingsProvider(year)),
      ),
    );
  }
}
