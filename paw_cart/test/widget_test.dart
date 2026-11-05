import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_cart/auth_screen.dart';

void main() {
  testWidgets('PawCart authentication screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestAuthApp(),
    );

    expect(find.text('PawCart'), findsOneWidget);
    expect(find.text('Welcome back, pet parent! 💗'), findsOneWidget);
    expect(find.text('Sign in'), findsNWidgets(2));
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}


class TestAuthApp extends StatelessWidget {
  const TestAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthScreen(),
    );
  }
}
