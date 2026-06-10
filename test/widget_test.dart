import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lab9_flutter/l10n/app_localizations.dart';
import 'package:lab9_flutter/ui/home_shell.dart';
import 'package:lab9_flutter/ui/login_screen.dart';

Widget _harness(Widget child) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('lab9_hive');
    Hive.init(dir.path);
    await Hive.openBox('tracks');
    await Hive.openBox('session');
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('login screen shows title and button', (tester) async {
    await tester.pumpWidget(_harness(const LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('short password shows validation error', (tester) async {
    await tester.pumpWidget(_harness(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'ab');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Пароль не короче 4 символов'), findsOneWidget);
  });

  testWidgets('home shows the total-tracks card with seeded data', (tester) async {
    await tester.pumpWidget(_harness(const HomeShell()));
    await tester.pumpAndSettle();

    expect(find.text('Всего треков'), findsOneWidget);
    expect(find.text('Главная'), findsWidgets);
  });
}
