import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/events/presentation/events_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/live_tv/presentation/live_tv_providers.dart';
import '../../features/live_tv/presentation/live_tv_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../analytics/analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/music_life_logo.dart';
import '../widgets/responsive.dart';
import 'tab_provider.dart';

/// Coquille de l'appli : 5 onglets conservés en mémoire.
/// • Téléphone : barre d'onglets en bas.
/// • Tablette, ordinateur, TV : menu latéral à gauche.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    Analytics.visit(); // 1 visiteur unique par jour
  }

  static const _pages = [HomeScreen(), LiveTvScreen(), LibraryScreen(), EventsScreen(), SearchScreen()];

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(currentTabProvider);
    final isLive = ref.watch(liveStreamProvider).valueOrNull?.canPlay ?? false;
    void select(int i) => ref.read(currentTabProvider.notifier).state = AppTab.values[i];

    Widget liveIcon(IconData icon) =>
        Badge(isLabelVisible: isLive, backgroundColor: AppColors.live, smallSize: 8, child: Icon(icon));

    final destinations = <(Widget, Widget, String)>[
      (const Icon(Icons.home_outlined), const Icon(Icons.home_rounded), 'Accueil'),
      (liveIcon(Icons.live_tv_outlined), liveIcon(Icons.live_tv_rounded), 'TV Live'),
      (const Icon(Icons.library_music_outlined), const Icon(Icons.library_music_rounded), 'Bibliothèque'),
      (const Icon(Icons.event_outlined), const Icon(Icons.event_rounded), 'Événements'),
      (const Icon(Icons.search_rounded), const Icon(Icons.search_rounded), 'Recherche'),
    ];

    final body = IndexedStack(index: tab.index, children: _pages);

    if (Breakpoints.isWide(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: const Color(0xFF120019),
              selectedIndex: tab.index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.violet,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: MusicLifeLogo(width: 96, cutoutColor: Color(0xFF120019)),
              ),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.mist, fontSize: 12),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: const IconThemeData(color: AppColors.mist),
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(icon: icon, selectedIcon: selected, label: Text(label)),
              ],
            ),
            const VerticalDivider(width: 1, color: Colors.white12),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: select,
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(icon: icon, selectedIcon: selected, label: label),
        ],
      ),
    );
  }
}
