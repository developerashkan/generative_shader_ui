import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';
import '../shader_theme.dart';

/// Triggers ripples on a [ShaderRipple] from code, e.g. on a notification
/// or when a value changes.
class ShaderRippleController {
  _ShaderRippleState? _state;

  /// Starts a ripple at [localPosition] (the center when null).
  void ripple([Offset? localPosition]) => _state?._spawn(localPosition);
}

/// Glowing, colorful ripples that spread from every touch.
///
/// Up to four ripples overlap at once. Wrap any tappable surface:
///
/// ```dart
/// ShaderRipple(
///   borderRadius: BorderRadius.circular(20),
///   onTap: () {},
///   child: const SizedBox(height: 120, child: Center(child: Text('Tap'))),
/// )
/// ```
class ShaderRipple extends StatefulWidget {
  /// Creates a ripple surface.
  const ShaderRipple({
    super.key,
    required this.child,
    this.onTap,
    this.palette,
    this.duration = const Duration(milliseconds: 1100),
    this.intensity = 1.0,
    this.borderRadius,
    this.controller,
    this.enabled = true,
  });

  /// The surface content.
  final Widget child;

  /// Called on tap (ripples appear either way).
  final VoidCallback? onTap;

  /// Ripple colors.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.neon].
  final ShaderPalette? palette;

  /// How long one ripple lives.
  final Duration duration;

  /// Brightness multiplier.
  final double intensity;

  /// Clips ripples to this shape; null leaves them unclipped.
  final BorderRadius? borderRadius;

  /// Optional controller to start ripples from code.
  final ShaderRippleController? controller;

  /// Whether touches create ripples.
  final bool enabled;

  @override
  State<ShaderRipple> createState() => _ShaderRippleState();
}

class _Ripple {
  _Ripple(this.position);
  final Offset position;
  double progress = 0;
}

class _ShaderRippleState extends ShaderWidgetState<ShaderRipple> {
  final List<_Ripple> _ripples = <_Ripple>[];

  @override
  ShaderEffect get effect => ShaderEffect.ripple;
  @override
  ShaderPalette get palette =>
      resolvePalette(widget.palette, ShaderPalette.neon);
  @override
  double get speed => 1;
  @override
  bool get animate => _ripples.isNotEmpty;
  @override
  bool get interactive => widget.enabled;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(ShaderRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    super.dispose();
  }

  void _spawn(Offset? local) {
    final Size? size = context.size;
    if (size == null || size.isEmpty) return;
    if (_ripples.length >= 4) _ripples.removeAt(0);
    _ripples.add(_Ripple(local ?? size.center(Offset.zero)));
    wake();
  }

  @override
  void onPointerDown() {
    final Size? size = context.size;
    if (size == null) return;
    _spawn(Offset(
      touchPosition.dx * size.width,
      touchPosition.dy * size.height,
    ));
  }

  @override
  bool tickValues(double dt) {
    final double life = math.max(widget.duration.inMicroseconds / 1e6, 0.05);
    for (final _Ripple r in _ripples) {
      r.progress += dt / life;
    }
    _ripples.removeWhere((_Ripple r) => r.progress >= 1);
    return _ripples.isNotEmpty;
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    w.palette(currentPalette);
    for (int i = 0; i < 4; i++) {
      if (i < _ripples.length) {
        final _Ripple r = _ripples[i];
        w
          ..vec2(r.position.dx, r.position.dy)
          ..vec2(r.progress, 1);
      } else {
        w
          ..vec2(0, 0)
          ..vec2(0, 0);
      }
    }
    w.float(widget.intensity);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    for (final _Ripple r in _ripples) {
      canvas.drawCircle(
        r.position,
        size.longestSide * r.progress,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = currentPalette.color1.withValues(alpha: 1 - r.progress),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget current = CustomPaint(
      foregroundPainter: painter,
      child: widget.child,
    );
    if (widget.borderRadius != null) {
      current = ClipRRect(borderRadius: widget.borderRadius!, child: current);
    }
    current = withTouch(current);
    if (widget.onTap != null) {
      current = GestureDetector(onTap: widget.onTap, child: current);
    }
    return current;
  }
}
