import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lab9_flutter/l10n/app_localizations.dart';
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

  testWidgets('localization renders parameterized greeting in russian', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context);
            return Scaffold(body: Text(l.homeGreeting('user@example.com')));
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Привет, user@example.com'), findsOneWidget);
  });
}
