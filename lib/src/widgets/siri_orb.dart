import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';

/// A glowing, fluid, Siri-style orb that reacts to audio and touch.
///
/// With no arguments it gently "breathes" on its own:
///
/// ```dart
/// const SiriOrb()
/// ```
///
/// Feed it a live microphone level (0..1) to make it dance with a voice:
///
/// ```dart
/// SiriOrb(size: 220, amplitude: micLevel)
/// ```
///
/// Amplitude changes are smoothed internally, so raw, jittery meter values
/// can be passed straight in. Tapping the orb makes it pulse.
class SiriOrb extends StatefulWidget {
  /// Creates a fluid orb.
  const SiriOrb({
    super.key,
    this.size = 200,
    this.palette = ShaderPalette.siri,
    this.amplitude,
    this.speed = 1.0,
    this.glow = 1.0,
    this.interactive = true,
    this.animate = true,
    this.semanticLabel,
  });

  /// Width and height of the square the orb (and its glow) occupies.
  final double size;

  /// Blob colors (1-3) and core color (4).
  final ShaderPalette palette;

  /// Audio level from 0 (silent) to 1 (loud). Values up to 1.5 overdrive it.
  ///
  /// When null the orb idles with a soft breathing motion.
  final double? amplitude;

  /// Animation speed multiplier.
  final double speed;

  /// Outer glow strength (0 disables the halo).
  final double glow;

  /// Whether taps make the orb pulse and the highlight follow the pointer.
  final bool interactive;

  /// Whether the orb animates. Platform "reduce motion" is respected.
  final bool animate;

  /// Accessibility label; the orb is decorative when null.
  final String? semanticLabel;

  @override
  State<SiriOrb> createState() => _SiriOrbState();
}

class _SiriOrbState extends ShaderWidgetState<SiriOrb> {
  double _amp = 0.15;
  double _burst = 0;

  @override
  ShaderEffect get effect => ShaderEffect.siriOrb;
  @override
  ShaderPalette get palette => widget.palette;
  @override
  double get speed => widget.speed;
  @override
  bool get animate => widget.animate;
  @override
  bool get interactive => widget.interactive;

  double get _target {
    final double base =
        widget.amplitude ?? (0.14 + 0.08 * math.sin(time * 1.3));
    return base + _burst;
  }

  @override
  bool tickValues(double dt) {
    _burst = approach(_burst, 0, dt, 3.5);
    final double target = _target;
    final double rate = target > _amp ? 14 : 6;
    _amp = approach(_amp, target, dt, rate);
    return (_amp - target).abs() > 0.002 || _burst > 0.002;
  }

  @override
  void onPointerDown() => _burst = 0.9;

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    w
      ..palette(currentPalette)
      ..float(_amp)
      ..float(widget.glow)
      ..vec3(touchPosition.dx, touchPosition.dy, touchStrength);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    final ShaderPalette p = currentPalette;
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide * 0.32;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c - Offset(r * 0.3, r * 0.3),
          r * 1.4,
          <Color>[p.color1, p.color2, p.color3, p.color4],
          const <double>[0, 0.4, 0.75, 1],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget orb = SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(painter: painter),
    );
    orb = withTouch(orb);
    orb = RepaintBoundary(child: orb);
    if (widget.semanticLabel == null) return ExcludeSemantics(child: orb);
    return Semantics(label: widget.semanticLabel, image: true, child: orb);
  }
}
