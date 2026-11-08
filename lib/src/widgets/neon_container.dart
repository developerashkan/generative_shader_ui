import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';

/// Wraps any widget in an animated neon border with a soft glow and a
/// glassy, touch-lit fill.
///
/// ```dart
/// NeonContainer(
///   palette: ShaderPalette.cyberpunk,
///   child: const Text('Level up'),
/// )
/// ```
///
/// The glow is painted outside the widget bounds (like a `BoxShadow`) and does
/// not affect layout.
class NeonContainer extends StatefulWidget {
  /// Creates a neon-bordered container.
  const NeonContainer({
    super.key,
    this.palette = ShaderPalette.neon,
    this.borderRadius = 16,
    this.strokeWidth = 2,
    this.glow = 14,
    this.fillColor = const Color(0xE60B0B16),
    this.highlight = 0,
    this.speed = 1.0,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
    this.alignment,
    this.interactive = true,
    this.animate = true,
    this.child,
  });

  /// Border sweep colors (all four cycle around the border).
  final ShaderPalette palette;

  /// Corner radius in logical pixels.
  final double borderRadius;

  /// Neon line thickness.
  final double strokeWidth;

  /// Glow spread in logical pixels (painted outside the bounds).
  final double glow;

  /// Fill behind [child]; use a translucent dark color for a glass look.
  final Color fillColor;

  /// Extra brightness from 0 to 1 (used by [NeonButton] for hover/press).
  ///
  /// Changes are animated smoothly.
  final double highlight;

  /// Animation speed multiplier.
  final double speed;

  /// Space between the border and [child].
  final EdgeInsetsGeometry padding;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Aligns [child] inside the container.
  final AlignmentGeometry? alignment;

  /// Whether a light follows the pointer inside the container.
  final bool interactive;

  /// Whether the neon animates. Platform "reduce motion" is respected.
  final bool animate;

  /// The content.
  final Widget? child;

  @override
  State<NeonContainer> createState() => _NeonContainerState();
}

class _NeonContainerState extends ShaderWidgetState<NeonContainer> {
  double _highlight = 0;

  @override
  ShaderEffect get effect => ShaderEffect.neonBorder;
  @override
  ShaderPalette get palette => widget.palette;
  @override
  double get speed => widget.speed;
  @override
  bool get animate => widget.animate;
  @override
  bool get interactive => widget.interactive;
  @override
  double get overflow => widget.glow * 1.6 + widget.strokeWidth;

  @override
  bool tickValues(double dt) {
    _highlight = approach(_highlight, widget.highlight, dt, 16);
    return (_highlight - widget.highlight).abs() > 0.002;
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    final double o = overflow;
    // Pointer position is relative to the widget; convert to canvas space.
    final double tx = (touchPosition.dx * size.width + o) / canvasSize.width;
    final double ty = (touchPosition.dy * size.height + o) / canvasSize.height;
    w
      ..palette(currentPalette)
      ..float(widget.borderRadius)
      ..float(widget.strokeWidth)
      ..float(widget.glow)
      ..float(o)
      ..color(widget.fillColor)
      ..float(_highlight)
      ..vec3(tx, ty, touchStrength);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    final ShaderPalette p = currentPalette;
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(widget.borderRadius),
    );
    canvas.drawRRect(rrect, Paint()..color = widget.fillColor);
    canvas.drawRRect(
      rrect.deflate(widget.strokeWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = widget.strokeWidth
        ..shader = ui.Gradient.sweep(
          size.center(Offset.zero),
          <Color>[p.color1, p.color2, p.color3, p.color4, p.color1],
          const <double>[0, 0.25, 0.5, 0.75, 1],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget? current = widget.child;
    if (current != null && widget.alignment != null) {
      current = Align(alignment: widget.alignment!, child: current);
    }
    current = Padding(padding: widget.padding, child: current);
    current = CustomPaint(
      painter: painter,
      child: RepaintBoundary(child: current),
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
