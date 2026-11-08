import 'dart:async';
import 'dart:ui' as ui;

/// The GPU fragment programs bundled with this package.
enum ShaderEffect {
  /// Animated four-point mesh gradient used by `ShaderGradient` and text masks.
  meshGradient('mesh_gradient'),

  /// Fluid Siri-style orb.
  siriOrb('siri_orb'),

  /// Layered voice waves.
  siriWave('siri_wave'),

  /// Neon rounded-rect border with glow.
  neonBorder('neon_border'),

  /// Gradient arc for circular progress.
  circularProgress('circular_progress'),

  /// Liquid bar for linear progress.
  linearProgress('linear_progress'),

  /// Northern lights background.
  aurora('aurora');

  const ShaderEffect(this.fileName);

  /// File name of the shader without extension.
  final String fileName;

  /// The asset key used when this package is a dependency of an app.
  String get assetKey => 'packages/generative_shader_ui/shaders/$fileName.frag';
}

/// Loads and caches the package's compiled fragment programs.
///
/// Widgets load their shaders lazily, so calling this is optional. Call
/// [precache] before `runApp` to make sure the very first frame of every
/// widget is rendered by the GPU shader instead of the gradient fallback:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await ShaderLibrary.precache();
///   runApp(const MyApp());
/// }
/// ```
abstract final class ShaderLibrary {
  static final Map<ShaderEffect, Future<ui.FragmentProgram>> _pending =
      <ShaderEffect, Future<ui.FragmentProgram>>{};
  static final Map<ShaderEffect, ui.FragmentProgram> _ready =
      <ShaderEffect, ui.FragmentProgram>{};

  /// Returns the program for [effect] if it has already finished loading.
  static ui.FragmentProgram? cached(ShaderEffect effect) => _ready[effect];

  /// Whether [effect] has finished loading.
  static bool isLoaded(ShaderEffect effect) => _ready.containsKey(effect);

  /// Loads (once) and returns the program for [effect].
  static Future<ui.FragmentProgram> load(ShaderEffect effect) {
    final ui.FragmentProgram? ready = _ready[effect];
    if (ready != null) return Future<ui.FragmentProgram>.value(ready);
    return _pending.putIfAbsent(effect, () async {
      try {
        ui.FragmentProgram program;
        try {
          program = await ui.FragmentProgram.fromAsset(effect.assetKey);
        } on Object {
          // Inside this package's own tests the asset is not prefixed.
          program = await ui.FragmentProgram.fromAsset(
            'shaders/${effect.fileName}.frag',
          );
        }
        _ready[effect] = program;
        return program;
      } finally {
        unawaited(_pending.remove(effect));
      }
    });
  }

  /// Loads every shader in [effects] (all of them by default).
  ///
  /// Failures are swallowed: widgets fall back to plain gradients when a
  /// shader cannot be loaded, so the app keeps working.
  static Future<void> precache([
    Iterable<ShaderEffect> effects = ShaderEffect.values,
  ]) async {
    await Future.wait(
      effects.map(
        (ShaderEffect e) => load(e).then<void>((_) {}, onError: (_) {}),
      ),
    );
  }
}
