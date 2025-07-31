import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/messaging/presentation/pages/chat_list_page.dart';
import '../features/messaging/presentation/pages/chat_room_page.dart';
import '../features/calling/presentation/pages/call_page.dart';
import '../features/calling/presentation/widgets/call_invitation_dialog.dart';
import '../features/meetings/presentation/pages/meeting_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/scanner/presentation/pages/scanner_page.dart';
import '../features/tasks/presentation/pages/task_list_page.dart';
import '../features/maintenance/presentation/pages/maintenance_page.dart';
import 'theme/app_theme.dart';

class SEWSConnectApp extends ConsumerWidget {
  const SEWSConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SEWS Connect',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return CallInvitationListener(
          child: child!,
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatListPage(),
    ),
    GoRoute(
      path: '/chat/:chatId',
      builder: (context, state) => ChatRoomPage(
        chatId: state.pathParameters['chatId']!,
      ),
    ),
    GoRoute(
      path: '/call',
      builder: (context, state) => const CallPage(),
    ),
    GoRoute(
      path: '/meeting',
      builder: (context, state) => const MeetingPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerPage(),
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) => const TaskListPage(),
    ),
    GoRoute(
      path: '/maintenance',
      builder: (context, state) => const MaintenancePage(),
    ),
  ],
);
