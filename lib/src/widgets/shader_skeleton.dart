import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../shader_library.dart';
import '../shader_state.dart';
import '../shader_theme.dart';

/// How a [ShaderSkeleton] animates its bones.
enum SkeletonEffect {
  /// A soft diagonal shine sweeping across the screen.
  shimmer,

  /// All bones gently breathe between the base and highlight colors.
  pulse,

  /// A shine tinted with the accent color and slow liquid noise.
  glow,
}

/// Turns any widget into a shimmering skeleton while [isLoading] is true,
/// then cross-fades to the real content.
///
/// **No placeholder layout needed.** The skeleton walks the laid-out child
/// and generates bones automatically: one rounded bar per line of text,
/// rectangles for images, inputs and colored boxes, circles for avatars.
/// Build your normal UI with sample data and wrap it:
///
/// ```dart
/// ShaderSkeleton(
///   isLoading: user == null,
///   child: ListTile(
///     leading: const CircleAvatar(),
///     title: Text(user?.name ?? 'Placeholder name'),
///     subtitle: Text(user?.email ?? 'placeholder@email.com'),
///   ),
/// )
/// ```
///
/// Every skeleton on screen shimmers in sync because the shine is computed
/// in screen space. Use [SkeletonBone] for explicit shapes and
/// [SkeletonIgnore] to leave parts out. Taps are blocked and the content is
/// hidden from screen readers while loading; [semanticsLabel] is announced
/// instead.
class ShaderSkeleton extends StatefulWidget {
  /// Creates a skeleton loader around [child].
  const ShaderSkeleton({
    super.key,
    required this.child,
    this.isLoading = true,
    this.effect = SkeletonEffect.shimmer,
    this.baseColor,
    this.highlightColor,
    this.accentColor,
    this.speed = 1.0,
    this.angle = 0.35,
    this.bandWidth = 0.22,
    this.boneRadius = 8,
    this.textBoneHeight = 0.62,
    this.transitionDuration = const Duration(milliseconds: 450),
    this.semanticsLabel = 'Loading',
    this.animate = true,
  })  : assert(speed >= 0, 'speed must not be negative'),
        assert(
          textBoneHeight > 0 && textBoneHeight <= 1,
          'textBoneHeight is a fraction of the line height',
        );

  /// The content; it is laid out normally and used to shape the bones.
  final Widget child;

  /// Whether the skeleton is shown. Changes cross-fade.
  final bool isLoading;

  /// Animation style of the bones.
  final SkeletonEffect effect;

  /// Bone color. Defaults to a neutral gray matching the theme brightness.
  final Color? baseColor;

  /// Shine color. Defaults to a lighter gray matching the theme brightness.
  final Color? highlightColor;

  /// Tint used by [SkeletonEffect.glow]. Defaults to the theme's primary
  /// color blended into [highlightColor].
  final Color? accentColor;

  /// Animation speed multiplier.
  final double speed;

  /// Direction of the shine in radians (0 = left to right).
  final double angle;

  /// Width of the shine as a fraction of the screen.
  final double bandWidth;

  /// Corner radius of generated rectangular bones.
  final double boneRadius;

  /// Height of a text bone as a fraction of its line height.
  final double textBoneHeight;

  /// Duration of the skeleton-to-content cross-fade.
  final Duration transitionDuration;

  /// Announced by screen readers while loading.
  final String semanticsLabel;

  /// Whether the shine animates. Platform "reduce motion" is respected.
  final bool animate;

  @override
  State<ShaderSkeleton> createState() => _ShaderSkeletonState();
}

class _ShaderSkeletonState extends State<ShaderSkeleton>
    with TickerProviderStateMixin<ShaderSkeleton> {
  late final AnimationController _reveal;
  late final Ticker _ticker;
  final ShaderClock _clock = ShaderClock();
  ui.FragmentShader? _shader;
  bool _reduceMotion = false;
  ShaderTheme? _theme;
  double _lastFrameSeconds = 0;

  bool get _motion =>
      widget.animate && (_theme?.animate ?? true) && !_reduceMotion;

  double get _time {
    if (!_motion) return 0;
    // The frame time stamp is shared by every skeleton, so all of them
    // shimmer in sync (and it honors timeDilation).
    final SchedulerBinding binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.idle) {
      _lastFrameSeconds = binding.currentFrameTimeStamp.inMicroseconds / 1e6;
    }
    return _lastFrameSeconds * widget.speed * (_theme?.speed ?? 1);
  }

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      value: widget.isLoading ? 0 : 1,
      duration: widget.transitionDuration,
    )..addListener(_clock.tick);
    _ticker = createTicker((_) => _clock.tick());
    final ui.FragmentProgram? program =
        ShaderLibrary.cached(ShaderEffect.skeleton);
    if (program != null) {
      _shader = program.fragmentShader();
    } else {
      ShaderLibrary.load(ShaderEffect.skeleton).then((ui.FragmentProgram p) {
        if (!mounted) return;
        setState(() => _shader = p.fragmentShader());
      }, onError: (Object _) {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _theme = ShaderTheme.maybeOf(context);
    _reveal.duration =
        _reduceMotion ? Duration.zero : widget.transitionDuration;
    _syncTicker();
  }

  @override
  void didUpdateWidget(ShaderSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reveal.duration =
        _reduceMotion ? Duration.zero : widget.transitionDuration;
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _reveal.reverse();
      } else {
        _reveal.forward();
      }
    }
    _syncTicker();
  }

  void _syncTicker() {
    final bool run = widget.isLoading && _motion;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _reveal.dispose();
    _clock.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color base = widget.baseColor ??
        (dark ? const Color(0xFF24262D) : const Color(0xFFE5E7EB));
    final Color high = widget.highlightColor ??
        (dark ? const Color(0xFF454959) : const Color(0xFFF8F9FB));
    final Color accent = widget.accentColor ??
        Color.lerp(high, theme.colorScheme.primary, 0.55)!;
    return RepaintBoundary(
      child: Semantics(
        label: widget.isLoading ? widget.semanticsLabel : null,
        child: ExcludeSemantics(
          excluding: widget.isLoading,
          child: _SkeletonRender(
            state: this,
            base: base,
            high: high,
            accent: accent,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SkeletonRender extends SingleChildRenderObjectWidget {
  const _SkeletonRender({
    required this.state,
    required this.base,
    required this.high,
    required this.accent,
    required super.child,
  });

  final _ShaderSkeletonState state;
  final Color base;
  final Color high;
  final Color accent;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShaderSkeleton(state: state)..configure(this, context);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderShaderSkeleton renderObject,
  ) =>
      renderObject.configure(this, context);
}

class _Bone {
  const _Bone(this.rect, this.radius, {this.circle = false});
  final Rect rect;
  final double radius;
  final bool circle;
}

class _RenderShaderSkeleton extends RenderProxyBox {
  _RenderShaderSkeleton({required _ShaderSkeletonState state}) : _state = state;

  _ShaderSkeletonState _state;
  Color _base = const Color(0xFFE5E7EB);
  Color _high = const Color(0xFFF8F9FB);
  Color _accent = const Color(0xFFB0B8FF);
  Size _view = const Size(400, 800);
  final LayerHandle<OpacityLayer> _opacity = LayerHandle<OpacityLayer>();

  void configure(_SkeletonRender w, BuildContext context) {
    if (!identical(_state, w.state) && attached) {
      _state._clock.removeListener(markNeedsPaint);
      w.state._clock.addListener(markNeedsPaint);
    }
    _state = w.state;
    _base = w.base;
    _high = w.high;
    _accent = w.accent;
    _view = MediaQuery.maybeSizeOf(context) ?? _view;
    markNeedsPaint();
  }

  double get _revealValue => _state._reveal.value;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _state._clock.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _state._clock.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _opacity.layer = null;
    super.dispose();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_revealValue < 0.999) {
      // Absorb taps while loading.
      if (size.contains(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
      return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) return;
    final double reveal = _revealValue;
    if (reveal >= 0.999) {
      _opacity.layer = null;
      context.paintChild(child, offset);
      return;
    }
    if (reveal > 0.001) {
      _opacity.layer = context.pushOpacity(
        offset,
        (reveal * 255).round(),
        (PaintingContext c, Offset o) => c.paintChild(child, o),
        oldLayer: _opacity.layer,
      );
    } else {
      _opacity.layer = null;
    }

    final List<_Bone> bones = <_Bone>[];
    _collect(child, bones);
    if (bones.isEmpty) return;

    final Path path = Path();
    for (final _Bone b in bones) {
      final Rect r = b.rect.shift(offset);
      if (b.circle) {
        path.addOval(r);
      } else {
        path.addRRect(
          RRect.fromRectAndRadius(
            r,
            Radius.circular(math.min(b.radius, r.shortestSide / 2)),
          ),
        );
      }
    }

    final double opacity = 1 - reveal;
    final Canvas canvas = context.canvas;
    canvas
      ..save()
      ..clipRect(offset & size)
      ..clipPath(path);
    final ui.FragmentShader? shader = _state._shader;
    if (shader == null) {
      canvas.drawRect(
        offset & size,
        Paint()..color = _base.withValues(alpha: _base.a * opacity),
      );
    } else {
      final Offset origin = localToGlobal(Offset.zero);
      final ShaderSkeleton w = _state.widget;
      UniformWriter(shader)
        ..size(size)
        ..float(_state._time)
        ..vec2(origin.dx, origin.dy)
        ..size(_view)
        ..color(_base)
        ..color(_high)
        ..color(_accent)
        ..float(w.effect.index.toDouble())
        ..float(w.angle)
        ..float(w.bandWidth)
        ..float(opacity);
      canvas
        ..translate(offset.dx, offset.dy)
        ..drawRect(Offset.zero & size, Paint()..shader = shader);
    }
    canvas.restore();
  }

  Rect _rectOf(RenderBox box, Rect local) =>
      MatrixUtils.transformRect(box.getTransformTo(this), local);

  void _collect(RenderObject node, List<_Bone> out) {
    if (node is _RenderSkeletonIgnore) return;
    if (node is RenderOffstage && node.offstage) return;
    if (node is RenderOpacity && node.opacity == 0) return;
    if (node is _RenderBoneMarker) {
      if (node.hasSize && !node.size.isEmpty) {
        out.add(_Bone(
          _rectOf(node, Offset.zero & node.size),
          node.radius,
          circle: node.circle,
        ));
      }
      return;
    }
    if (node is RenderBox) {
      if (!node.hasSize || node.size.isEmpty) return;
      if (node is RenderParagraph) {
        _addText(node, out);
        return;
      }
      if (node is RenderImage || node is RenderEditable) {
        out.add(_Bone(_rectOf(node, Offset.zero & node.size), _radius()));
        return;
      }
      if (node is RenderClipOval) {
        out.add(_Bone(_rectOf(node, Offset.zero & node.size), 0, circle: true));
        return;
      }
      if (node is RenderDecoratedBox) {
        final Decoration d = node.decoration;
        final bool circle =
            (d is BoxDecoration && d.shape == BoxShape.circle) ||
                (d is ShapeDecoration && d.shape is CircleBorder);
        if (circle) {
          out.add(
            _Bone(_rectOf(node, Offset.zero & node.size), 0, circle: true),
          );
          return;
        }
      }
    }
    final int before = out.length;
    node.visitChildren((RenderObject c) => _collect(c, out));
    if (out.length == before && node is RenderDecoratedBox) {
      // A decorated box with no content of its own (a colored tile, a
      // divider-like bar) becomes one bone with its own corner radius.
      final Decoration d = node.decoration;
      double radius = _radius();
      if (d is BoxDecoration && d.borderRadius != null) {
        radius = d.borderRadius!.resolve(TextDirection.ltr).topLeft.x;
      }
      out.add(_Bone(_rectOf(node, Offset.zero & node.size), radius));
    }
  }

  double _radius() => _state.widget.boneRadius;

  void _addText(RenderParagraph p, List<_Bone> out) {
    final String text = p.text.toPlainText(includeSemanticsLabels: false);
    if (text.trim().isEmpty) return;
    final List<TextBox> boxes = p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    final List<Rect> lines = <Rect>[];
    for (final TextBox box in boxes) {
      final Rect r = box.toRect();
      if (r.width < 0.5 || r.height < 0.5) continue;
      final int i = lines.indexWhere(
        (Rect l) => (l.center.dy - r.center.dy).abs() < r.height * 0.5,
      );
      if (i < 0) {
        lines.add(r);
      } else {
        lines[i] = lines[i].expandToInclude(r);
      }
    }
    final Matrix4 m = p.getTransformTo(this);
    final double f = _state.widget.textBoneHeight;
    for (final Rect line in lines) {
      final double h = math.max(4, line.height * f);
      final Rect bar = Rect.fromLTWH(
        line.left,
        line.center.dy - h / 2,
        math.max(line.width, h),
        h,
      );
      out.add(_Bone(MatrixUtils.transformRect(m, bar), h * 0.45));
    }
  }
}

/// An explicit placeholder shape for [ShaderSkeleton].
///
/// Inside a loading skeleton it becomes a bone of exactly this size. Outside
/// one it paints a plain, theme-aware gray shape.
///
/// ```dart
/// const SkeletonBone(width: 120, height: 14)
/// const SkeletonBone.circle(size: 48)
/// const SkeletonBone.text(lines: 3)
/// ```
class SkeletonBone extends StatelessWidget {
  /// A rounded rectangle bone. A null [width] fills the available width.
  const SkeletonBone({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 8,
    this.color,
  })  : _circle = false,
        lines = null,
        spacing = 0,
        lastLineFraction = 1;

  /// A circular bone, e.g. for an avatar.
  const SkeletonBone.circle({super.key, required double size, this.color})
      : width = size,
        height = size,
        borderRadius = 0,
        _circle = true,
        lines = null,
        spacing = 0,
        lastLineFraction = 1;

  /// A paragraph of [lines] text bars; the last one is shorter.
  const SkeletonBone.text({
    super.key,
    int this.lines = 3,
    this.height = 12,
    this.spacing = 8,
    this.lastLineFraction = 0.6,
    this.color,
  })  : width = null,
        borderRadius = 6,
        _circle = false;

  /// Bone width; null fills the available width.
  final double? width;

  /// Bone (or line) height.
  final double height;

  /// Corner radius of rectangular bones.
  final double borderRadius;

  /// Paint color outside a skeleton; defaults to a theme-aware gray.
  final Color? color;

  /// Number of lines for [SkeletonBone.text], null otherwise.
  final int? lines;

  /// Gap between text lines.
  final double spacing;

  /// Width of the last text line as a fraction of the full width.
  final double lastLineFraction;

  final bool _circle;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color c =
        color ?? (dark ? const Color(0xFF24262D) : const Color(0xFFE5E7EB));
    Widget bone(double? w, {double fraction = 1}) {
      Widget b = _BoneMarker(
        circle: _circle,
        radius: borderRadius,
        color: c,
        child: SizedBox(width: w, height: height),
      );
      if (fraction < 1) {
        b = FractionallySizedBox(
          widthFactor: fraction,
          alignment: AlignmentDirectional.centerStart,
          child: b,
        );
      }
      return b;
    }

    final int? n = lines;
    if (n == null) return bone(width);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < n; i++) ...<Widget>[
          if (i > 0) SizedBox(height: spacing),
          bone(null, fraction: i == n - 1 && n > 1 ? lastLineFraction : 1),
        ],
      ],
    );
  }
}

class _BoneMarker extends SingleChildRenderObjectWidget {
  const _BoneMarker({
    required this.circle,
    required this.radius,
    required this.color,
    super.child,
  });

  final bool circle;
  final double radius;
  final Color color;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBoneMarker(circle, radius, color);

  @override
  void updateRenderObject(BuildContext context, _RenderBoneMarker r) {
    r
      ..circle = circle
      ..radius = radius
      ..color = color
      ..markNeedsPaint();
  }
}

class _RenderBoneMarker extends RenderProxyBox {
  _RenderBoneMarker(this.circle, this.radius, this.color);

  bool circle;
  double radius;
  Color color;

  @override
  void paint(PaintingContext context, Offset offset) {
    final Rect r = offset & size;
    final Paint paint = Paint()..color = color;
    if (circle) {
      context.canvas.drawOval(r, paint);
    } else {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          r,
          Radius.circular(math.min(radius, r.shortestSide / 2)),
        ),
        paint,
      );
    }
    super.paint(context, offset);
  }
}

/// Excludes [child] from the bones of an enclosing [ShaderSkeleton].
///
/// Useful for decorative parts (dividers, background art) that should not
/// turn into placeholder shapes. Ignored parts are hidden while loading.
class SkeletonIgnore extends SingleChildRenderObjectWidget {
  /// Creates a skeleton exclusion.
  const SkeletonIgnore({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSkeletonIgnore();
}

class _RenderSkeletonIgnore extends RenderProxyBox {}
