import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef ThemeBuilder = Widget Function(BuildContext, ThemeData theme);

/// A Widget that initializes the [ThemeController] and provides it to the descendant widgets.
///
/// This widget must wrap your [MaterialApp] or the part of the widget tree where you want
/// to enable shader-based theme switching.
class ShaderTheme extends StatefulWidget {
  const ShaderTheme({
    super.key,
    this.builder,
    this.child,
    required this.initTheme,
  });

  /// specific builder allows to just provide [MaterialApp] with the theme from [ThemeController]
  final ThemeBuilder? builder;

  /// The child widget which will be wrapped with the [InheritedThemeController].
  final Widget? child;

  /// The initial [ThemeData] to be used when the app starts.
  final ThemeData initTheme;

  @override
  State<ShaderTheme> createState() => _ShaderThemeState();
}

class _ShaderThemeState extends State<ShaderTheme> {
  late ThemeController controller;

  @override
  void initState() {
    super.initState();
    controller = ThemeController(startTheme: widget.initTheme);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedThemeController(
      notifier: controller,
      child: Builder(builder: (context) {
        var controller = InheritedThemeController.of(context);
        return RepaintBoundary(
          key: controller.previewContainer,
          child: widget.child ?? widget.builder!(context, controller.theme),
        );
      }),
    );
  }
}

/// An [InheritedNotifier] that exposes the [ThemeController] to the widget tree.
class InheritedThemeController extends InheritedNotifier<ThemeController> {
  const InheritedThemeController({
    super.key,
    required ThemeController super.notifier,
    required super.child,
  });

  /// The [ThemeController] from the closest [InheritedThemeController] instance that encloses the given context.
  static ThemeController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedThemeController>()!
        .notifier!;
  }
}

/// The controller that holds the current theme state and manages the switching animation logic.
class ThemeController extends ChangeNotifier {
  ThemeData _theme;
  ui.Image? oldThemeImage;

  late GlobalKey switcherGlobalKey;
  final previewContainer = GlobalKey();

  ThemeController({
    required ThemeData startTheme,
  }) : _theme = startTheme;

  /// The current [ThemeData].
  ThemeData get theme => _theme;
  ThemeData? oldTheme;

  bool _isAnimating = false;

  /// During animation, this is true. The UI might be unresponsive during this time.
  bool get isAnimating => _isAnimating;

  late Offset switcherOffset;

  void endAnimation() {
    if (_isAnimating) {
      _isAnimating = false;
      notifyListeners();
    }
  }

  /// Triggers the theme change animation.
  ///
  /// [context] is required to access the [devicePixelRatio].
  /// [theme] is the new theme to switch to.
  /// [key] is the [GlobalKey] of the widget from which the shockwave animation will originate (e.g. the button tapped).
  /// [offset] is an optional offset from the center of the widget identified by [key].
  /// [onAnimationFinish] is an optional callback called when the transition is fully complete.
  void changeTheme(
    BuildContext context, {
    required ThemeData theme,
    required GlobalKey key,
    Offset? offset,
    VoidCallback? onAnimationFinish,
  }) async {
    if (_isAnimating) return;
    final devicePixelRatio = View.of(context).devicePixelRatio;

    // 1. Capture the current (old) theme screenshot BEFORE updating the theme.
    // This prevents race conditions where an interim rebuild (during await)
    // would show the new theme before we are ready to animate.
    final image = await _makeScreenshot(devicePixelRatio);

    // 2. Now update the state atomically
    _isAnimating = true;
    oldTheme = _theme;
    _theme = theme;
    switcherOffset = _getSwitcherCoordinates(key, offset);

    // 3. Manage resources
    oldThemeImage?.dispose();
    oldThemeImage = image;

    // 4. Trigger the update
    notifyListeners();
  }

  Future<ui.Image> _makeScreenshot(double devicePixelRatio) async {
    final boundary = previewContainer.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    return await boundary.toImage(pixelRatio: devicePixelRatio);
  }

  Offset _getSwitcherCoordinates(
      GlobalKey<State<StatefulWidget>> switcherGlobalKey,
      [Offset? tapOffset]) {
    final renderObject =
        switcherGlobalKey.currentContext!.findRenderObject()! as RenderBox;
    final size = renderObject.size;
    return renderObject.localToGlobal(Offset.zero).translate(
          tapOffset?.dx ?? (size.width / 2),
          tapOffset?.dy ?? (size.height / 2),
        );
  }
}
