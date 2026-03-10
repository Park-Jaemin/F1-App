import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/meetings_provider.dart';

class F1YearSelector extends ConsumerWidget {
  const F1YearSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedYearProvider);
    final currentYear = DateTime.now().year;
    
    // 2021년부터 현재 연도까지 역순 리스트 생성
    final years = List.generate(
      currentYear - 2023 + 1,
      (i) => 2023 + i
    ).reversed.toList();

    return DropdownButton<int>(
      value: selectedYear,
      dropdownColor: F1Colors.surfaceVariant,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.expand_more, color: F1Colors.textSecondary, size: 18),
      style: const TextStyle(
        color: F1Colors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      items: years
          .map(
            (year) => DropdownMenuItem<int>(
              value: year,
              child: Text(
                '$year 시즌',
                style: TextStyle(
                  color: selectedYear == year
                      ? F1Colors.primary
                      : F1Colors.textPrimary,
                  fontWeight: selectedYear == year
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (year) {
        if (year != null) {
          ref.read(selectedYearProvider.notifier).state = year;
        }
      },
    );
  }
}
