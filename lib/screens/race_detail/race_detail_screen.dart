import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/korean_locale.dart';
import '../../core/theme.dart';
import '../../providers/meetings_provider.dart';
import '../shared/error_widget.dart';
import '../shared/loading_widget.dart';
import 'widgets/pit_stops_tab.dart';
import 'widgets/result_list.dart';

class RaceDetailScreen extends ConsumerWidget {
  final int meetingKey;
  final String meetingName;

  const RaceDetailScreen({
    super.key,
    required this.meetingKey,
    required this.meetingName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider(meetingKey));

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Scaffold(
            backgroundColor: F1Colors.background,
            appBar: AppBar(
              backgroundColor: F1Colors.background,
              title: Text(localizeGrandPrix(meetingName)),
            ),
            body: const Center(
              child: Text(
                '세션 정보가 없습니다',
                style: TextStyle(color: F1Colors.textSecondary),
              ),
            ),
          );
        }

        // 완료된 세션만 노출 (미완료 세션은 결과 API에서 404 발생 가능)
        final completedSessions = sessions
            .where((s) => s.isCompleted)
            .toList()
          ..sort((a, b) => a.dateStart.compareTo(b.dateStart));

        if (completedSessions.isEmpty) {
          return Scaffold(
            backgroundColor: F1Colors.background,
            appBar: AppBar(
              backgroundColor: F1Colors.background,
              title: Text(localizeGrandPrix(meetingName)),
            ),
            body: const Center(
              child: Text(
                '완료된 세션이 없습니다',
                style: TextStyle(color: F1Colors.textSecondary),
              ),
            ),
          );
        }

        // 레이스 세션 찾기 (피트스톱 탭을 위해)
        final raceSession =
            completedSessions.where((s) => s.isRace).firstOrNull;

        // 탭 구성: 모든 세션 + (레이스가 있다면) 피트스톱
        final tabsCount =
            completedSessions.length + (raceSession != null ? 1 : 0);

        return DefaultTabController(
          length: tabsCount,
          initialIndex:
              (completedSessions.length - 1).clamp(0, tabsCount - 1), // 기본으로 마지막 세션(보통 레이스) 선택
          child: Scaffold(
            backgroundColor: F1Colors.background,
            appBar: AppBar(
              backgroundColor: F1Colors.background,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizeGrandPrix(meetingName),
                    style: const TextStyle(
                      color: F1Colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              bottom: TabBar(
                isScrollable: true,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                tabAlignment: TabAlignment.center,
                tabs: [
                  ...completedSessions
                      .map((s) => Tab(text: localizeSession(s.sessionName))),
                  if (raceSession != null) const Tab(text: '피트스톱'),
                ],
                labelColor: F1Colors.primary,
                unselectedLabelColor: F1Colors.textSecondary,
                indicatorColor: F1Colors.primary,
              ),
            ),
            body: _LazyTabBarView(
              length: tabsCount,
              builder: (context, index) {
                if (index < completedSessions.length) {
                  final session = completedSessions[index];
                  return ResultList(
                    sessionKey: session.sessionKey,
                    isPractice: session.isPractice,
                    isQualifying: session.isQualifying,
                  );
                }
                if (raceSession != null &&
                    index == completedSessions.length) {
                  return PitStopsTab(sessionKey: raceSession.sessionKey);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: F1Colors.background,
        appBar: AppBar(backgroundColor: F1Colors.background),
        body: const F1LoadingWidget(),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: F1Colors.background,
        appBar: AppBar(backgroundColor: F1Colors.background),
        body: F1ErrorWidget(error: error),
      ),
    );
  }
}

class _LazyTabBarView extends StatefulWidget {
  final int length;
  final IndexedWidgetBuilder builder;

  const _LazyTabBarView({
    required this.length,
    required this.builder,
  });

  @override
  State<_LazyTabBarView> createState() => _LazyTabBarViewState();
}

class _LazyTabBarViewState extends State<_LazyTabBarView> {
  TabController? _controller;
  final Set<int> _loaded = <int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (controller == _controller) return;

    _controller?.removeListener(_onControllerChanged);
    _controller = controller;
    _syncLoaded();
    _controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _LazyTabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.length < oldWidget.length) {
      _loaded.removeWhere((i) => i >= widget.length);
    }
    _syncLoaded();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _syncLoaded();
  }

  void _syncLoaded() {
    final controller = _controller;
    if (controller == null) return;
    final current = controller.index;
    var changed = false;
    changed = _markLoaded(current) || changed;
    changed = _markLoaded(current - 1) || changed;
    changed = _markLoaded(current + 1) || changed;
    if (changed && mounted) {
      setState(() {});
    }
  }

  bool _markLoaded(int index) {
    if (index < 0 || index >= widget.length) return false;
    return _loaded.add(index);
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: List.generate(widget.length, (index) {
        if (_loaded.contains(index)) {
          return widget.builder(context, index);
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
