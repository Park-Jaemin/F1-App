import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/race_control_message.dart';

class RaceControlFeed extends StatelessWidget {
  final List<RaceControlMessage> messages;

  const RaceControlFeed({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '레이스 컨트롤',
            style: TextStyle(
              color: F1Colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...messages.take(20).map((msg) => _RaceControlItem(message: msg)),
      ],
    );
  }
}

class _RaceControlItem extends StatelessWidget {
  final RaceControlMessage message;

  const _RaceControlItem({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: F1Colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FlagIndicator(flag: message.flag),
          const SizedBox(width: 8),
          if (message.lapNumber != null)
            SizedBox(
              width: 48,
              child: Text(
                'LAP ${message.lapNumber}',
                style: const TextStyle(
                  color: F1Colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.message,
              style: const TextStyle(
                color: F1Colors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagIndicator extends StatelessWidget {
  final String? flag;

  const _FlagIndicator({this.flag});

  @override
  Widget build(BuildContext context) {
    final color = _flagColor(flag);
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Color _flagColor(String? flag) {
    switch (flag) {
      case 'RED':
        return Colors.red;
      case 'YELLOW':
      case 'DOUBLE YELLOW':
        return Colors.yellow;
      case 'GREEN':
        return Colors.green;
      case 'BLUE':
        return Colors.blue;
      case 'BLACK AND WHITE':
        return Colors.grey;
      case 'CHEQUERED':
        return Colors.white;
      default:
        return F1Colors.textSecondary;
    }
  }
}
