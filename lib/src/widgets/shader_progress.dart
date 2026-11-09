import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_theme.dart';
import '../shader_library.dart';
import '../shader_state.dart';

double _ease(double t) => Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));

/// A glowing gradient ring progress indicator rendered by a GPU shader.
///
/// ```dart
/// // Indeterminate spinner:
/// const ShaderCircularProgressIndicator()
///
/// // Determinate, with a label in the middle:
/// ShaderCircularProgressIndicator(
///   value: 0.72,
///   size: 96,
///   child: const Text('72%'),
/// )
/// ```
///
/// Changes to [value] animate smoothly.
class ShaderCircularProgressIndicator extends StatefulWidget {
  /// Creates a circular progress indicator.
  const ShaderCircularProgressIndicator({
    super.key,
    this.value,
    this.size = 64,
    this.strokeWidth = 6,
    this.palette,
    this.glow = 10,
    this.trackColor = const Color(0x1FFFFFFF),
    this.speed = 1.0,
    this.semanticsLabel,
    this.child,
  });

  /// Progress from 0 to 1, or null for an indeterminate spinner.
  final double? value;

  /// Diameter of the ring.
  final double size;

  /// Ring thickness.
  final double strokeWidth;

  /// Arc gradient from start (color 1) to end (color 4).
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.siri].
  final ShaderPalette? palette;

  /// Glow spread in logical pixels (painted outside the bounds).
  final double glow;

  /// Color of the unfilled track; use a transparent color to hide it.
  final Color trackColor;

  /// Animation speed multiplier.
  final double speed;

  /// Accessibility label.
  final String? semanticsLabel;

  /// Optional widget centered inside the ring.
  final Widget? child;

  @override
  State<ShaderCircularProgressIndicator> createState() =>
      _ShaderCircularProgressIndicatorState();
}

class _ShaderCircularProgressIndicatorState
    extends ShaderWidgetState<ShaderCircularProgressIndicator> {
  double _value = 0;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? 0;
  }

  @override
  ShaderEffect get effect => ShaderEffect.circularProgress;
  @override
  ShaderPalette get palette =>
      resolvePalette(widget.palette, ShaderPalette.siri);
  @override
  double get speed => widget.speed;
  @override
  bool get animate => true;
  @override
  bool get interactive => false;
  @override
  double get overflow => widget.glow * 1.6;

  @override
  bool tickValues(double dt) {
    final double target = (widget.value ?? 0).clamp(0.0, 1.0);
    _value = approach(_value, target, dt, 8);
    return (_value - target).abs() > 0.0005;
  }

  (double, double) get _arc {
    if (widget.value != null) return (0, _value);
    final double c = time * 0.6;
    final double f = c - c.floorToDouble();
    final double n = c.floorToDouble();
    final double head = n * 0.75 + 0.75 * _ease(f * 2);
    final double tail = n * 0.75 + 0.75 * _ease(f * 2 - 1);
    final double sweep = head - tail + 0.04;
    final double start = tail + time * 0.22;
    return (start - start.floorToDouble(), sweep);
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    final (double start, double sweep) = _arc;
    w
      ..palette(currentPalette)
      ..float(start)
      ..float(sweep)
      ..float(widget.strokeWidth)
      ..float((size.shortestSide - widget.strokeWidth) / 2)
      ..float(widget.glow)
      ..color(widget.trackColor);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    final (double start, double sweep) = _arc;
    final ShaderPalette p = currentPalette;
    final Rect rect = (Offset.zero & size).deflate(widget.strokeWidth / 2);
    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = widget.strokeWidth
        ..color = widget.trackColor,
    );
    canvas.drawArc(
      rect,
      start * 2 * math.pi - math.pi / 2,
      sweep * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = widget.strokeWidth
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          p.colors,
          const <double>[0, 0.35, 0.7, 1],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double? v = widget.value;
    return Semantics(
      label: widget.semanticsLabel,
      value: v == null ? null : '${(v.clamp(0.0, 1.0) * 100).round()}%',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: painter,
            child: widget.child == null ? null : Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// A liquid, glowing linear progress bar rendered by a GPU shader.
///
/// ```dart
/// // Indeterminate:
/// const ShaderLinearProgressIndicator()
///
/// // Determinate:
/// ShaderLinearProgressIndicator(value: downloadProgress)
/// ```
///
/// Expands to the available width like `LinearProgressIndicator`. Changes to
/// [value] animate smoothly.
class ShaderLinearProgressIndicator extends StatefulWidget {
  /// Creates a linear progress indicator.
  const ShaderLinearProgressIndicator({
    super.key,
    this.value,
    this.minHeight = 8,
    this.borderRadius,
    this.palette,
    this.glow = 10,
    this.trackColor = const Color(0x1FFFFFFF),
    this.speed = 1.0,
    this.semanticsLabel,
  });

  /// Progress from 0 to 1, or null for indeterminate.
  final double? value;

  /// Height of the bar.
  final double minHeight;

  /// Corner radius; defaults to fully rounded ends.
  final double? borderRadius;

  /// Colors flowing through the bar.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.siri].
  final ShaderPalette? palette;

  /// Glow spread in logical pixels (painted outside the bounds).
  final double glow;

  /// Color of the unfilled track.
  final Color trackColor;

  /// Animation speed multiplier.
  final double speed;

  /// Accessibility label.
  final String? semanticsLabel;

  @override
  State<ShaderLinearProgressIndicator> createState() =>
      _ShaderLinearProgressIndicatorState();
}

class _ShaderLinearProgressIndicatorState
    extends ShaderWidgetState<ShaderLinearProgressIndicator> {
  double _value = 0;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? 0;
  }

  @override
  ShaderEffect get effect => ShaderEffect.linearProgress;
  @override
  ShaderPalette get palette =>
      resolvePalette(widget.palette, ShaderPalette.siri);
  @override
  double get speed => widget.speed;
  @override
  bool get animate => true;
  @override
  bool get interactive => false;
  @override
  double get overflow => widget.glow * 1.6;

  @override
  bool tickValues(double dt) {
    final double target = (widget.value ?? 0).clamp(0.0, 1.0);
    _value = approach(_value, target, dt, 8);
    return (_value - target).abs() > 0.0005;
  }

  (double, double) get _segment {
    if (widget.value != null) return (0, _value);
    final double c = time * 0.55;
    final double f = c - c.floorToDouble();
    final double head = Curves.easeOut.transform(f) * 1.5 - 0.2;
    final double tail = Curves.easeIn.transform(f) * 1.5 - 0.5;
    return (tail.clamp(0.0, 1.0), head.clamp(0.0, 1.0));
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    final (double start, double end) = _segment;
    w
      ..palette(currentPalette)
      ..float(start)
      ..float(end)
      ..float(widget.borderRadius ?? size.height / 2)
      ..float(widget.glow)
      ..float(overflow)
      ..color(widget.trackColor);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    final (double start, double end) = _segment;
    final Radius r = Radius.circular(widget.borderRadius ?? size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = widget.trackColor,
    );
    if (end <= start) return;
    final Rect seg = Rect.fromLTRB(
      size.width * start,
      0,
      size.width * end,
      size.height,
    );
    paintPaletteFallback(
      canvas,
      seg,
      currentPalette,
      radius: BorderRadius.all(r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double? v = widget.value;
    return Semantics(
      label: widget.semanticsLabel,
      value: v == null ? null : '${(v.clamp(0.0, 1.0) * 100).round()}%',
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: widget.minHeight,
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }
}
