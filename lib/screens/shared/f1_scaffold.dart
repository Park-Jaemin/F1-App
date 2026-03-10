import 'package:flutter/material.dart';
import '../../core/theme.dart';

class F1Scaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const F1Scaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(title),
          ],
        ),
        actions: actions,
        leading: leading,
        bottom: bottom,
      ),
      body: body,
    );
  }
}
