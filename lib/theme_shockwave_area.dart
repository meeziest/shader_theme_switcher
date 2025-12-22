import 'dart:math' as dart_math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

import 'shockwave_config.dart';

import 'theme_provider.dart';

/// A widget that renders the shockwave shader effect during theme transitions.
///
/// This widget uses a Fragment Shader to distort the content based on the
/// animation progress controlled by [ThemeController].
class ThemeShockWaveArea extends StatefulWidget {
  const ThemeShockWaveArea({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.mixFactor = 1.0,
    this.config = ShockwaveConfig.liquid,
  });

  /// The child widget over which the effect will be drawn.
  /// Typically this wraps your [Scaffold] or the main content of your screen.
  final Widget child;

  /// The duration of the shockwave animation.
  final Duration duration;

  /// Controls the blending of the circle mask.
  final double mixFactor;

  /// Configuration for the shockwave physics and look.
  final ShockwaveConfig config;

  @override
  State<ThemeShockWaveArea> createState() => _ThemeShockWaveAreaState();
}

class _ThemeShockWaveAreaState extends State<ThemeShockWaveArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.FragmentProgram? _program;

  ThemeController? _controllerModel;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _loadShader();
  }

  void _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'packages/shader_theme_switcher/shaders/shockwave.frag',
    );
    if (mounted) {
      setState(() {
        _program = program;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ThemeShockWaveArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controllerModel?.removeListener(_onListen);
    _controllerModel = InheritedThemeController.of(context);
    _controllerModel?.addListener(_onListen);
  }

  void _onListen() async {
    // Only start if the controller logic says we are animating.
    // This prevents re-triggering when isAnimating sets to false at the end.
    if (_controllerModel?.isAnimating == true) {
      if (_controller.value != 0.0) {
        _controller.value = 0.0;
      }
      _controller.forward(from: 0.0).then((value) {
        _controllerModel?.endAnimation();
        _controller.value = 0.0; // Reset for next time to prevent flash
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedThemeController.of(context);

    if (_program == null) {
      return widget.child;
    }

    final shader = _program!.fragmentShader();

    return IgnorePointer(
      ignoring: controller.isAnimating,
      child: Material(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return AnimatedSampler(
              enabled:
                  controller.isAnimating && controller.oldThemeImage != null,
              (ui.Image newThemeTexture, Size size, Canvas canvas) {
                final devicePixelRatio =
                    MediaQuery.of(context).devicePixelRatio;
                shader.setFloat(0, _controller.value); // iTime
                // iResolution is PHYSICAL pixels
                shader.setFloat(1, size.width * devicePixelRatio);
                shader.setFloat(2, size.height * devicePixelRatio);
                // offset is LOGICAL pixels
                shader.setFloat(3, controller.switcherOffset.dx);
                shader.setFloat(4, controller.switcherOffset.dy);
                shader.setFloat(5, widget.mixFactor); // circle mix factor
                shader.setFloat(6, devicePixelRatio); // devicePixelRatio

                // Custom config uniforms
                shader.setFloat(7, widget.config.shockStrength);
                shader.setFloat(8, widget.config.lensingSpread);
                shader.setFloat(9, widget.config.powExp);

                // Calculate dynamic maxRadius if null
                double maxRadius = widget.config.maxRadius ?? 0.0;
                if (widget.config.maxRadius == null) {
                  final double w = size.width;
                  final double h = size.height;
                  final double sx = controller.switcherOffset.dx;
                  final double sy = controller.switcherOffset.dy;

                  // Distances squared to 4 corners
                  final d1 = sx * sx + sy * sy; // Top-Left (0,0)
                  final d2 = (w - sx) * (w - sx) + sy * sy; // Top-Right (w,0)
                  final d3 = sx * sx + (h - sy) * (h - sy); // Bottom-Left (0,h)
                  final d4 = (w - sx) * (w - sx) +
                      (h - sy) * (h - sy); // Bottom-Right (w,h)

                  final maxDistSq = [d1, d2, d3, d4]
                      .reduce((curr, next) => curr > next ? curr : next);
                  // Shader uses coordinates normalized by height:
                  // scaledOrigin = (sx/h, sy/h)
                  // scaledUv = (x/h, y/h)
                  // So we normalize the pixel distance by height.
                  maxRadius = dart_math.sqrt(maxDistSq) / h;
                }
                shader.setFloat(10, maxRadius);

                shader.setImageSampler(
                    0, controller.oldThemeImage!); // iChannel0
                shader.setImageSampler(1, newThemeTexture); // iChannel1

                final paint = Paint()..shader = shader;
                canvas.drawRect(Offset.zero & size, paint);
              },
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}
