import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';
import '../shader_theme.dart';

/// Radar-style rings pulsing out of [child] with a soft colored halo.
///
/// Perfect for "live" badges, a listening mic button, an active map pin or
/// anything that needs attention. Rings paint outside the child's bounds
/// (they never affect layout) and fade out smoothly when [active] turns
/// false.
///
/// ```dart
/// ShaderPulse(
///   child: CircleAvatar(child: Icon(Icons.mic)),
/// )
/// ```
class ShaderPulse extends StatefulWidget {
  /// Creates pulsing rings around [child].
  const ShaderPulse({
    super.key,
    required this.child,
    this.palette,
    this.active = true,
    this.spread = 36,
    this.rings = 3,
    this.borderRadius,
    this.intensity = 1.0,
    this.speed = 1.0,
    this.animate = true,
  }) : assert(rings >= 1 && rings <= 5, 'rings must be 1..5');

  /// The widget the rings come out of.
  final Widget child;

  /// Ring colors.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.siri].
  final ShaderPalette? palette;

  /// Whether the rings are pulsing. Changes fade smoothly.
  final bool active;

  /// How far the rings travel beyond the child, in logical pixels.
  final double spread;

  /// Number of rings in flight (1 to 5).
  final int rings;

  /// Corner radius of the child's outline; null treats it as a circle or a
  /// pill.
  final double? borderRadius;

  /// Brightness multiplier.
  final double intensity;

  /// Animation speed multiplier.
  final double speed;

  /// Whether the rings move. Platform "reduce motion" is respected.
  final bool animate;

  @override
  State<ShaderPulse> createState() => _ShaderPulseState();
}

class _ShaderPulseState extends ShaderWidgetState<ShaderPulse> {
  double _level = 0;

  @override
  ShaderEffect get effect => ShaderEffect.pulse;
  @override
  ShaderPalette get palette =>
      resolvePalette(widget.palette, ShaderPalette.siri);
  @override
  double get speed => widget.speed;
  @override
  bool get animate => widget.animate && (widget.active || _level > 0.002);
  @override
  bool get interactive => false;
  @override
  double get overflow => widget.spread;

  double get _target => widget.active ? widget.intensity : 0;

  @override
  void initState() {
    super.initState();
    _level = _target;
  }

  @override
  bool tickValues(double dt) {
    _level = approach(_level, _target, dt, 5);
    return (_level - _target).abs() > 0.002;
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    w
      ..palette(currentPalette)
      ..float(widget.spread)
      ..float(widget.rings.toDouble())
      ..float(_level)
      ..float(widget.borderRadius ?? size.shortestSide / 2);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {}

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: painter, child: widget.child);
  }
}
