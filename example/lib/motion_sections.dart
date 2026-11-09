import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:generative_shader_ui/generative_shader_ui.dart';

/// Slows the demos' own timers down; screenshot capture sets it together
/// with `timeDilation` so slow software renderers still record smooth GIFs.
double demoSlowdown = 1;

Duration _demo(int ms) => Duration(milliseconds: (ms * demoSlowdown).round());

/// Skeleton loader demo: a feed whose bones are generated automatically
/// from the real tiles. Loops loading -> loaded so it can be watched.
class SkeletonDemo extends StatefulWidget {
  /// Creates the skeleton demo.
  const SkeletonDemo({super.key});

  @override
  State<SkeletonDemo> createState() => _SkeletonDemoState();
}

class _SkeletonDemoState extends State<SkeletonDemo> {
  bool _loading = true;
  SkeletonEffect _effect = SkeletonEffect.shimmer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_demo(2600), (_) {
      setState(() => _loading = !_loading);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final SkeletonEffect e in SkeletonEffect.values)
              ChoiceChip(
                label: Text(e.name),
                selected: _effect == e,
                onSelected: (_) => setState(() => _effect = e),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ShaderSkeleton(
          isLoading: _loading,
          effect: _effect,
          child: const Column(
            children: <Widget>[
              _PostTile(
                name: 'Ava Martinez',
                meta: '2h · Design systems',
                body: 'Shipped the new onboarding flow today. '
                    'Skeletons are generated from this exact layout.',
                colors: <Color>[Color(0xFF8B5CF6), Color(0xFF22D3EE)],
              ),
              SizedBox(height: 18),
              _PostTile(
                name: 'Noah Kim',
                meta: '5h · Motion',
                body: 'No placeholder widgets needed - just wrap it.',
                colors: <Color>[Color(0xFFFF6B6B), Color(0xFFFFD43B)],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.name,
    required this.meta,
    required this.body,
    required this.colors,
  });

  final String name;
  final String meta;
  final String body;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: colors.first,
              child: Text(
                name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_horiz, color: Colors.white54),
          ],
        ),
        const SizedBox(height: 12),
        Text(body, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 12),
        Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: colors),
          ),
        ),
      ],
    );
  }
}

/// Liquid glass panels floating over a living gradient with bokeh.
class GlassDemo extends StatelessWidget {
  /// Creates the glass demo.
  const GlassDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ShaderGradient(palette: ShaderPalette.sunset, warp: 1.6),
          const ParticleField(
            style: ParticleStyle.bokeh,
            palette: ShaderPalette.candy,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LiquidGlass(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: <Color>[
                                  Color(0xFF7C3AED),
                                  Color(0xFFFF3EA5),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.graphic_eq,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Midnight Drive',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Neon Avenue',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const ShaderLinearProgressIndicator(
                        value: 0.42,
                        minHeight: 5,
                        palette: ShaderPalette.candy,
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Icon(Icons.skip_previous_rounded,
                              color: Colors.white, size: 32),
                          Icon(Icons.pause_circle_filled_rounded,
                              color: Colors.white, size: 48),
                          Icon(Icons.skip_next_rounded,
                              color: Colors.white, size: 32),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const LiquidGlass(
                  borderRadius: 40,
                  padding: EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.home_rounded, color: Colors.white),
                      SizedBox(width: 30),
                      Icon(Icons.search_rounded, color: Colors.white70),
                      SizedBox(width: 30),
                      Icon(Icons.favorite_rounded, color: Colors.white70),
                      SizedBox(width: 30),
                      Icon(Icons.person_rounded, color: Colors.white70),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every [ParticleStyle] on its own tile.
class ParticlesDemo extends StatelessWidget {
  /// Creates the particles demo.
  const ParticlesDemo({super.key, this.tileWidth = 200, this.tileHeight = 150});

  /// Width of one tile.
  final double tileWidth;

  /// Height of one tile.
  final double tileHeight;

  static const Map<ParticleStyle, List<Color>> _backgrounds =
      <ParticleStyle, List<Color>>{
    ParticleStyle.snow: <Color>[Color(0xFF0B1A33), Color(0xFF1E3A5F)],
    ParticleStyle.embers: <Color>[Color(0xFF1A0505), Color(0xFF3D0A00)],
    ParticleStyle.fireflies: <Color>[Color(0xFF04140C), Color(0xFF0E2A1F)],
    ParticleStyle.bokeh: <Color>[Color(0xFF120A2A), Color(0xFF2A0F3D)],
    ParticleStyle.rain: <Color>[Color(0xFF050B14), Color(0xFF14243A)],
    ParticleStyle.confetti: <Color>[Color(0xFF0D0D18), Color(0xFF1B1530)],
    ParticleStyle.warp: <Color>[Color(0xFF000000), Color(0xFF0B0B22)],
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: <Widget>[
        for (final ParticleStyle style in ParticleStyle.values)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: tileWidth,
              height: tileHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _backgrounds[style]!,
                ),
              ),
              child: ParticleField(
                style: style,
                density: style == ParticleStyle.confetti ? 0.45 : 0.7,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      style.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: const ColoredBox(
              color: Color(0xFF0A0F1F),
              child: LiquidWaves(
                level: 0.55,
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'LiquidWaves',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pulse, liquid gauge, ripples, reveal transitions and shimmer, all
/// running on their own so the demo can be recorded.
class MotionDemo extends StatefulWidget {
  /// Creates the motion demo.
  const MotionDemo({super.key});

  @override
  State<MotionDemo> createState() => _MotionDemoState();
}

class _MotionDemoState extends State<MotionDemo> {
  final ShaderRippleController _ripples = ShaderRippleController();
  final math.Random _rng = math.Random(3);
  Timer? _timer;
  int _tick = 0;
  bool _visible = true;
  int _styleIndex = 0;
  double _level = 0.35;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_demo(800), (_) {
      _tick++;
      _ripples.ripple(
        Offset(20 + _rng.nextDouble() * 220, 20 + _rng.nextDouble() * 110),
      );
      setState(() {
        _level = 0.25 + 0.55 * (0.5 + 0.5 * math.sin(_tick * 0.9));
        if (_tick.isEven) {
          _visible = !_visible;
          if (_visible) {
            _styleIndex = (_styleIndex + 1) % RevealStyle.values.length;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(width: 170),
        SizedBox(
          height: 170,
          child: Center(widthFactor: 1, child: child),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final RevealStyle style = RevealStyle.values[_styleIndex];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 28,
      runSpacing: 24,
      children: <Widget>[
        _labeled(
          'ShaderPulse',
          ShaderPulse(
            child: Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF8B5CF6), Color(0xFF2AF5FF)],
                ),
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 34),
            ),
          ),
        ),
        _labeled(
          'LiquidWaves gauge',
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A1022),
              border: Border.all(color: const Color(0x3390E0EF), width: 2),
            ),
            child: ClipOval(
              child: LiquidWaves(
                level: _level,
                child: Center(
                  child: Text(
                    '${(_level * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _labeled(
          'ShaderRipple',
          ShaderRipple(
            controller: _ripples,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 260,
              height: 150,
              color: const Color(0xFF10101C),
              alignment: Alignment.center,
              child: const Text(
                'Tap anywhere',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ),
        _labeled(
          'ShaderReveal · ${style.name}',
          AnimatedShaderReveal(
            visible: _visible,
            style: style,
            origin: Alignment.topLeft,
            duration: const Duration(milliseconds: 1300),
            child: ShaderGradient(
              width: 240,
              height: 150,
              palette: ShaderPalette.aurora,
              borderRadius: BorderRadius.circular(22),
              alignment: Alignment.center,
              child: const Text(
                'Hello!',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        _labeled(
          'ShaderShimmer',
          ShaderShimmer(
            period: const Duration(milliseconds: 1800),
            child: Container(
              width: 230,
              height: 140,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFB8860B),
                    Color(0xFFFFD86B),
                    Color(0xFF8A6100),
                  ],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.workspace_premium, color: Colors.white),
                  Spacer(),
                  Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
