import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_theme.dart';
import '../shader_library.dart';
import '../shader_state.dart';

/// Paints any child (text, icons, images) with the living mesh gradient.
///
/// The child's opaque pixels are replaced by the animated gradient:
///
/// ```dart
/// ShaderGradientMask(
///   palette: ShaderPalette.neon,
///   child: const Icon(Icons.bolt, size: 96),
/// )
/// ```
class ShaderGradientMask extends StatefulWidget {
  /// Creates an animated gradient mask.
  const ShaderGradientMask({
    super.key,
    required this.child,
    this.palette,
    this.speed = 1.0,
    this.warp = 1.0,
    this.scale = 1.4,
    this.blendMode = BlendMode.srcIn,
    this.useDeepTone = false,
    this.animate = true,
  });

  /// Whether the palette's fourth (usually darkest) color is used.
  ///
  /// Defaults to false so text and icons stay bright and readable on dark
  /// backgrounds; the fourth color is replaced by the first.
  final bool useDeepTone;

  /// The widget to colorize.
  final Widget child;

  /// Gradient colors.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.siri].
  final ShaderPalette? palette;

  /// Animation speed multiplier.
  final double speed;

  /// Noise distortion strength.
  final double warp;

  /// Noise frequency.
  final double scale;

  /// How the gradient combines with the child; [BlendMode.srcIn] keeps the
  /// child's shape and replaces its colors.
  final BlendMode blendMode;

  /// Whether the gradient animates. Platform "reduce motion" is respected.
  final bool animate;

  @override
  State<ShaderGradientMask> createState() => _ShaderGradientMaskState();
}

class _ShaderGradientMaskState extends ShaderWidgetState<ShaderGradientMask> {
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
  bool get interactive => false;

  ShaderPalette get _maskPalette {
    final ShaderPalette p = currentPalette;
    return widget.useDeepTone ? p : p.copyWith(color4: p.color1);
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    w
      ..palette(_maskPalette)
      ..float(widget.warp)
      ..float(widget.scale)
      ..float(0)
      ..vec3(0.5, 0.5, 0);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {}

  Shader _shaderFor(Rect bounds) {
    final ui.FragmentShader? s = shader;
    if (s == null || bounds.isEmpty) {
      return ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        _maskPalette.colors,
        const <double>[0, 0.35, 0.7, 1],
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
        blendMode: widget.blendMode,
        shaderCallback: _shaderFor,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Text filled with the living mesh gradient.
///
/// ```dart
/// const ShaderGradientText('Hello, world')
/// ```
class ShaderGradientText extends StatelessWidget {
  /// Creates animated gradient text.
  const ShaderGradientText(
    this.text, {
    super.key,
    this.style,
    this.palette,
    this.speed = 1.0,
    this.textAlign,
    this.maxLines,
    this.animate = true,
  });

  /// The text to display.
  final String text;

  /// Text style; color is ignored. Defaults to a large bold headline.
  final TextStyle? style;

  /// Gradient colors.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.siri].
  final ShaderPalette? palette;

  /// Animation speed multiplier.
  final double speed;

  /// Horizontal alignment.
  final TextAlign? textAlign;

  /// Maximum number of lines.
  final int? maxLines;

  /// Whether the gradient animates.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return ShaderGradientMask(
      palette: palette,
      speed: speed,
      animate: animate,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.5,
        ).merge(style).copyWith(color: const Color(0xFFFFFFFF)),
      ),
    );
  }
}
