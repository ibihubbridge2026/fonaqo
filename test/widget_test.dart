import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fonaco/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const FonacoApp(isFirstTime: false, isLoggedIn: false),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
