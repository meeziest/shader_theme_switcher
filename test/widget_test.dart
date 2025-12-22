import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_theme_switcher/shader_theme_switcher.dart';
import 'package:shader_theme_switcher/theme_provider.dart';

void main() {
  testWidgets('ShaderTheme provides theme', (WidgetTester tester) async {
    final lightTheme = ThemeData.light();

    await tester.pumpWidget(
      ShaderTheme(
        initTheme: lightTheme,
        builder: (context, theme) {
          return MaterialApp(
            theme: theme,
            home: const Scaffold(body: Text('Hello')),
          );
        },
      ),
    );

    expect(find.text('Hello'), findsOneWidget);

    // Verify context can access controller
    final context = tester.element(find.text('Hello'));
    final controller = InheritedThemeController.of(context);
    expect(controller.theme, equals(lightTheme));
  });
}
