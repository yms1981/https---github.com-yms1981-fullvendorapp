import 'dart:async';

import 'package:flutter/material.dart';

class FullVendor {
  static FullVendor? _instance;

  static FullVendor get instance => _instance ??= FullVendor._();

  FullVendor._() {}

  factory FullVendor() => instance;

  GlobalKey<NavigatorState> navigationKey = GlobalKey(debugLabel: 'FullVendorRouter');
  GlobalKey key = GlobalKey(debugLabel: 'FullVendorApp');
  GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

  late BuildContext currentContext;

  BuildContext get context => navigationKey.currentContext ?? currentContext;

  void routeReplace(String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  Future<dynamic> pushNamed(
    String path, {
    Object? parameters,
  }) async {
    return await navigationKey.currentState?.pushNamed(path, arguments: parameters);
    // return await context.pushNamed(path, queryParameters: parameters);
  }

  void pushReplacement(String path) {
    Navigator.of(context).pushReplacementNamed(path);
  }

  void pushReplacementAll(String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (Route<dynamic> route) => false,
    );
  }

  ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  ValueNotifier<double> imageSyncProgress = ValueNotifier<double>(0.0);
  ValueNotifier<String> dbUpdateLogMessage = ValueNotifier<String>('');
}
