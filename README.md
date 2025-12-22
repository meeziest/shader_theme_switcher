# Shader Theme Switcher

A Flutter package for creating beautiful, shader-driven theme transitions. This package implements a "shockwave" effect that physically displaces pixels to expand the new theme over the old one, complete with optional chromatic aberration and dynamic physics.

https://github.com/user-attachments/assets/c6fbd979-5fc3-4b2b-9f9c-c904de2782c9

## Features

- **Shader-Powered Transitions**: Uses GLSL shaders (FragProgram) for high-performance visual effects.
- **Physics-Based Animation**: Includes amplitude damping and optional chromatic aberration (RGB split) for realistic liquid or glass-like warping.
- **Dynamic Resizing**: Automatically calculates the shockwave radius to cover the screen from any touch point.
- **Customizable**:
  - `ShockwaveConfig`: Control strength, spread, sharpness, and physics.
  - Predefined presets: `.liquid`, `.snap`, `.gentle`, `.normal`.
- **Interaction Safety**: Automatically blocks user interactions during the transition to prevent state issues.

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  shader_theme_switcher: ^0.0.1
```

## Usage

### 1. Wrap your App

Wrap your `MaterialApp` with `ShaderTheme` to initialize the theme controller.

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your starting theme
    final lightTheme = ThemeData.light();

    return ShaderTheme(
      initTheme: lightTheme,
      builder: (context, theme) {
        return MaterialApp(
          title: 'My App',
          theme: theme, // Use the theme from the builder
          home: const MyHomePage(),
        );
      },
    );
  }
}
```

### 2. Add the Shockwave Area

Wrap your root scaffold or screen content in `ThemeShockWaveArea`. This widget renders the shader effect.

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeShockWaveArea(
      config: ShockwaveConfig.liquid, // Use a preset or custom config
      child: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(child: const Text('Hello World')),
      ),
    );
  }
}
```


### 4. Trigger the Switch

You can trigger the switch in two ways:

#### Option A: Using `ThemeSwitcherPoint` (Recommended)
This widget automatically manages the `GlobalKey` for the splash origin.

```dart
ThemeSwitcherPoint(
  builder: (context, changeTheme) {
    return IconButton(
      icon: const Icon(Icons.brightness_6),
      onPressed: () {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final newTheme = isDark ? ThemeData.light() : ThemeData.dark();
        
        changeTheme(theme: newTheme);
      },
    );
  },
)
```

#### Option B: Manual Controller Access
If you need more control, use `InheritedThemeController`. You must provide a `GlobalKey` to identify the widget where the shockwave should start.

```dart
// 1. Create a GlobalKey
final GlobalKey _myButtonKey = GlobalKey();

// 2. Attach it to your widget
IconButton(
  key: _myButtonKey,
  icon: const Icon(Icons.brightness_6),
  onPressed: () {
    final controller = InheritedThemeController.of(context);
    final isDark = controller.theme.brightness == Brightness.dark;

    // 3. Call changeTheme
    controller.changeTheme(
      context,
      theme: isDark ? ThemeData.light() : ThemeData.dark(),
      key: _myButtonKey, // Pass the key
    );
  },
),
```

## Customization

You can fully tune the shader physics using `ShockwaveConfig`:

```dart
ThemeShockWaveArea(
  config: ShockwaveConfig(
    shockStrength: 1.0,  // Refraction intensity
    lensingSpread: 0.3,  // Width of the distortion ring
    powExp: 15.0,        // Sharpness of the curve
  ),
  child: ...
)
```

### Presets

- `ShockwaveConfig.liquid`: Smooth, viscous, water-like.
- `ShockwaveConfig.snap`: Fast, sharp, high-impact.
- `ShockwaveConfig.gentle`: Subtle distortion, good for minimal distraction.
- `ShockwaveConfig.normal`: Standard balanced effect.
