import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../palette.dart';
import '../shader_library.dart';
import '../shader_state.dart';
import '../shader_theme.dart';

/// Visual style of a [ShaderReveal] transition.
enum RevealStyle {
  /// Organic noise dissolve with a glowing edge.
  dissolve,

  /// Content burns in from glowing embers with a charred rim.
  burn,

  /// An expanding, slightly wobbly circle from [ShaderReveal.origin].
  iris,

  /// A soft-edged wipe from [ShaderReveal.origin] to the opposite side.
  wipe,

  /// Random blocks that pop in along a diagonal.
  pixels,

  /// Rises from the bottom like liquid filling a glass.
  liquid,
}

/// Reveals [child] with a GPU transition as [progress] goes from 0 (hidden)
/// to 1 (fully visible).
///
/// Drive it with any animation, or use [AnimatedShaderReveal], the
/// [ShaderReveal.transitionBuilder] for `AnimatedSwitcher`, or
/// [ShaderRevealRoute] for page transitions.
///
/// ```dart
/// ShaderReveal(
///   progress: controller.value,
///   style: RevealStyle.burn,
///   child: const ProfileCard(),
/// )
/// ```
class ShaderReveal extends StatefulWidget {
  /// Creates a reveal transition.
  const ShaderReveal({
    super.key,
    required this.progress,
    required this.child,
    this.style = RevealStyle.dissolve,
    this.palette,
    this.origin = Alignment.center,
    this.edgeWidth = 0.08,
    this.animate = true,
  }) : assert(edgeWidth > 0, 'edgeWidth must be positive');

  /// 0 = hidden, 1 = fully visible.
  final double progress;

  /// The content to reveal.
  final Widget child;

  /// Transition style.
  final RevealStyle style;

  /// Edge glow colors.
  ///
  /// Defaults to the nearest [ShaderTheme] palette, or
  /// [ShaderPalette.lava] for [RevealStyle.burn] and [ShaderPalette.neon]
  /// otherwise.
  final ShaderPalette? palette;

  /// Where [RevealStyle.iris] and [RevealStyle.wipe] start.
  final Alignment origin;

  /// Width of the glowing edge, as a fraction of the transition.
  final double edgeWidth;

  /// Whether the edge shimmers while transitioning.
  final bool animate;

  /// A transition builder for `AnimatedSwitcher`:
  ///
  /// ```dart
  /// AnimatedSwitcher(
  ///   duration: const Duration(milliseconds: 900),
  ///   transitionBuilder: ShaderReveal.transitionBuilder(),
  ///   child: Text('$count', key: ValueKey(count)),
  /// )
  /// ```
  static Widget Function(Widget, Animation<double>) transitionBuilder({
    RevealStyle style = RevealStyle.dissolve,
    ShaderPalette? palette,
    Alignment origin = Alignment.center,
    double edgeWidth = 0.08,
  }) {
    return (Widget child, Animation<double> animation) => AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (BuildContext context, Widget? c) => ShaderReveal(
            progress: animation.value,
            style: style,
            palette: palette,
            origin: origin,
            edgeWidth: edgeWidth,
            child: c!,
          ),
        );
  }

  @override
  State<ShaderReveal> createState() => _ShaderRevealState();
}

class _ShaderRevealState extends ShaderWidgetState<ShaderReveal> {
  ui.FragmentShader? _mask;

  double get _p => widget.progress.clamp(0.0, 1.0);

  @override
  ShaderEffect get effect => ShaderEffect.reveal;
  @override
  ShaderPalette get palette => resolvePalette(
        widget.palette,
        widget.style == RevealStyle.burn
            ? ShaderPalette.lava
            : ShaderPalette.neon,
      );
  @override
  double get speed => 1;
  @override
  bool get animate => widget.animate && _p > 0 && _p < 1;
  @override
  bool get interactive => false;

  void _write(UniformWriter w, double mode) {
    w
      ..palette(currentPalette)
      ..float(_p)
      ..float(widget.style.index.toDouble())
      ..vec2((widget.origin.x + 1) / 2, (widget.origin.y + 1) / 2)
      ..float(widget.edgeWidth)
      ..float(mode);
  }

  @override
  void writeUniforms(UniformWriter w, Size size, Size canvasSize) =>
      _write(w, 1);

  @override
  void paintFallback(Canvas canvas, Size size) {}

  Shader _maskFor(Rect bounds) {
    final ui.FragmentShader? glow = shader;
    if (glow != null && _mask == null) {
      _mask = ShaderLibrary.cached(effect)?.fragmentShader();
    }
    final ui.FragmentShader? m = _mask;
    if (m == null || bounds.isEmpty) {
      final Color c = Color.fromRGBO(255, 255, 255, _p);
      return ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, <Color>[
        c,
        c,
      ]);
    }
    _write(
      UniformWriter(m)
        ..size(bounds.size)
        ..float(time),
      0,
    );
    return m;
  }

  @override
  void dispose() {
    _mask?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stop painting the edge glow once the transition has settled.
    final bool moving = _p > 0 && _p < 1;
    return CustomPaint(
      foregroundPainter: moving ? painter : null,
      child: ListenableBuilder(
        listenable: clock,
        builder: (BuildContext context, Widget? child) => ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: _maskFor,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Shows or hides [child] with a [ShaderReveal] transition whenever
/// [visible] changes.
///
/// ```dart
/// AnimatedShaderReveal(
///   visible: loaded,
///   style: RevealStyle.iris,
///   child: const ResultCard(),
/// )
/// ```
class AnimatedShaderReveal extends StatefulWidget {
  /// Creates an implicitly animated reveal.
  const AnimatedShaderReveal({
    super.key,
    required this.visible,
    required this.child,
    this.style = RevealStyle.dissolve,
    this.palette,
    this.origin = Alignment.center,
    this.edgeWidth = 0.08,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeInOutCubic,
  });

  /// Whether [child] is (becoming) visible.
  final bool visible;

  /// The content.
  final Widget child;

  /// Transition style.
  final RevealStyle style;

  /// Edge glow colors; see [ShaderReveal.palette].
  final ShaderPalette? palette;

  /// Where iris and wipe transitions start.
  final Alignment origin;

  /// Width of the glowing edge.
  final double edgeWidth;

  /// Transition duration.
  final Duration duration;

  /// Transition curve.
  final Curve curve;

  @override
  State<AnimatedShaderReveal> createState() => _AnimatedShaderRevealState();
}

class _AnimatedShaderRevealState extends State<AnimatedShaderReveal>
    with SingleTickerProviderStateMixin<AnimatedShaderReveal> {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.visible ? 1 : 0,
  );

  @override
  void didUpdateWidget(AnimatedShaderReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _c.duration = reduce ? Duration.zero : widget.duration;
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _c.forward();
      } else {
        _c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (BuildContext context, Widget? child) => ShaderReveal(
        progress: widget.curve.transform(_c.value),
        style: widget.style,
        palette: widget.palette,
        origin: widget.origin,
        edgeWidth: widget.edgeWidth,
        child: child!,
      ),
    );
  }
}

/// A page route that reveals the new page with a [ShaderReveal] transition.
///
/// ```dart
/// Navigator.of(context).push(
///   ShaderRevealRoute<void>(
///     style: RevealStyle.iris,
///     builder: (_) => const DetailsPage(),
///   ),
/// );
/// ```
class ShaderRevealRoute<T> extends PageRouteBuilder<T> {
  /// Creates a shader transition route.
  ShaderRevealRoute({
    required WidgetBuilder builder,
    RevealStyle style = RevealStyle.iris,
    ShaderPalette? palette,
    Alignment origin = Alignment.center,
    double edgeWidth = 0.06,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOutCubic,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (BuildContext context, _, __) => builder(context),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            _,
            Widget child,
          ) =>
              AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (BuildContext context, Widget? c) => ShaderReveal(
              progress: curve.transform(animation.value),
              style: style,
              palette: palette,
              origin: origin,
              edgeWidth: edgeWidth,
              child: c!,
            ),
          ),
        );
}
