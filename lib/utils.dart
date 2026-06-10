import 'package:flutter/widgets.dart';

/// Граница перехода между «узким» (мобильным) и «широким» (десктоп) макетами.
const double kWideBreakpoint = 800;

/// Responsive-расширения на [BuildContext] (без жёстких пикселей).
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isWide => screenWidth >= kWideBreakpoint;
}

/// Валидация учётных данных. Возвращает ключ ошибки локализации или null.
String? validateCredentials(String email, String password) {
  if (email.trim().isEmpty || !email.contains('@')) return 'invalidEmail';
  if (password.length < 4) return 'shortPassword';
  return null;
}
