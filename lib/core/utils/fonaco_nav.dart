import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation impérative compatible GoRouter.
abstract final class FonacoNav {
  static void push(BuildContext context, String path, {Object? extra}) {
    context.push(path, extra: extra);
  }

  static void replace(BuildContext context, String path, {Object? extra}) {
    context.replace(path, extra: extra);
  }

  static void go(BuildContext context, String path, {Object? extra}) {
    context.go(path, extra: extra);
  }

  static void goFromNavigatorKey(GlobalKey<NavigatorState> key, String path) {
    key.currentContext?.go(path);
  }
}
