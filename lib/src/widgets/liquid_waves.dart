import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';
import '../shader_theme.dart';

/// Layered, glowing liquid that fills its box up to [level], with foam
/// crests, rising bubbles and waves that slosh under the pointer.
///
/// Use it as a hero background (low level, full width) or as a liquid
/// progress gauge inside any clip:
///
/// ```dart
/// ClipOval(
///   child: SizedBox.square(
///     dimension: 160,
///     child: LiquidWaves(
///       level: progress,
///       child: Center(child: Text('${(progress * 100).round()}%')),
///     ),
///   ),
/// )
/// ```
///
/// Changes to [level] animate smoothly. Above the liquid it is transparent.
class LiquidWaves extends StatefulWidget {
  /// Creates layered liquid waves.
  const LiquidWaves({
    super.key,
    this.level = 0.45,
    this.amplitude = 1.0,
    this.bubbles = 1.0,
    this.palette,
    this.speed = 1.0,
    this.width,
    this.height,
    this.interactive = true,
    this.animate = true,
    this.child,
  }) : assert(level >= 0 && level <= 1, 'level is 0..1');

  /// Liquid height as a fraction of the box, 0..1.
  final double level;

  /// Wave height multiplier.
  final double amplitude;

  /// Amount of rising bubbles (0 disables them).
  final double bubbles;

  /// Liquid layer colors (front to back) and the deep tone.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.ocean].
  final ShaderPalette? palette;

  /// Animation speed multiplier.
  final double speed;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Whether the pointer makes waves.
  final bool interactive;

  /// Whether the liquid moves. Platform "reduce motion" is respected.
  final bool animate;

  /// Content painted over the liquid.
  final Widget? child;

  @override
  State<LiquidWaves> createState() => _LiquidWavesState();
}

class _LiquidWavesState extends ShaderWidgetState<LiquidWaves> {
  late double _level = widget.level;

  @override
  ShaderEffect get effect => ShaderEffect.liquidWaves;
  @override
  ShaderPalette get palette =>
      resolvePalette(widget.palette, ShaderPalette.ocean);
  @override
  double get speed => widget.speed;
  @override
  bool get animate => widget.animate;
  @override
  bool get interactive => widget.interactive;

  @override
  bool tickValues(double dt) {
    _level = approach(_level, widget.level, dt, 3.5);
    return (_level - widget.level).abs() > 0.001;
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    w
      ..palette(currentPalette)
      ..float(_level)
      ..float(widget.amplitude)
      ..float(widget.bubbles)
      ..vec3(touchPosition.dx, touchPosition.dy, touchStrength);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    final double top = size.height * (1 - _level);
    final ShaderPalette p = currentPalette;
    canvas.drawRect(
      Rect.fromLTRB(0, top, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, size.height),
          <Color>[p.color1, p.color4],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget current = CustomPaint(
      painter: painter,
      child: widget.child ?? const SizedBox.expand(),
    );
    current = withTouch(current);
    if (widget.width != null || widget.height != null) {
      current = SizedBox(
        width: widget.width,
        height: widget.height,
        child: current,
      );
    }
    return RepaintBoundary(child: current);
  }
}
