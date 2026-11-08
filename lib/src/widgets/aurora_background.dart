import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';

/// A full-bleed northern-lights background with twinkling stars.
///
/// Wrap a screen or a hero section with it:
///
/// ```dart
/// AuroraBackground(
///   child: Center(child: Text('Good evening')),
/// )
/// ```
///
/// The first three palette colors become the light curtains and the fourth
/// tints the horizon. Touching or hovering brightens the curtains under the
/// pointer.
class AuroraBackground extends StatefulWidget {
  /// Creates an animated aurora background.
  const AuroraBackground({
    super.key,
    this.palette = ShaderPalette.aurora,
    this.baseColor = const Color(0xFF050816),
    this.speed = 1.0,
    this.stars = 1.0,
    this.borderRadius = BorderRadius.zero,
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.interactive = true,
    this.animate = true,
    this.child,
  });

  /// Curtain colors (1-3) and horizon glow (4).
  final ShaderPalette palette;

  /// Sky color behind the aurora.
  final Color baseColor;

  /// Animation speed multiplier.
  final double speed;

  /// Star density from 0 (none) to about 3 (dense).
  final double stars;

  /// Corner rounding; content is clipped to it.
  final BorderRadiusGeometry borderRadius;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Empty space around [child].
  final EdgeInsetsGeometry? padding;

  /// Aligns [child] within the background.
  final AlignmentGeometry? alignment;

  /// Whether touches and hover brighten the aurora.
  final bool interactive;

  /// Whether the aurora animates. Platform "reduce motion" is respected.
  final bool animate;

  /// Content drawn on top of the aurora.
  final Widget? child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends ShaderWidgetState<AuroraBackground> {
  @override
  ShaderEffect get effect => ShaderEffect.aurora;
  @override
  ShaderPalette get palette => widget.palette;
  @override
  double get speed => widget.speed;
  @override
  bool get animate => widget.animate;
  @override
  bool get interactive => widget.interactive;

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    w
      ..palette(currentPalette)
      ..color(widget.baseColor)
      ..float(widget.stars)
      ..vec3(touchPosition.dx, touchPosition.dy, touchStrength);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = widget.baseColor);
    final ShaderPalette p = currentPalette;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          <Color>[
            p.color1.withValues(alpha: 0),
            p.color1.withValues(alpha: 0.35),
            p.color2.withValues(alpha: 0.25),
            p.color4.withValues(alpha: 0.3),
          ],
          const <double>[0, 0.4, 0.6, 1],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget current = widget.child ??
        LimitedBox(
          maxWidth: 0,
          maxHeight: 0,
          child: ConstrainedBox(constraints: const BoxConstraints.expand()),
        );
    if (widget.alignment != null) {
      current = Align(alignment: widget.alignment!, child: current);
    }
    if (widget.padding != null) {
      current = Padding(padding: widget.padding!, child: current);
    }
    current = CustomPaint(
      painter: painter,
      child: RepaintBoundary(child: current),
    );
    if (widget.borderRadius != BorderRadius.zero) {
      current = ClipRRect(borderRadius: widget.borderRadius, child: current);
    }
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
