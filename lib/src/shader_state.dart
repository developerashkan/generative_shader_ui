import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'palette.dart';
import 'shader_library.dart';
import 'shader_theme.dart';

/// Writes uniforms into a [ui.FragmentShader] in declaration order.
class UniformWriter {
  /// Creates a writer that starts at uniform index 0.
  UniformWriter(this.shader);

  /// The shader being configured.
  final ui.FragmentShader shader;
  int _index = 0;

  /// Writes a single float.
  void float(double value) => shader.setFloat(_index++, value);

  /// Writes a `vec2`.
  void vec2(double x, double y) {
    float(x);
    float(y);
  }

  /// Writes a `vec3`.
  void vec3(double x, double y, double z) {
    float(x);
    float(y);
    float(z);
  }

  /// Writes a [Size] as a `vec2`.
  void size(Size size) => vec2(size.width, size.height);

  /// Writes a straight-alpha [Color] as a `vec4`.
  void color(Color color) {
    float(color.r);
    float(color.g);
    float(color.b);
    float(color.a);
  }

  /// Writes the four palette colors as four `vec4`s.
  void palette(ShaderPalette palette) {
    color(palette.color1);
    color(palette.color2);
    color(palette.color3);
    color(palette.color4);
  }
}

/// Repaint signal shared by a shader widget and its painter.
class ShaderClock extends ChangeNotifier {
  /// Notifies listeners that a new frame should be painted.
  void tick() => notifyListeners();
}

/// Smoothly moves [current] toward [target] at [rate] per second.
double approach(double current, double target, double dt, double rate) {
  return current + (target - current) * (1 - math.exp(-dt * rate));
}

/// Shared animation, loading, palette cross-fade and touch tracking logic of
/// every shader widget in this package.
///
/// Not exported; widgets subclass it privately.
abstract class ShaderWidgetState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin<T> {
  /// Which fragment program to render.
  ShaderEffect get effect;

  /// The palette to render, usually `resolvePalette(widget.palette, ...)`.
  ShaderPalette get palette;

  /// Time multiplier requested by the widget.
  double get speed;

  /// Whether time should advance.
  bool get animate;

  /// Whether pointer position/presses feed into the shader.
  bool get interactive;

  /// Extra pixels painted around the widget for glows (does not affect
  /// layout).
  double get overflow => 0;

  /// Writes all uniforms after the common `uSize` and `uTime` pair.
  void writeUniforms(UniformWriter writer, Size size, Size canvasSize);

  /// Paints a cheap approximation while the shader loads or if it fails.
  void paintFallback(Canvas canvas, Size size);

  /// Advances widget specific smoothed values; return true while still
  /// animating so the ticker keeps running even when [animate] is false.
  bool tickValues(double dt) => false;

  /// Called when a pointer goes down on the widget.
  void onPointerDown() {}

  /// The live fragment shader, or null while loading.
  ui.FragmentShader? shader;

  /// Notifies the painter each frame.
  final ShaderClock clock = ShaderClock();

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  late double _time;
  bool _reduceMotion = false;
  ShaderTheme? _theme;
  bool _paletteReady = false;
  double _sinceRepaint = 0;

  late ShaderPalette _fromPalette;
  late ShaderPalette _toPalette;
  double _paletteT = 1;

  Offset _touch = const Offset(0.5, 0.5);
  double _touchStrength = 0;
  double _touchTarget = 0;
  bool _pointerDown = false;

  /// Shader time in seconds (scaled by [speed]).
  double get time => _time % 3600.0;

  /// Palette after cross-fade.
  ShaderPalette get currentPalette => _paletteT >= 1
      ? _toPalette
      : ShaderPalette.lerp(
          _fromPalette,
          _toPalette,
          Curves.easeInOut.transform(_paletteT),
        );

  /// Normalized pointer position (0..1 in both axes, relative to the widget).
  Offset get touchPosition => _touch;

  /// Smoothed pointer strength: 1 pressed, ~0.45 hovering, 0 idle.
  double get touchStrength => _touchStrength;

  /// Whether motion is currently allowed (respects platform reduce motion
  /// and [ShaderTheme.animate]).
  bool get motionEnabled =>
      animate && (_theme?.animate ?? true) && !_reduceMotion;

  /// Whether the platform asked for reduced motion.
  bool get reduceMotion => _reduceMotion;

  /// Returns [own] if set, otherwise the [ShaderTheme] palette, otherwise
  /// [fallback].
  ShaderPalette resolvePalette(ShaderPalette? own, ShaderPalette fallback) =>
      own ?? _theme?.palette ?? fallback;

  @override
  void initState() {
    super.initState();
    _time = (identityHashCode(this) % 997) / 7.0;
    _ticker = createTicker(_onTick);
    final ui.FragmentProgram? program = ShaderLibrary.cached(effect);
    if (program != null) {
      shader = program.fragmentShader();
    } else {
      ShaderLibrary.load(effect).then((ui.FragmentProgram p) {
        if (!mounted) return;
        setState(() => shader = p.fragmentShader());
      }, onError: (Object error, StackTrace stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'generative_shader_ui',
          context: ErrorDescription(
            'while loading the ${effect.fileName} shader; '
            'falling back to a plain gradient',
          ),
          silent: true,
        ));
      });
    }
    wake();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _theme = ShaderTheme.maybeOf(context);
    _syncPalette();
    wake();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPalette();
    wake();
  }

  void _syncPalette() {
    final ShaderPalette next = palette;
    if (!_paletteReady) {
      _fromPalette = next;
      _toPalette = next;
      _paletteReady = true;
    } else if (next != _toPalette) {
      _fromPalette = currentPalette;
      _toPalette = next;
      _paletteT = 0;
    }
  }

  /// Ensures the ticker is running (it stops itself when idle and paused).
  void wake() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final double dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _lastElapsed = elapsed;
    if (motionEnabled) _time += dt * speed * (_theme?.speed ?? 1);
    bool busy = false;
    if (_paletteT < 1) {
      _paletteT = math.min(1, _paletteT + dt / 0.6);
      busy = true;
    }
    _touchStrength = approach(_touchStrength, _touchTarget, dt, 9);
    if ((_touchStrength - _touchTarget).abs() > 0.002) busy = true;
    if (tickValues(dt)) busy = true;
    _sinceRepaint += dt;
    final double? maxFps = _theme?.maxFps;
    final bool settling = !motionEnabled && !busy;
    if (maxFps == null || settling || _sinceRepaint >= 1 / maxFps - 0.004) {
      _sinceRepaint = 0;
      clock.tick();
    }
    if (!motionEnabled && !busy) _ticker.stop();
  }

  void _setTouch(Offset local, double strength) {
    final Size? size = context.size;
    if (size == null || size.isEmpty) return;
    _touch = Offset(local.dx / size.width, local.dy / size.height);
    _touchTarget = strength;
    wake();
  }

  /// Wraps [child] so pointer events feed the shader (if [interactive]).
  Widget withTouch(Widget child) {
    if (!interactive) return child;
    // Opaque so ancestors (e.g. a GestureDetector around this widget) see
    // the hit: the non-opaque MouseRegion below always reports a miss.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent e) {
        _pointerDown = true;
        _setTouch(e.localPosition, 1);
        onPointerDown();
      },
      onPointerMove: (PointerMoveEvent e) => _setTouch(e.localPosition, 1),
      onPointerHover: (PointerHoverEvent e) => _setTouch(e.localPosition, 0.45),
      onPointerUp: (PointerUpEvent e) {
        _pointerDown = false;
        _setTouch(
            e.localPosition, e.kind == PointerDeviceKind.mouse ? 0.45 : 0);
      },
      onPointerCancel: (_) {
        _pointerDown = false;
        _touchTarget = 0;
        wake();
      },
      child: MouseRegion(
        opaque: false,
        onExit: (_) {
          if (_pointerDown) return;
          _touchTarget = 0;
          wake();
        },
        child: child,
      ),
    );
  }

  /// A painter bound to this state.
  CustomPainter get painter => ShaderPainter(this);

  @override
  void dispose() {
    _ticker.dispose();
    clock.dispose();
    shader?.dispose();
    super.dispose();
  }
}

/// Paints a [ShaderWidgetState]'s shader (or its fallback) every tick.
class ShaderPainter extends CustomPainter {
  /// Creates a painter that repaints whenever [state] ticks.
  ShaderPainter(this.state) : super(repaint: state.clock);

  /// The owning state.
  final ShaderWidgetState<StatefulWidget> state;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final ui.FragmentShader? shader = state.shader;
    if (shader == null) {
      state.paintFallback(canvas, size);
      return;
    }
    final double o = state.overflow;
    final Size canvasSize = Size(size.width + o * 2, size.height + o * 2);
    final UniformWriter writer = UniformWriter(shader)
      ..size(canvasSize)
      ..float(state.time);
    state.writeUniforms(writer, size, canvasSize);
    canvas
      ..save()
      ..translate(-o, -o)
      ..drawRect(Offset.zero & canvasSize, Paint()..shader = shader)
      ..restore();
  }

  @override
  bool shouldRepaint(ShaderPainter oldDelegate) => true;
}

/// Paints a simple gradient approximation of a palette.
void paintPaletteFallback(
  Canvas canvas,
  Rect rect,
  ShaderPalette palette, {
  BorderRadius? radius,
  double opacity = 1,
}) {
  final Paint paint = Paint()
    ..shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      palette.colors
          .map((Color c) => c.withValues(alpha: c.a * opacity))
          .toList(),
      const <double>[0, 0.35, 0.7, 1],
    );
  if (radius == null) {
    canvas.drawRect(rect, paint);
  } else {
    canvas.drawRRect(radius.toRRect(rect), paint);
  }
}
