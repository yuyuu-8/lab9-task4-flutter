import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../notification.dart';
import '../providers.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tracks = ref.watch(tracksProvider);
    final matches = tracks.where((t) => t.id == trackId);
    final track = matches.isEmpty ? null : matches.first;

    return Scaffold(
      appBar: AppBar(title: Text(l.detailTitle)),
      body: track == null
          ? Center(child: Text(l.noTracks))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(track.artist, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.read(tracksProvider.notifier).toggleFavorite(track.id),
                    icon: Icon(track.favorite ? Icons.favorite : Icons.favorite_border),
                    label: Text(track.favorite ? l.unmarkFavorite : l.markFavorite),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(tracksProvider.notifier).deleteTrack(track.id);
                      if (context.mounted) {
                        NotificationService.show(context, l.trackDeleted);
                        context.pop();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l.delete),
                  ),
                ],
              ),
            ),
    );
  }
}
