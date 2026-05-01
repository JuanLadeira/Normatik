import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'features/auth/login_page.dart';
import 'features/auth/accept_invite_page.dart';
import 'features/auth/auth_provider.dart';
import 'features/home/main_shell.dart';
import 'features/home/dashboard_page.dart';
import 'features/settings/users_page.dart';
import 'core/theme/theme_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: NormatiqLabApp(),
    ),
  );
}

// Provedor do GoRouter integrado com Auth
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorOpsKey = GlobalKey<NavigatorState>(debugLabel: 'ops');
final _shellNavigatorLabKey = GlobalKey<NavigatorState>(debugLabel: 'lab');
final _shellNavigatorClientsKey = GlobalKey<NavigatorState>(debugLabel: 'clients');
final _shellNavigatorMoreKey = GlobalKey<NavigatorState>(debugLabel: 'more');

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isPublicRoute = state.matchedLocation == '/login' || state.matchedLocation == '/accept-invite';
      final isAuthenticated = authState.status == AuthStatus.authenticated;

      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && state.matchedLocation == '/login') return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/accept-invite',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return AcceptInvitePage(token: token);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorOpsKey,
            routes: [
              GoRoute(
                path: '/operations',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text("Operações (Calibrações)")),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorLabKey,
            routes: [
              GoRoute(
                path: '/laboratory',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text("Laboratório (Padrões)")),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorClientsKey,
            routes: [
              GoRoute(
                path: '/clients',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text("Clientes & Instrumentos")),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMoreKey,
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const UsersPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class NormatiqLabApp extends ConsumerWidget {
  const NormatiqLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Normatiq Lab',
      theme: NormatiqTheme.light,
      darkTheme: NormatiqTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
