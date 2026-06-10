import 'package:flutter/material.dart';

/// Кроссплатформенные уведомления. На мобильных/десктоп/web показывается
/// SnackBar (аналог Toast); на Android/iOS может быть заменён на push-уведомления.
class NotificationService {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}
