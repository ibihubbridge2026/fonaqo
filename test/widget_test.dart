import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fonaco/core/providers/auth_provider.dart';

import 'package:fonaco/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      FonacoApp(isFirstTime: false, isLoggedIn: false, authProvider: AuthProvider()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
