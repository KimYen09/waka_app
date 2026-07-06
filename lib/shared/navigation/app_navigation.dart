import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppNavigation {
  static void goBackOrExit(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    SystemNavigator.pop();
  }

  static void replaceAll(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => page),
      (route) => false,
    );
  }
}
