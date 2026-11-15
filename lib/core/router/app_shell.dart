import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/live_tv/presentation/live_tv_screen.dart';
import '../../features/live_tv/presentation/live_tv_providers.dart';
import '../theme/app_colors.dart';
import 'tab_provider.dart';

/// Coquille de l'appli : 5 onglets conservés en mémoire (IndexedStack).
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(currentTabProvider);
    final isLive = ref.watch(liveStreamProvider).valueOrNull?.isLive ?? false;

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          HomeScreen(),
          LiveTvScreen(),
          _NextStep(title: 'Médiathèque', icon: Icons.video_library_rounded),
          _NextStep(title: 'Explorer', icon: Icons.explore_rounded),
          _NextStep(title: 'Recherche', icon: Icons.search_rounded),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => ref.read(currentTabProvider.notifier).state = AppTab.values[i],
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          NavigationDestination(
            icon: Badge(isLabelVisible: isLive, backgroundColor: AppColors.live, smallSize: 8, child: const Icon(Icons.live_tv_outlined)),
            selectedIcon: const Icon(Icons.live_tv_rounded),
            label: 'TV Live',
          ),
          const NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library_rounded), label: 'Médiathèque'),
          const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Explorer'),
          const NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Recherche'),
        ],
      ),
    );
  }
}

/// Onglets livrés à l'étape suivante (Médiathèque, Explorer, Recherche).
class _NextStep extends StatelessWidget {
  const _NextStep({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.lilac),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
