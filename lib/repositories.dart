import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import 'models.dart';

/// Репозиторий треков (CRUD). Абстракция позволяет подменять реализацию в тестах.
abstract class TrackRepository {
  Future<void> seedIfEmpty();
  List<Track> all();
  Future<void> add(Track track);
  Future<void> delete(String id);
  Future<void> update(Track track);
  Future<void> clear();
}

/// Реализация поверх Hive — данные сохраняются на устройстве (офлайн-режим).
class HiveTrackRepository implements TrackRepository {
  HiveTrackRepository(this._box);

  final Box _box;

  @override
  Future<void> seedIfEmpty() async {
    if (_box.isNotEmpty) return;
    for (final track in _defaults) {
      await _box.put(track.id, track.toMap());
    }
  }

  @override
  List<Track> all() => _box.values
      .map((e) => Track.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();

  @override
  Future<void> add(Track track) => _box.put(track.id, track.toMap());

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> update(Track track) => _box.put(track.id, track.toMap());

  @override
  Future<void> clear() => _box.clear();

  static final List<Track> _defaults = [
    const Track(id: '1', title: 'Blinding Lights', artist: 'The Weeknd', favorite: true),
    const Track(id: '2', title: 'Levitating', artist: 'Dua Lipa'),
    const Track(id: '3', title: 'Stay', artist: 'The Kid LAROI'),
  ];
}

/// Реализация в памяти — для модульных тестов (без Hive).
class InMemoryTrackRepository implements TrackRepository {
  final List<Track> _list = [];

  @override
  Future<void> seedIfEmpty() async {}

  @override
  List<Track> all() => List.unmodifiable(_list);

  @override
  Future<void> add(Track track) async => _list.add(track);

  @override
  Future<void> delete(String id) async => _list.removeWhere((e) => e.id == id);

  @override
  Future<void> update(Track track) async {
    final index = _list.indexWhere((e) => e.id == track.id);
    if (index >= 0) _list[index] = track;
  }

  @override
  Future<void> clear() async => _list.clear();
}

/// Сетевой источник (Dio): загрузка списка с публичного API без ключа.
class RemoteTrackSource {
  RemoteTrackSource([Dio? dio]) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<Track>> fetch() async {
    final response = await _dio.get<List<dynamic>>(
      'https://jsonplaceholder.typicode.com/albums',
      queryParameters: {'_limit': 5},
    );
    final data = response.data ?? const [];
    return data.map((e) {
      final map = e as Map<String, dynamic>;
      return Track(
        id: 'net_${map['id']}',
        title: map['title'] as String,
        artist: 'Album ${map['userId']}',
      );
    }).toList();
  }
}
