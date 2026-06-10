import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'models.dart';
import 'repositories.dart';
import 'utils.dart';

// ─── Репозитории ──────────────────────────────────────────────────────────────

final trackRepositoryProvider = Provider<TrackRepository>(
  (ref) => HiveTrackRepository(Hive.box('tracks')),
);

final remoteSourceProvider = Provider<RemoteTrackSource>((ref) => RemoteTrackSource());

// ─── Треки ────────────────────────────────────────────────────────────────────

class TracksNotifier extends StateNotifier<List<Track>> {
  TracksNotifier(this._repo, this._remote) : super(const []) {
    _init();
  }

  final TrackRepository _repo;
  final RemoteTrackSource _remote;

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    state = _repo.all();
  }

  Future<void> addTrack(String title, String artist) async {
    final track = Track(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      artist: artist,
    );
    await _repo.add(track);
    state = _repo.all();
  }

  Future<void> deleteTrack(String id) async {
    await _repo.delete(id);
    state = _repo.all();
  }

  /// Очистка кэша: удаляет все сохранённые данные и восстанавливает значения по умолчанию.
  Future<void> clearCache() async {
    await _repo.clear();
    await _repo.seedIfEmpty();
    state = _repo.all();
  }

  Future<void> toggleFavorite(String id) async {
    final track = state.firstWhere((e) => e.id == id);
    await _repo.update(track.copyWith(favorite: !track.favorite));
    state = _repo.all();
  }

  /// Загрузка из сети с обработкой исключений (офлайн-fallback на кэш).
  Future<bool> loadFromNetwork() async {
    try {
      final remote = await _remote.fetch();
      for (final track in remote) {
        await _repo.add(track);
      }
      state = _repo.all();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('TracksNotifier.loadFromNetwork error: $e');
      return false;
    }
  }
}

final tracksProvider = StateNotifierProvider<TracksNotifier, List<Track>>(
  (ref) => TracksNotifier(ref.watch(trackRepositoryProvider), ref.watch(remoteSourceProvider)),
);

// ─── Аутентификация ─────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({this.loggedIn = false, this.email});

  final bool loggedIn;
  final String? email;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._box) : super(_initial(_box));

  final Box _box;

  static AuthState _initial(Box box) {
    final email = box.get('email') as String?;
    return AuthState(loggedIn: email != null, email: email);
  }

  /// Возвращает ключ ошибки или null при успешном входе. Сессия сохраняется в Hive.
  String? login(String email, String password) {
    final error = validateCredentials(email, password);
    if (error != null) return error;
    final trimmed = email.trim();
    _box.put('email', trimmed);
    state = AuthState(loggedIn: true, email: trimmed);
    return null;
  }

  void logout() {
    _box.delete('email');
    state = const AuthState(loggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(Hive.box('session')),
);

// ─── Тема и язык ────────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(this._box) : super(_load(_box));

  final Box _box;

  static ThemeMode _load(Box box) {
    switch (box.get('themeMode', defaultValue: 'system') as String) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setMode(ThemeMode mode) {
    _box.put('themeMode', mode.name);
    state = mode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(Hive.box('settings')),
);

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._box) : super(_load(_box));

  final Box _box;

  static Locale? _load(Box box) {
    final code = box.get('locale') as String?;
    return code == null ? null : Locale(code);
  }

  void setLocale(Locale? locale) {
    if (locale == null) {
      _box.delete('locale');
    } else {
      _box.put('locale', locale.languageCode);
    }
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(Hive.box('settings')),
);
