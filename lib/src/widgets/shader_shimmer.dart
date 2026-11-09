import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';

/// A glossy shine that sweeps across [child] every [period], like light
/// catching a premium card, a "slide to unlock" label or a fresh badge.
///
/// Only the child's own pixels are lit, so it works on text, icons, images
/// and whole cards alike:
///
/// ```dart
/// ShaderShimmer(child: Text('PRO', style: TextStyle(fontSize: 48)))
/// ```
class ShaderShimmer extends StatefulWidget {
  /// Creates a shine effect over [child].
  const ShaderShimmer({
    super.key,
    required this.child,
    this.color = const Color(0xB3FFFFFF),
    this.angle = 0.45,
    this.width = 0.16,
    this.period = const Duration(milliseconds: 2600),
    this.speed = 1.0,
    this.enabled = true,
    this.animate = true,
  });

  /// The content to shine over.
  final Widget child;

  /// Shine color; its alpha is the peak strength.
  final Color color;

  /// Sweep direction in radians (0 = left to right).
  final double angle;

  /// Shine width as a fraction of the child's size.
  final double width;

  /// Time between two sweeps (the sweep itself takes up to 1.2 s).
  final Duration period;

  /// Animation speed multiplier.
  final double speed;

  /// Set to false to show [child] without any effect.
  final bool enabled;

  /// Whether the shine animates. Platform "reduce motion" hides it.
  final bool animate;

  @override
  State<ShaderShimmer> createState() => _ShaderShimmerState();
}

class _ShaderShimmerState extends ShaderWidgetState<ShaderShimmer> {
  @override
  ShaderEffect get effect => ShaderEffect.shimmer;
  @override
  ShaderPalette get palette => ShaderPalette.siri;
  @override
  double get speed => widget.speed;
  @override
  bool get animate => widget.animate && widget.enabled;
  @override
  bool get interactive => false;

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    final Color c =
        motionEnabled ? widget.color : widget.color.withValues(alpha: 0);
    w
      ..color(c)
      ..float(widget.angle)
      ..float(widget.width)
      ..float(widget.period.inMicroseconds / 1e6);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {}

  Shader _shaderFor(Rect bounds) {
    final ui.FragmentShader? s = shader;
    if (s == null || bounds.isEmpty) {
      return ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        const <Color>[Color(0x00FFFFFF), Color(0x00FFFFFF)],
      );
    }
    final UniformWriter w = UniformWriter(s)
      ..size(bounds.size)
      ..float(time);
    writeUniforms(w, bounds.size, bounds.size);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: clock,
      builder: (BuildContext context, Widget? child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: _shaderFor,
        child: child,
      ),
      child: widget.child,
    );
  }
}
