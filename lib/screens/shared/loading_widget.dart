import 'package:flutter/material.dart';
import '../../core/theme.dart';

class F1LoadingWidget extends StatelessWidget {
  const F1LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: F1Colors.primary,
        strokeWidth: 3,
      ),
    );
  }
}
