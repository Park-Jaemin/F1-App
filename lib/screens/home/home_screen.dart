import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/meeting.dart';
import '../../providers/meetings_provider.dart';
import '../shared/error_widget.dart';
import '../shared/loading_widget.dart';
import '../shared/year_selector.dart';
import 'widgets/gp_chip.dart';
import 'widgets/podium_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Meeting? _selectedMeeting;
  final ScrollController _chipScrollController = ScrollController();

  @override
  void dispose() {
    _chipScrollController.dispose();
    super.dispose();
  }

  void _autoSelect(List<Meeting> meetings) {
    if (meetings.isEmpty || _selectedMeeting != null) return;

    final now = DateTime.now();
    final past = meetings.where((m) => m.dateStart.isBefore(now)).toList();

    Meeting target;
    if (past.isEmpty || past.length == meetings.length) {
      // 시즌 시작 전이거나 시즌이 완전히 종료된 경우 첫 번째 그랑프리 선택
      target = meetings.first;
    } else {
      // 시즌 진행 중인 경우 완료된 레이스 중 가장 최근 레이스 선택
      target = past.last;
    }

    // build 중에 setState 방지
    Future.microtask(() {
      if (!mounted || _selectedMeeting != null) return;

      setState(() {
        _selectedMeeting = target;
      });

      // 선택된 아이템으로 스크롤
      final index = meetings.indexOf(target);
      if (_chipScrollController.hasClients && index >= 0) {
        _chipScrollController.animateTo(
          index * 92.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedYear = ref.watch(selectedYearProvider);
    final meetingsAsync = ref.watch(meetingsProvider(selectedYear));

    // 연도 변경 시 선택 초기화
    ref.listen(selectedYearProvider, (prev, next) {
      setState(() => _selectedMeeting = null);
    });

    return Scaffold(
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
              'FORMULA 1',
              style: TextStyle(
                color: F1Colors.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
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
      ),
      body: Column(
        children: [
          // ─── GP 수평 스크롤 목록 ─────────────────────────────
          SizedBox(
            height: 110,
            child: meetingsAsync.when(
              data: (meetings) {
                _autoSelect(meetings);
                if (meetings.isEmpty) {
                  return const Center(
                    child: Text(
                      '데이터 없음',
                      style: TextStyle(color: F1Colors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _chipScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    return GpChip(
                      meeting: meeting,
                      roundNumber: index + 1,
                      isSelected:
                          _selectedMeeting?.meetingKey ==
                              meeting.meetingKey,
                      onTap: () {
                        setState(() => _selectedMeeting = meeting);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: F1LoadingWidget()),
              error: (error, _) => Center(
                child: F1ErrorWidget(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(meetingsProvider(selectedYear)),
                ),
              ),
            ),
          ),
          // ─── 구분선 ─────────────────────────────────────────
          const Divider(height: 1, color: F1Colors.divider),
          // ─── 포디엄 섹션 ─────────────────────────────────────
          Expanded(
            child: _selectedMeeting == null
                ? const Center(
                    child: Text(
                      '그랑프리를 선택해주세요',
                      style: TextStyle(color: F1Colors.textSecondary),
                    ),
                  )
                : PodiumSection(meeting: _selectedMeeting!),
          ),
        ],
      ),
    );
  }
}
