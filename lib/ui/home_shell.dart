import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../notification.dart';
import '../providers.dart';
import '../utils.dart';

/// Корневой экран с адаптивной навигацией: NavigationRail на широких экранах,
/// NavigationBar (нижняя навигация) на узких.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const pages = [HomeTab(), TracksTab(), SettingsTab()];
    final items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home, l.navHome),
      (Icons.library_music_outlined, Icons.library_music, l.navTracks),
      (Icons.settings_outlined, Icons.settings, l.navSettings),
    ];

    if (context.isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final it in items)
                  NavigationRailDestination(
                    icon: Icon(it.$1),
                    selectedIcon: Icon(it.$2),
                    label: Text(it.$3),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final it in items)
            NavigationDestination(icon: Icon(it.$1), selectedIcon: Icon(it.$2), label: it.$3),
        ],
      ),
    );
  }
}

// ─── Главная: карточки данных + график ─────────────────────────────────────────

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tracks = ref.watch(tracksProvider);
    final auth = ref.watch(authProvider);
    final favorites = tracks.where((t) => t.favorite).length;
    final others = tracks.length - favorites;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.homeGreeting(auth.email ?? ''), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(label: l.cardTotal, value: '${tracks.length}'),
              _StatCard(label: l.cardFavorites, value: '$favorites'),
            ],
          ),
          const SizedBox(height: 24),
          Text(l.favoritesChart, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: tracks.isEmpty
                ? Center(child: Text(l.noTracks))
                : PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: favorites.toDouble(),
                          color: scheme.primary,
                          title: '$favorites',
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: others.toDouble(),
                          color: scheme.tertiary,
                          title: '$others',
                          radius: 60,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend(scheme.primary, l.favorite),
              const SizedBox(width: 16),
              _legend(scheme.tertiary, l.others),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 6),
          Text(text),
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ─── Треки: список с добавлением/удалением/избранным ─────────────────────────────

class TracksTab extends ConsumerWidget {
  const TracksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tracks = ref.watch(tracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tracksTitle),
        actions: [
          IconButton(
            tooltip: l.loadFromNet,
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: () async {
              final ok = await ref.read(tracksProvider.notifier).loadFromNetwork();
              if (context.mounted && !ok) NotificationService.show(context, l.networkError);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref, l),
        child: const Icon(Icons.add),
      ),
      body: tracks.isEmpty
          ? Center(child: Text(l.noTracks))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, i) {
                final t = tracks[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) async {
                    await ref.read(tracksProvider.notifier).deleteTrack(t.id);
                    if (context.mounted) NotificationService.show(context, l.trackDeleted);
                  },
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete),
                  ),
                  child: ListTile(
                    title: Text(t.title),
                    subtitle: Text(t.artist),
                    trailing: IconButton(
                      icon: Icon(t.favorite ? Icons.favorite : Icons.favorite_border),
                      onPressed: () => ref.read(tracksProvider.notifier).toggleFavorite(t.id),
                    ),
                    onTap: () => context.go('/detail/${t.id}'),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final title = TextEditingController();
    final artist = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addTrack),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: InputDecoration(labelText: l.trackTitle)),
            TextField(controller: artist, decoration: InputDecoration(labelText: l.trackArtist)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty) return;
              ref.read(tracksProvider.notifier).addTrack(title.text.trim(), artist.text.trim());
              Navigator.pop(ctx);
              NotificationService.show(context, l.trackAdded);
            },
            child: Text(l.add),
          ),
        ],
      ),
    );
    title.dispose();
    artist.dispose();
  }
}

// ─── Настройки: тема, язык, очистка кэша, версия, выход ──────────────────────────

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.theme, style: Theme.of(context).textTheme.titleMedium),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeProvider.notifier).setMode(m!),
            title: Text(l.themeSystem),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeProvider.notifier).setMode(m!),
            title: Text(l.themeLight),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeProvider.notifier).setMode(m!),
            title: Text(l.themeDark),
          ),
          const Divider(),
          ListTile(
            title: Text(l.language),
            trailing: DropdownButton<String?>(
              value: locale?.languageCode,
              items: [
                DropdownMenuItem(value: null, child: Text(l.themeSystem)),
                const DropdownMenuItem(value: 'ru', child: Text('Русский')),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'be', child: Text('Беларуская')),
              ],
              onChanged: (code) => ref
                  .read(localeProvider.notifier)
                  .setLocale(code == null ? null : Locale(code)),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: Text(l.clearCache),
            onTap: () async {
              await ref.read(tracksProvider.notifier).clearCache();
              if (context.mounted) NotificationService.show(context, l.cacheCleared);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.appVersion('1.0.0')),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l.logout),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
