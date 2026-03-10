import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/race_detail/race_detail_screen.dart';
import '../screens/standings/standings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'race/:meetingKey/:meetingName',
                  builder: (context, state) {
                    final meetingKey =
                        int.parse(state.pathParameters['meetingKey']!);
                    final meetingName =
                        Uri.decodeComponent(state.pathParameters['meetingName']!);
                    return RaceDetailScreen(
                      meetingKey: meetingKey,
                      meetingName: meetingName,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/standings',
              builder: (context, state) => const StandingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '시즌',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '순위',
          ),
        ],
      ),
    );
  }
}
