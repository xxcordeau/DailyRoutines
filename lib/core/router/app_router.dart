import 'package:go_router/go_router.dart';
import '../../data/local/hive_service.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/task_edit/screens/task_edit_screen.dart';
import '../../shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final nickname =
        HiveService.settings.get('nickname', defaultValue: '') as String;
    if (nickname.isEmpty && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/task/add',
      builder: (context, state) => const TaskEditScreen(),
    ),
    GoRoute(
      path: '/task/edit/:taskId',
      builder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return TaskEditScreen(taskId: taskId);
      },
    ),
  ],
);
