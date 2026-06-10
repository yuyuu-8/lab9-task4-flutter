import 'package:flutter_test/flutter_test.dart';
import 'package:lab9_flutter/models.dart';
import 'package:lab9_flutter/providers.dart';
import 'package:lab9_flutter/repositories.dart';
import 'package:lab9_flutter/utils.dart';

void main() {
  group('validateCredentials', () {
    test('rejects invalid email', () {
      expect(validateCredentials('not-an-email', 'password'), 'invalidEmail');
    });
    test('rejects short password', () {
      expect(validateCredentials('user@example.com', '12'), 'shortPassword');
    });
    test('accepts valid credentials', () {
      expect(validateCredentials('user@example.com', '1234'), isNull);
    });
  });

  test('Track round-trips through Map', () {
    const track = Track(id: '1', title: 'Title', artist: 'Artist', favorite: true);
    final restored = Track.fromMap(track.toMap());
    expect(restored.id, '1');
    expect(restored.title, 'Title');
    expect(restored.artist, 'Artist');
    expect(restored.favorite, isTrue);
  });

  group('TracksNotifier', () {
    test('adds and deletes a track', () async {
      final notifier = TracksNotifier(InMemoryTrackRepository(), RemoteTrackSource());
      await Future<void>.delayed(Duration.zero); // дать завершиться _init()

      await notifier.addTrack('Song', 'Band');
      expect(notifier.state.length, 1);

      final id = notifier.state.first.id;
      await notifier.deleteTrack(id);
      expect(notifier.state, isEmpty);
    });

    test('toggles favorite', () async {
      final notifier = TracksNotifier(InMemoryTrackRepository(), RemoteTrackSource());
      await Future<void>.delayed(Duration.zero);

      await notifier.addTrack('Song', 'Band');
      final id = notifier.state.first.id;
      await notifier.toggleFavorite(id);
      expect(notifier.state.first.favorite, isTrue);
    });
  });
}
