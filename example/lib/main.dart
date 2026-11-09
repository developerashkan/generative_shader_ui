import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:generative_shader_ui/generative_shader_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional: warm up every shader so the first frame is already GPU-rendered.
  await ShaderLibrary.precache();
  runApp(const GalleryApp());
}

/// Showcase of every widget in `generative_shader_ui`.
class GalleryApp extends StatelessWidget {
  /// Creates the gallery app.
  const GalleryApp({super.key, this.scene});

  /// Optional single scene to show (used for README screenshots).
  final String? scene;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'generative_shader_ui',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07070D),
        colorSchemeSeed: const Color(0xFF8B5CF6),
        useMaterial3: true,
      ),
      home: GalleryPage(scene: scene),
    );
  }
}

/// The gallery screen.
class GalleryPage extends StatefulWidget {
  /// Creates the gallery screen.
  const GalleryPage({super.key, this.scene});

  /// Optional single scene to show.
  final String? scene;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  ShaderPalette _palette = ShaderPalette.siri;
  bool _voice = true;
  double _amplitude = 0.3;
  double _progress = 0.68;
  Timer? _timer;
  final math.Random _rng = math.Random(7);
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    // Simulated microphone level. In a real app feed the level from any
    // audio plugin (record, flutter_sound, ...) into `amplitude`.
    _timer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (!_voice) return;
      _phase += 0.07;
      final double syllables = math.max(0, math.sin(_phase * 5.3)) *
          (0.5 + 0.5 * math.sin(_phase * 1.1));
      setState(() {
        _amplitude = (syllables * 0.9 + _rng.nextDouble() * 0.15).clamp(0, 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Widget> sections = <String, Widget>{
      'hero': _hero(),
      'siri': _siriSection(),
      'buttons': _buttonsSection(),
      'progress': _progressSection(),
      'containers': _containersSection(),
    };

    final String? scene = widget.scene;
    if (scene != null) {
      return Scaffold(body: _sceneFor(scene, sections));
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final bool wide = c.maxWidth >= 1000;
            final List<Widget> cards = <Widget>[
              _Card(title: 'SiriOrb + SiriWave', child: sections['siri']!),
              _Card(title: 'NeonButton', child: sections['buttons']!),
              _Card(title: 'Progress', child: sections['progress']!),
              _Card(title: 'Containers', child: sections['containers']!),
            ];
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                sections['hero']!,
                const SizedBox(height: 16),
                _paletteBar(),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: cards[0]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            cards[1],
                            const SizedBox(height: 16),
                            cards[2],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: cards[3]),
                    ],
                  )
                else
                  for (final Widget card in cards) ...<Widget>[
                    card,
                    const SizedBox(height: 16),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sceneFor(String scene, Map<String, Widget> sections) {
    switch (scene) {
      case 'siri':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SiriOrb(size: 260, palette: _palette, amplitude: _amplitude),
              SiriWave(
                width: 520,
                height: 110,
                palette: _palette,
                amplitude: _amplitude,
              ),
            ],
          ),
        );
      case 'controls':
        return Center(
          child: SizedBox(
            width: 760,
            child: Row(
              children: <Widget>[
                Expanded(child: sections['buttons']!),
                const SizedBox(width: 40),
                Expanded(child: sections['progress']!),
              ],
            ),
          ),
        );
      case 'aurora':
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              Expanded(child: sections['hero']!),
              const SizedBox(height: 20),
              SizedBox(height: 200, child: sections['containers']!),
            ],
          ),
        );
      default:
        return sections[scene] ?? const SizedBox();
    }
  }

  Widget _hero() {
    return AuroraBackground(
      height: 230,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(28),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ShaderGradientText('Generative Shader UI', palette: _palette),
          const SizedBox(height: 8),
          const Text(
            'GPU shader widgets. Drop them in the tree and boom.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _paletteBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final MapEntry<String, ShaderPalette> e
            in ShaderPalette.presets.entries)
          ChoiceChip(
            label: Text(e.key),
            selected: _palette == e.value,
            avatar: CircleAvatar(backgroundColor: e.value.color2),
            onSelected: (_) => setState(() => _palette = e.value),
          ),
      ],
    );
  }

  Widget _siriSection() {
    return Column(
      children: <Widget>[
        SiriOrb(size: 220, palette: _palette, amplitude: _amplitude),
        SiriWave(height: 100, palette: _palette, amplitude: _amplitude),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulated voice'),
            value: _voice,
            onChanged: (bool v) => setState(() => _voice = v),
          ),
        ),
        Slider(
          value: _amplitude,
          onChanged:
              _voice ? null : (double v) => setState(() => _amplitude = v),
        ),
      ],
    );
  }

  Widget _buttonsSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NeonButton(
          palette: _palette,
          onPressed: () => ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Boom!'))),
          child: const Text('Get started'),
        ),
        const SizedBox(height: 22),
        NeonButton(
          palette: ShaderPalette.cyberpunk,
          borderRadius: 40,
          onPressed: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.mic),
              SizedBox(width: 8),
              Text('Talk to me'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const NeonButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }

  Widget _progressSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ShaderCircularProgressIndicator(
              value: _progress,
              size: 96,
              strokeWidth: 9,
              palette: _palette,
              child: Text(
                '${(_progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ShaderCircularProgressIndicator(palette: _palette, size: 72),
          ],
        ),
        const SizedBox(height: 28),
        ShaderLinearProgressIndicator(value: _progress, palette: _palette),
        const SizedBox(height: 24),
        ShaderLinearProgressIndicator(
          palette: ShaderPalette.neon,
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        Slider(
          value: _progress,
          onChanged: (double v) => setState(() => _progress = v),
        ),
      ],
    );
  }

  Widget _containersSection() {
    return Row(
      children: <Widget>[
        Expanded(
          child: ShaderGradient(
            palette: _palette,
            height: 180,
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(18),
            alignment: Alignment.bottomLeft,
            child: const Text(
              'ShaderGradient\ntouch me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NeonContainer(
            palette: ShaderPalette.aurora,
            height: 180,
            borderRadius: 24,
            alignment: Alignment.center,
            child: const ShaderGradientMask(
              palette: ShaderPalette.aurora,
              child: Icon(Icons.bolt, size: 96),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10101A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
