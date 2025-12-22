import 'package:flutter/material.dart';

import 'theme_provider.dart';

/// A builder function that provides the [BuildContext] and a callback function to switch the theme.
typedef BuilderWithTheme = Widget Function(
    BuildContext, ThemeSwitcherCallback callback);

/// A callback function signature for triggering the theme switch.
typedef ThemeSwitcherCallback = void Function({
  required ThemeData theme,
  Offset? offset,
  VoidCallback? onAnimationFinish,
});

/// A helper widget that simplifies triggering the theme switch.
///
/// It automatically manages a [GlobalKey] to pinpoint the exact location
/// of the widget for the splash origin.
class ThemeSwitcherPoint extends StatefulWidget {
  const ThemeSwitcherPoint({
    super.key,
    required this.builder,
  });

  final BuilderWithTheme builder;

  @override
  ThemeSwitcherPointState createState() => ThemeSwitcherPointState();
}

class ThemeSwitcherPointState extends State<ThemeSwitcherPoint> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Builder(
      key: _globalKey,
      builder: (context) => widget.builder(
        context,
        changeTheme,
      ),
    );
  }

  void changeTheme({
    required ThemeData theme,
    Offset? offset,
    VoidCallback? onAnimationFinish,
  }) {
    InheritedThemeController.of(context).changeTheme(
      context,
      theme: theme,
      key: _globalKey,
      offset: offset,
      onAnimationFinish: onAnimationFinish,
    );
  }
}
