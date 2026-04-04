import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/sport_provider.dart';
import '../../../core/constants/sport_config.dart';

class SportsListScreen extends ConsumerWidget {
  const SportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsAsync = ref.watch(allSportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports'),
      ),
      body: sportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(allSportsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (sports) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(allSportsProvider),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: sports.length,
            itemBuilder: (context, index) {
              final sport = sports[index];
              final config = SportConfig.getConfig(sport['name'] ?? '');

              return _SportTile(
                name: sport['display_name'] ?? sport['name'] ?? '',
                icon: config.icon,
                color: config.color,
                format: sport['match_format'] ?? 'individual',
                teamSize: '${sport['team_size_min']}-${sport['team_size_max']}',
                onTap: () => context.push('/sport/${sport['id']}'),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SportTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String format;
  final String teamSize;
  final VoidCallback onTap;

  const _SportTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.format,
    required this.teamSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '$teamSize joueurs',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
