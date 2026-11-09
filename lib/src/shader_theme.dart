import 'package:flutter/widgets.dart';

import 'palette.dart';

/// Sets defaults for every shader widget below it in the tree.
///
/// Wrap your app (or one screen) once and every widget whose `palette` is not
/// set picks up the theme palette. Changing the theme cross-fades all of them
/// at once:
///
/// ```dart
/// ShaderTheme(
///   palette: ShaderPalette.sunset,
///   maxFps: 30, // battery saver for decorative effects
///   child: MaterialApp(home: HomePage()),
/// )
/// ```
class ShaderTheme extends InheritedWidget {
  /// Creates a shader theme.
  const ShaderTheme({
    super.key,
    this.palette,
    this.speed = 1.0,
    this.animate = true,
    this.maxFps,
    required super.child,
  })  : assert(speed >= 0, 'speed must not be negative'),
        assert(maxFps == null || maxFps > 0, 'maxFps must be positive');

  /// Default palette for widgets that do not set their own.
  ///
  /// When null each widget keeps its own default palette.
  final ShaderPalette? palette;

  /// Multiplies the `speed` of every widget below.
  final double speed;

  /// Set to false to freeze every shader below (one static frame each).
  final bool animate;

  /// Caps how often shaders repaint, for example `30` to halve GPU work on
  /// decorative backgrounds. Null repaints every frame.
  final double? maxFps;

  /// The nearest theme, or null. Registers a dependency.
  static ShaderTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShaderTheme>();

  @override
  bool updateShouldNotify(ShaderTheme oldWidget) =>
      palette != oldWidget.palette ||
      speed != oldWidget.speed ||
      animate != oldWidget.animate ||
      maxFps != oldWidget.maxFps;
}
