import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';
import '../shader_theme.dart';

/// A "liquid glass" surface: the content behind it is blurred and
/// saturated, and a shader adds a light-catching rim, a specular highlight
/// that follows the pointer, an iridescent edge and a glossy sheen.
///
/// Place it over something colorful (an image, [AuroraBackground],
/// [ShaderGradient], a [ParticleField]):
///
/// ```dart
/// LiquidGlass(
///   padding: const EdgeInsets.all(24),
///   child: const Text('Liquid glass'),
/// )
/// ```
class LiquidGlass extends StatefulWidget {
  /// Creates a liquid glass surface.
  const LiquidGlass({
    super.key,
    this.child,
    this.borderRadius = 28,
    this.blur = 18,
    this.saturation = 1.6,
    this.tint = const Color(0x1FFFFFFF),
    this.rimLight = 1.0,
    this.iridescence = 0.6,
    this.grain = 0.035,
    this.palette,
    this.shadow = true,
    this.padding = const EdgeInsets.all(20),
    this.width,
    this.height,
    this.alignment,
    this.speed = 1.0,
    this.interactive = true,
    this.animate = true,
  })  : assert(blur >= 0, 'blur must not be negative'),
        assert(saturation >= 0, 'saturation must not be negative');

  /// The content shown on the glass.
  final Widget? child;

  /// Corner radius.
  final double borderRadius;

  /// Backdrop blur sigma; 0 disables the blur.
  final double blur;

  /// Backdrop color saturation; 1 keeps colors as they are.
  final double saturation;

  /// Glass tint; use a translucent white for light glass or a translucent
  /// black for smoked glass.
  final Color tint;

  /// Strength of the rim light and specular highlight.
  final double rimLight;

  /// Strength of the colored edge reflections.
  final double iridescence;

  /// Fine frosted grain (0 disables it).
  final double grain;

  /// Colors of the iridescent edge.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.siri].
  final ShaderPalette? palette;

  /// Whether a soft drop shadow lifts the glass off the background.
  final bool shadow;

  /// Space around [child].
  final EdgeInsetsGeometry padding;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Aligns [child] inside the glass.
  final AlignmentGeometry? alignment;

  /// Animation speed multiplier.
  final double speed;

  /// Whether the highlight follows the pointer.
  final bool interactive;

  /// Whether the sheen animates. Platform "reduce motion" is respected.
  final bool animate;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends ShaderWidgetState<LiquidGlass> {
  @override
  ShaderEffect get effect => ShaderEffect.glass;
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
      ..float(widget.borderRadius)
      ..color(widget.tint)
      ..float(widget.rimLight)
      ..float(widget.iridescence)
      ..float(widget.grain)
      ..vec3(touchPosition.dx, touchPosition.dy, touchStrength);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    final RRect r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(widget.borderRadius),
    );
    canvas
      ..drawRRect(r, Paint()..color = widget.tint)
      ..drawRRect(
        r.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0x55FFFFFF),
      );
  }

  ui.ImageFilter? get _filter {
    if (widget.blur <= 0 && widget.saturation == 1) return null;
    final ui.ImageFilter blur = ui.ImageFilter.blur(
      sigmaX: widget.blur,
      sigmaY: widget.blur,
      tileMode: TileMode.mirror,
    );
    if (widget.saturation == 1) return blur;
    final double s = widget.saturation;
    const double lr = 0.2126;
    const double lg = 0.7152;
    const double lb = 0.0722;
    final ColorFilter sat = ColorFilter.matrix(<double>[
      lr * (1 - s) + s, lg * (1 - s), lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s) + s, lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s), lb * (1 - s) + s, 0, 0, //
      0, 0, 0, 1, 0,
    ]);
    if (widget.blur <= 0) return sat;
    return ui.ImageFilter.compose(outer: sat, inner: blur);
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(widget.borderRadius);
    Widget? current = widget.child;
    if (current != null && widget.alignment != null) {
      current = Align(alignment: widget.alignment!, child: current);
    }
    current = Padding(padding: widget.padding, child: current);
    current = CustomPaint(painter: painter, child: current);
    final ui.ImageFilter? filter = _filter;
    if (filter != null) {
      current = BackdropFilter(filter: filter, child: current);
    }
    current = ClipRRect(borderRadius: radius, child: current);
    if (widget.shadow) {
      current = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 32,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: current,
      );
    }
    current = withTouch(current);
    if (widget.width != null || widget.height != null) {
      current = SizedBox(
        width: widget.width,
        height: widget.height,
        child: current,
      );
    }
    return current;
  }
}
