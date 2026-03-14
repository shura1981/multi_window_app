import 'package:flutter/material.dart';

/// Simple notifier to request a data refresh from outside the widget tree.
class MainWindowRefreshNotifier extends ChangeNotifier {
  MainWindowRefreshNotifier._();

  static final instance = MainWindowRefreshNotifier._();

  void requestRefresh() => notifyListeners();
}
