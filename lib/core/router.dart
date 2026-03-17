import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/race_detail/race_detail_screen.dart';
import '../screens/live/live_screen.dart';
import '../screens/replay/replay_screen.dart';
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
                GoRoute(
                  path: 'replay/:meetingName/:sessionKey/:sessionName',
                  builder: (context, state) {
                    final meetingName = Uri.decodeComponent(
                        state.pathParameters['meetingName']!);
                    final sessionKey =
                        int.parse(state.pathParameters['sessionKey']!);
                    final sessionName = Uri.decodeComponent(
                        state.pathParameters['sessionName']!);
                    return ReplayScreen(
                      sessionKey: sessionKey,
                      meetingName: meetingName,
                      sessionName: sessionName,
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/live',
              builder: (context, state) => const LiveScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: '라이브',
          ),
        ],
      ),
    );
  }
}
