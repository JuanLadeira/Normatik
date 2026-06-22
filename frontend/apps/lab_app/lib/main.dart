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
import 'features/settings/settings_hub_page.dart';
import 'features/settings/grandezas_settings_page.dart';
import 'features/settings/tipos_instrumento_settings_page.dart';
import 'features/settings/templates_medicao_page.dart';
import 'features/clientes/clientes_list_page.dart';
import 'features/clientes/cliente_detail_page.dart';
import 'features/clientes/cliente_form_page.dart';
import 'features/padroes/padroes_list_page.dart';
import 'features/padroes/padrao_detail_page.dart';
import 'features/padroes/padrao_form_page.dart';
import 'features/padroes/certificado_form_page.dart';
import 'features/padroes/certificado_detail_page.dart';
import 'features/padroes/certificado_analise_page.dart';
import 'features/instrumentos/instrumentos_list_page.dart';
import 'features/instrumentos/instrumento_detail_page.dart';
import 'features/instrumentos/instrumento_form_page.dart';
import 'core/theme/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: NormatiqLabApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorOpsKey = GlobalKey<NavigatorState>(debugLabel: 'ops');
final _shellNavigatorLabKey = GlobalKey<NavigatorState>(debugLabel: 'lab');
final _shellNavigatorClientsKey =
    GlobalKey<NavigatorState>(debugLabel: 'clients');
final _shellNavigatorMoreKey = GlobalKey<NavigatorState>(debugLabel: 'more');

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isPublicRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/accept-invite';
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
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // ── Branch 0: Dashboard ───────────────��──────────────────────────
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),

          // ── Branch 1: Operações (OS + Calibrações — implementar em próxima fase) ──
          StatefulShellBranch(
            navigatorKey: _shellNavigatorOpsKey,
            routes: [
              GoRoute(
                path: '/operacoes',
                builder: (context, state) => const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.straighten_outlined,
                            size: 48, color: NormatiqColors.neutral400),
                        SizedBox(height: 12),
                        Text('OS & Calibrações',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Disponível na próxima fase.',
                            style: TextStyle(
                                color: NormatiqColors.neutral500,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Branch 2: Laboratório — Padrões ──────────────────────────────
          StatefulShellBranch(
            navigatorKey: _shellNavigatorLabKey,
            routes: [
              GoRoute(
                path: '/padroes',
                builder: (context, state) => const PadroesListPage(),
                routes: [
                  GoRoute(
                    path: 'novo',
                    builder: (context, state) => const PadraoFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PadraoDetailPage(
                      padraoId: int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'editar',
                        builder: (context, state) => PadraoFormPage(
                          padraoId:
                              int.parse(state.pathParameters['id']!),
                        ),
                      ),
                      GoRoute(
                        path: 'certificados/novo',
                        builder: (context, state) => CertificadoFormPage(
                          padraoId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                      GoRoute(
                        path: 'certificados/:certId',
                        builder: (context, state) => CertificadoDetailPage(
                          padraoId: int.parse(state.pathParameters['id']!),
                          certId: int.parse(state.pathParameters['certId']!),
                        ),
                        routes: [
                          GoRoute(
                            path: 'analise',
                            builder: (context, state) {
                              final extra =
                                  state.extra as Map<String, dynamic>? ?? {};
                              return CertificadoAnalisePage(
                                certId: int.parse(
                                    state.pathParameters['certId']!),
                                campos:
                                    extra['campos'] as List<dynamic>? ?? [],
                                campoXDefault:
                                    extra['campo_x'] as String?,
                                campoYDefault:
                                    extra['campo_y'] as String?,
                                tipoDefault:
                                    extra['tipo'] as String? ?? 'linear',
                                grauDefault:
                                    extra['grau'] as int? ?? 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 3: Clientes & Instrumentos ────────────────────────────
          StatefulShellBranch(
            navigatorKey: _shellNavigatorClientsKey,
            routes: [
              GoRoute(
                path: '/clientes',
                builder: (context, state) => const ClientesListPage(),
                routes: [
                  GoRoute(
                    path: 'novo',
                    builder: (context, state) => const ClienteFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ClienteDetailPage(
                      clienteId:
                          int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'editar',
                        builder: (context, state) => ClienteFormPage(
                          clienteId:
                              int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/instrumentos',
                builder: (context, state) => const InstrumentosListPage(),
                routes: [
                  GoRoute(
                    path: 'novo',
                    builder: (context, state) {
                      final clienteId = state.uri.queryParameters['clienteId'];
                      return InstrumentoFormPage(
                        clienteIdInicial: clienteId != null
                            ? int.tryParse(clienteId)
                            : null,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => InstrumentoDetailPage(
                      instrumentoId:
                          int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'editar',
                        builder: (context, state) => InstrumentoFormPage(
                          instrumentoId:
                              int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 4: Configurações ──────────────────────────────────────
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMoreKey,
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const SettingsHubPage(),
                routes: [
                  GoRoute(
                    path: 'usuarios',
                    builder: (context, state) => const UsersPage(),
                  ),
                  GoRoute(
                    path: 'grandezas',
                    builder: (context, state) =>
                        const GrandezasSettingsPage(),
                  ),
                  GoRoute(
                    path: 'tipos-instrumento',
                    builder: (context, state) =>
                        const TiposInstrumentoSettingsPage(),
                  ),
                  GoRoute(
                    path: 'templates-medicao',
                    builder: (context, state) =>
                        const TemplatesMedicaoPage(),
                  ),
                ],
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
