import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab9_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user logs in and reaches the home shell', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Экран входа: два поля (email предзаполнен, пароль пустой).
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(1), 'password');

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // После входа отображается адаптивная навигация.
    final hasNav = find.byType(NavigationBar).evaluate().isNotEmpty ||
        find.byType(NavigationRail).evaluate().isNotEmpty;
    expect(hasNav, isTrue);
  });
}
