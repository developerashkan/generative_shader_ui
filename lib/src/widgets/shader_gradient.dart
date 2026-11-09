import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_theme.dart';
import '../shader_library.dart';
import '../shader_state.dart';

/// A container filled with a living, GPU-rendered mesh gradient.
///
/// Drop it anywhere you would use a `Container` with a gradient:
///
/// ```dart
/// ShaderGradient(
///   palette: ShaderPalette.sunset,
///   borderRadius: BorderRadius.circular(24),
///   padding: const EdgeInsets.all(24),
///   child: const Text('Hello'),
/// )
/// ```
///
/// Four soft color points drift around while a noise field warps the space
/// between them. Pointers (touch or mouse) gently push the colors around and
/// light up the area under the finger.
class ShaderGradient extends StatefulWidget {
  /// Creates an animated mesh gradient container.
  const ShaderGradient({
    super.key,
    this.palette,
    this.speed = 1.0,
    this.warp = 1.0,
    this.scale = 1.6,
    this.grain = 0.25,
    this.borderRadius = BorderRadius.zero,
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.interactive = true,
    this.animate = true,
    this.child,
  });

  /// Colors of the four drifting gradient points.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.siri].
  final ShaderPalette? palette;

  /// Animation speed multiplier; 0 freezes the gradient.
  final double speed;

  /// How strongly noise distorts the gradient (0 = clean blend, 2 = liquid).
  final double warp;

  /// Noise frequency; larger values give smaller, busier swirls.
  final double scale;

  /// Film-grain amount from 0 to 1; a little grain prevents color banding.
  final double grain;

  /// Corner rounding; content is clipped to it.
  final BorderRadiusGeometry borderRadius;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Empty space inside the gradient around [child].
  final EdgeInsetsGeometry? padding;

  /// Aligns [child] within the container.
  final AlignmentGeometry? alignment;

  /// Whether touches and mouse hover push the gradient.
  final bool interactive;

  /// Whether the gradient animates. Platform "reduce motion" is respected.
  final bool animate;

  /// The content drawn on top of the gradient.
  final Widget? child;

  @override
  State<ShaderGradient> createState() => _ShaderGradientState();
}

class _ShaderGradientState extends ShaderWidgetState<ShaderGradient> {
  @override
  ShaderEffect get effect => ShaderEffect.meshGradient;
  @override
  ShaderPalette get palette =>
      resolvePalette(widget.palette, ShaderPalette.siri);
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
      ..float(widget.warp)
      ..float(widget.scale)
      ..float(widget.grain)
      ..vec3(touchPosition.dx, touchPosition.dy, touchStrength);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    paintPaletteFallback(canvas, Offset.zero & size, currentPalette);
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
