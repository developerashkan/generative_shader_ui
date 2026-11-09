import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';
import '../shader_theme.dart';

/// The particle behaviors of [ParticleField].
enum ParticleStyle {
  /// Parallax snowflakes drifting down.
  snow,

  /// Glowing sparks rising and flickering.
  embers,

  /// Wandering, blinking firefly lights.
  fireflies,

  /// Large, soft, out-of-focus discs.
  bokeh,

  /// Fast slanted rain streaks.
  rain,

  /// Tumbling confetti in palette colors.
  confetti,

  /// Stars streaking out of the center (hyperspace).
  warp,
}

/// Thousands of animated particles in a single GPU draw call.
///
/// Particles are generated procedurally in the shader (no particle lists,
/// no per-frame Dart work), so even full-screen fields are cheap. Touching
/// or hovering lights up nearby particles; the warp field steers towards
/// the pointer.
///
/// ```dart
/// const ParticleField(style: ParticleStyle.snow)            // backdrop
/// ParticleField(style: ParticleStyle.confetti,
///               foreground: true, child: successPage)       // overlay
/// ```
///
/// Without a [child] the field expands to fill its parent.
class ParticleField extends StatefulWidget {
  /// Creates a particle field.
  const ParticleField({
    super.key,
    this.style = ParticleStyle.snow,
    this.palette,
    this.density = 0.6,
    this.particleScale = 1.0,
    this.opacity = 1.0,
    this.speed = 1.0,
    this.foreground = false,
    this.interactive = true,
    this.animate = true,
    this.child,
  })  : assert(density >= 0 && density <= 1, 'density is 0..1'),
        assert(particleScale > 0, 'particleScale must be positive');

  /// Which particles to render.
  final ParticleStyle style;

  /// Particle colors.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or a palette that suits
  /// the [style] (frost for snow, lava for embers, firefly for fireflies...).
  final ShaderPalette? palette;

  /// Fraction of grid cells that hold a particle, 0..1.
  final double density;

  /// Scales particle size and spacing.
  final double particleScale;

  /// Overall opacity.
  final double opacity;

  /// Animation speed multiplier.
  final double speed;

  /// Whether particles are painted over [child] instead of behind it.
  ///
  /// Foreground particles never block taps.
  final bool foreground;

  /// Whether the pointer lights up (and steers) particles.
  final bool interactive;

  /// Whether particles move. Platform "reduce motion" is respected.
  final bool animate;

  /// Optional content painted over (or under) the particles.
  final Widget? child;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends ShaderWidgetState<ParticleField> {
  static const Map<ParticleStyle, ShaderPalette> _defaults =
      <ParticleStyle, ShaderPalette>{
    ParticleStyle.snow: ShaderPalette.frost,
    ParticleStyle.embers: ShaderPalette.lava,
    ParticleStyle.fireflies: ShaderPalette.firefly,
    ParticleStyle.bokeh: ShaderPalette.siri,
    ParticleStyle.rain: ShaderPalette.ocean,
    ParticleStyle.confetti: ShaderPalette.neon,
    ParticleStyle.warp: ShaderPalette.cyberpunk,
  };

  @override
  ShaderEffect get effect => ShaderEffect.particles;
  @override
  ShaderPalette get palette =>
      resolvePalette(widget.palette, _defaults[widget.style]!);
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
      ..float(widget.style.index.toDouble())
      ..float(widget.density)
      ..float(widget.particleScale)
      ..float(widget.opacity)
      ..vec3(touchPosition.dx, touchPosition.dy, touchStrength);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {}

  @override
  Widget build(BuildContext context) {
    final CustomPainter p = painter;
    Widget current = CustomPaint(
      painter: widget.foreground ? null : p,
      foregroundPainter: widget.foreground ? p : null,
      child: widget.child == null
          ? const SizedBox.expand()
          : RepaintBoundary(child: widget.child),
    );
    current = withTouch(current);
    return RepaintBoundary(child: current);
  }
}
