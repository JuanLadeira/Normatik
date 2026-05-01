import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/theme_provider.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          if (isWide)
            Container(
              width: MediaQuery.of(context).size.width >= 900 ? 220 : 80,
              color: NormatiqColors.primary600,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: NormatiqLogo(size: 28, isDark: true),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  Expanded(
                    child: NavigationRail(
                      extended: MediaQuery.of(context).size.width >= 900,
                      backgroundColor: Colors.transparent,
                      unselectedIconTheme: const IconThemeData(color: Colors.white60),
                      selectedIconTheme: const IconThemeData(color: NormatiqColors.accent100),
                      unselectedLabelTextStyle: const TextStyle(color: Colors.white60),
                      selectedLabelTextStyle: const TextStyle(color: Colors.white),
                      indicatorColor: Colors.white12,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.grid_view_outlined),
                          selectedIcon: Icon(Icons.grid_view),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.straighten_outlined),
                          selectedIcon: Icon(Icons.straighten),
                          label: Text('Calibrações'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.science_outlined),
                          selectedIcon: Icon(Icons.science),
                          label: Text('Padrões'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.people_outline),
                          selectedIcon: Icon(Icons.people),
                          label: Text('Clientes'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.group_outlined),
                          selectedIcon: Icon(Icons.group),
                          label: Text('Usuários'),
                        ),
                      ],
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: (index) => navigationShell.goBranch(index),
                    ),
                  ),
                  
                  const Divider(color: Colors.white10, height: 1),
                  
                  // Botões de Sistema
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Column(
                      children: [
                        ListTile(
                          visualDensity: VisualDensity.compact,
                          leading: Icon(
                            themeMode == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          title: MediaQuery.of(context).size.width >= 900 
                            ? Text(themeMode == ThemeMode.light ? "Tema Escuro" : "Tema Claro", 
                                style: const TextStyle(color: Colors.white70, fontSize: 13)) 
                            : null,
                          onTap: () {
                            ref.read(themeModeProvider.notifier).state = 
                              themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                          },
                        ),
                        ListTile(
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(Icons.logout_outlined, color: Color(0xFFFDA4AF), size: 20),
                          title: MediaQuery.of(context).size.width >= 900 
                            ? const Text("Sair", style: TextStyle(color: Colors.white70, fontSize: 13)) 
                            : null,
                          onTap: () => ref.read(authProvider.notifier).logout(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 1),
                  
                  // User Profile Mini
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: NormatiqColors.accent500,
                          child: Text("JL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: NormatiqColors.primary600)),
                        ),
                        if (MediaQuery.of(context).size.width >= 900) ...[
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Juan Ladeira", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text("Admin", style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: navigationShell.currentIndex,
              selectedItemColor: NormatiqColors.primary600,
              unselectedItemColor: NormatiqColors.neutral400,
              onTap: (index) => navigationShell.goBranch(index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Início'),
                BottomNavigationBarItem(icon: Icon(Icons.straighten), label: 'Ops'),
                BottomNavigationBarItem(icon: Icon(Icons.science), label: 'Lab'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
                BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Usuários'),
              ],
            ),
    );
  }
}
