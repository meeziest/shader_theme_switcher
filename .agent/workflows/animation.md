---
description: Animation Rules - Efficient animations in Flutter
---

## 1. Refresh Rate Awareness

Flutter automatically synchronizes with the device's display refresh rate (e.g., 120Hz on ProMotion displays).

**Rule**: Do not artificially cap FPS. Let the engine drive the ticker.

```dart
// ✅ CORRECT - Let Flutter manage refresh rate
AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

// ❌ WRONG - Don't manually cap frame rate
Timer.periodic(const Duration(milliseconds: 16), (timer) { /*setState((){})*/ });
```

## 2. Avoid Widget Tree Rebuilds

**Problem**: `setState` or `AnimatedBuilder` in tight loops triggers frequent Widget Tree dirtying.

**Rule**: Manage render cycle directly, bypass expensive framework build phase.

```dart
// ❌ WRONG - setState triggers widget tree rebuilds
_controller.addListener(() {
  setState(() { _value = _controller.value; }); // Rebuilds entire tree
});

// ✅ CORRECT - Use AnimatedBuilder
AnimatedBuilder(
  animation: controller,
  builder: (context, child) => Transform.translate(
    offset: Offset(controller.value * 100, 0),
    child: child,
  ),
  child: const MyWidget(), 
)
```

## 3. Isolate with RepaintBoundary

**Rule**: Wrap frequently animating complex Widgets in `RepaintBoundary`.

**Benefit**: Isolates painting process. Only the boundary repaints, leaving rest of screen static.

```dart
// ✅ CORRECT - Isolate animated content
Column(
  children: [
    const StaticHeader(), // Not repainted
    RepaintBoundary(child: AnimatedContent()), // Only this repaints
    const StaticFooter(), // Not repainted
  ],
)
```

## 4. Maintain Structural Integrity

**Rule**: Never change Widget Tree structure (add, remove, reorder nodes) during active animation.

**Consequence**: Structural changes trigger layout recalculations, causing jank. Modify properties, not hierarchy.

```dart
// ❌ WRONG - Structure changes mid-animation
if (controller.value > 0.5) const Text('New Item')

// ✅ CORRECT - Maintain structure, modify properties
Opacity(
  opacity: controller.value > 0.5 ? 1.0 : 0.0,
  child: const Text('New Item'),
)
```

## 5. Implement Custom Tickers

**Rule**: Use `Ticker` class directly for precise frame control with lower overhead.

```dart
class _State extends State<Widget> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _value = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final seconds = elapsed.inMilliseconds / 1000.0;
    _value = (seconds % 2.0) / 2.0; // Repeating 0-1 animation
    // Mark render object for repaint, not setState
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
```

## 6. Direct RenderObject Manipulation

**Rule**: Mark specific `RenderObject` as needing repaint (`markNeedsPaint`) rather than rebuilding widget.

**Strategy**: Targets render layer directly, ignoring Element and Widget trees for update cycle.

```dart
class AnimatedRenderWidget extends LeafRenderObjectWidget {
  final Animation<double> animation;
  const AnimatedRenderWidget({required this.animation, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
    RenderAnimatedBox(animation);

  @override
  void updateRenderObject(BuildContext context, RenderAnimatedBox renderObject) {
    renderObject.animation = animation;
  }
}

class RenderAnimatedBox extends RenderBox {
  RenderAnimatedBox(Animation<double> animation) : _animation = animation {
    _animation.addListener(markNeedsPaint);
  }

  Animation<double> _animation;
  Animation<double> get animation => _animation;

  set animation(Animation<double> value) {
    if (_animation == value) return;
    _animation.removeListener(markNeedsPaint);
    _animation = value;
    _animation.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final paint = Paint()..color = Color.lerp(Colors.red, Colors.blue, _animation.value)!;
    canvas.drawCircle(offset + Offset(size.width / 2, size.height / 2), 50 * _animation.value, paint);
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void detach() {
    _animation.removeListener(markNeedsPaint);
    super.detach();
  }
}
```

## 7. Canvas & Painting Optimization

### Reuse Objects

**Never** create new `Paint` objects inside `paint` method. Define once and reuse.

```dart
// ❌ WRONG - Creating new Paint per frame
@override
void paint(Canvas canvas, Size size) {
  for (var i = 0; i < 100; i++) {
    final paint = Paint()..color = Colors.blue; // 100 objects!
    canvas.drawCircle(Offset(i * 10.0, i * 10.0), 5, paint);
  }
}

// ✅ CORRECT - Reuse Paint
class GoodPainter extends CustomPainter {
  final Paint _paint = Paint()..color = Colors.blue;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 100; i++) {
      canvas.drawCircle(Offset(i * 10.0, i * 10.0), 5, _paint);
    }
  }
}
```

### Batch Operations

Use optimized methods like `drawAtlas`, `drawPoints` for multiple sprites/shapes in single GPU call.

```dart
// ❌ WRONG - Multiple draw calls
for (final particle in particles) {
  canvas.drawCircle(particle.position, particle.radius, paint);
}

// ✅ CORRECT - Batched rendering
final points = particles.map((p) => p.position).toList();
canvas.drawPoints(PointMode.points, points, _paint); // Single call

// ✅ BEST - Use drawAtlas for sprites
canvas.drawAtlas(spriteSheet, transforms, rects, null, BlendMode.src, null, Paint());
```

### Layer Management

Use `save()` and `restore()` to manage canvas stack efficiently.

```dart
@override
void paint(Canvas canvas, Size size) {
  canvas.save();
  canvas.translate(100, 100);
  canvas.rotate(0.5);
  canvas.drawCircle(Offset.zero, 50, Paint()..color = Colors.blue);
  canvas.restore();
  canvas.drawRect(Rect.fromLTWH(0, 0, 100, 100), Paint()..color = Colors.red);
}
```

## 8. Leverage Fragment Shaders

**Rule**: For complex pixel manipulations, use Fragment Shaders (GPU-accelerated).

```dart
// Load shader
Future<ui.FragmentShader> loadShader() async {
  final program = await ui.FragmentProgram.fromAsset('shaders/my_shader.frag');
  return program.fragmentShader();
}

class ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  ShaderPainter(this.shader, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(ShaderPainter oldDelegate) => oldDelegate.time != time;
}
```

## 9. The CustomPainter Pattern

**Rule**: Do not use `setState` to drive `CustomPainter`.

**Best Practice**: Pass `AnimationController` (or `Listenable`) to `repaint` argument. Triggers paint phase without build phase.

```dart
// ❌ WRONG - Using setState
_controller.addListener(() {
  setState(() {}); // ❌ Rebuilds entire widget tree
});

// In build:
CustomPaint(painter: MyPainter(_controller.value))

// ✅ CORRECT - Using repaint parameter
RepaintBoundary(
  child: CustomPaint(
    painter: MyAnimatedPainter(animation: _controller),
  ),
)

class MyAnimatedPainter extends CustomPainter {
  MyAnimatedPainter({required this.animation}) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    // ... drawing code
  }

  @override
  bool shouldRepaint(MyAnimatedPainter oldDelegate) => oldDelegate.animation != animation;
}
```

## 10. Animation Performance Patterns

### Implicit Animations for Simple Cases

For simple animations, use implicit animation widgets:

```dart
// Simple property animations
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  width: _expanded ? 200 : 100,
  height: _expanded ? 200 : 100,
)

AnimatedOpacity(
  duration: const Duration(milliseconds: 300),
  opacity: _visible ? 1.0 : 0.0,
  child: child,
)
```

### Explicit Animations for Complex Cases

For complex animations requiring precise control:

```dart
class ComplexAnimation extends StatefulWidget {
  @override
  State<ComplexAnimation> createState() => _ComplexAnimationState();
}

class _ComplexAnimationState extends State<ComplexAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Performance Checklist

- ✅ Use `RepaintBoundary` to isolate animated content where needed
- ✅ Prefer `AnimatedBuilder` over `setState` for animations
- ✅ Pass `AnimationController` to `CustomPainter`'s `repaint` parameter
- ✅ Reuse `Paint` objects, never create in `paint()` method
- ✅ Use batched drawing (`drawPoints`, `drawAtlas`)
- ✅ Maintain widget tree structure during animations
- ✅ Use `markNeedsPaint()` for direct `RenderObject` updates
- ✅ Leverage Fragment Shaders for GPU effects
- ✅ Use custom `Ticker` for precise frame control
- ✅ Let Flutter manage refresh rates automatically

## Performance Monitoring

```dart
import 'dart:developer' as developer;

// Measure animation performance
developer.Timeline.startSync('MyAnimation');
// Animation code
developer.Timeline.finishSync();

// Enable performance overlay
MaterialApp(
  showPerformanceOverlay: true, // Shows FPS and GPU usage
)
```

## Common Pitfalls

1. **Don't animate expensive layouts**: Use `Transform` instead of `Padding` or `Container` size changes
2. **Don't animate clip paths**: Clipping is expensive, use opacity instead when possible
3. **Don't create animations in build method**: Create in `initState`, dispose in `dispose`
4. **Don't forget dispose**: Always dispose `AnimationController` and `Ticker`
5. **Don't over-use `RepaintBoundary`**: Only use where needed, too many can hurt performance