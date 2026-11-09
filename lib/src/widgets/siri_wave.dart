import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_theme.dart';
import '../shader_library.dart';
import '../shader_state.dart';

/// Four layered, glowing voice waves in the style of modern assistants.
///
/// ```dart
/// SiriWave(height: 120, amplitude: micLevel)
/// ```
///
/// With [amplitude] null the waves idle softly. Each palette color drives one
/// wave. Amplitude changes are smoothed, so raw meter values can be passed.
class SiriWave extends StatefulWidget {
  /// Creates animated voice waves.
  const SiriWave({
    super.key,
    this.width,
    this.height = 120,
    this.palette,
    this.amplitude,
    this.speed = 1.0,
    this.thickness = 2.0,
    this.glow = 1.0,
    this.animate = true,
    this.semanticLabel,
  });

  /// Width of the waves; expands to the available width when null.
  final double? width;

  /// Height of the waves.
  final double height;

  /// One color per wave.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or [ShaderPalette.siri].
  final ShaderPalette? palette;

  /// Audio level from 0 to 1; idles softly when null.
  final double? amplitude;

  /// Animation speed multiplier.
  final double speed;

  /// Line thickness in logical pixels.
  final double thickness;

  /// Glow spread multiplier.
  final double glow;

  /// Whether the waves animate. Platform "reduce motion" is respected.
  final bool animate;

  /// Accessibility label; decorative when null.
  final String? semanticLabel;

  @override
  State<SiriWave> createState() => _SiriWaveState();
}

class _SiriWaveState extends ShaderWidgetState<SiriWave> {
  double _amp = 0.2;

  @override
  ShaderEffect get effect => ShaderEffect.siriWave;
  @override
  ShaderPalette get palette =>
      resolvePalette(widget.palette, ShaderPalette.siri);
  @override
  double get speed => widget.speed;
  @override
  bool get animate => widget.animate;
  @override
  bool get interactive => false;

  double get _target => widget.amplitude ?? (0.22 + 0.1 * math.sin(time * 0.9));

  @override
  bool tickValues(double dt) {
    final double target = _target;
    _amp = approach(_amp, target, dt, target > _amp ? 14 : 5);
    return (_amp - target).abs() > 0.002;
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) {
    w
      ..palette(currentPalette)
      ..float(_amp)
      ..float(widget.thickness)
      ..float(widget.glow);
  }

  @override
  void paintFallback(Canvas canvas, Size size) {
    final ShaderPalette p = currentPalette;
    final List<Color> colors = p.colors;
    for (int i = 0; i < 4; i++) {
      final Path path = Path();
      for (double x = 0; x <= size.width; x += 4) {
        final double nx = x / size.width * 2 - 1;
        final double att = math.pow(1 - nx * nx, 2).toDouble();
        final double y = size.height / 2 +
            att *
                _amp *
                size.height *
                0.4 *
                math.sin(nx * (1.6 + i * 0.55) * math.pi + time + i);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = widget.thickness
          ..color = colors[i],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget wave = SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: CustomPaint(painter: painter),
    );
    wave = RepaintBoundary(child: wave);
    if (widget.semanticLabel == null) return ExcludeSemantics(child: wave);
    return Semantics(label: widget.semanticLabel, image: true, child: wave);
  }
}
