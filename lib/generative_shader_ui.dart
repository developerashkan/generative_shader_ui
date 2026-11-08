/// Drop-in, GPU shader powered Flutter widgets.
///
/// Every widget works with zero configuration - add it to the widget tree
/// and it animates. Customize everything through plain Dart properties; no
/// GLSL required.
///
/// * [SiriOrb] - fluid, audio-reactive assistant orb.
/// * [SiriWave] - layered glowing voice waves.
/// * [NeonButton] and [NeonContainer] - animated neon borders and glow.
/// * [ShaderGradient] - living mesh gradient container.
/// * [AuroraBackground] - northern lights backdrop.
/// * [ShaderCircularProgressIndicator] and [ShaderLinearProgressIndicator].
/// * [ShaderGradientText] and [ShaderGradientMask] - gradient-filled content.
/// * [ShaderPalette] - shared four-color theming with smooth cross-fades.
/// * [ShaderLibrary] - optional shader precaching.
library;

export 'src/palette.dart';
export 'src/shader_library.dart';
export 'src/widgets/aurora_background.dart';
export 'src/widgets/neon_button.dart';
export 'src/widgets/neon_container.dart';
export 'src/widgets/shader_gradient.dart';
export 'src/widgets/shader_gradient_text.dart';
export 'src/widgets/shader_progress.dart';
export 'src/widgets/siri_orb.dart';
export 'src/widgets/siri_wave.dart';
