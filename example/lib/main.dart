import 'package:flutter/material.dart';
import 'package:shader_theme_switcher/shader_theme_switcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      brightness: Brightness.light,
    );

    return ShaderTheme(
      initTheme: lightTheme,
      builder: (context, theme) {
        return MaterialApp(
          title: 'Shader Theme Switcher Demo',
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: const ThemeShockWaveArea(
            config: ShockwaveConfig.liquid,
            duration: Duration(milliseconds: 1000),
            child: MyHomePage(),
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Shader Theme Switcher')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ThemeSwitcherPoint(
              builder: (context, changeTheme) {
                return IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    final newTheme = isDark
                        ? ThemeData(
                            useMaterial3: true,
                            colorScheme: ColorScheme.fromSeed(
                              seedColor: Colors.blue,
                            ),
                            brightness: Brightness.light,
                          )
                        : ThemeData(
                            useMaterial3: true,
                            colorScheme: ColorScheme.fromSeed(
                              seedColor: Colors.blue,
                              brightness: Brightness.dark,
                            ),
                            brightness: Brightness.dark,
                          );

                    changeTheme(theme: newTheme);
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Current Theme: ${isDark ? "Dark" : "Light"}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
