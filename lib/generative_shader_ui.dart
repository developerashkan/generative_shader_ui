/// Drop-in, GPU shader powered Flutter widgets.
///
/// Every widget works with zero configuration - add it to the widget tree
/// and it animates. Customize everything through plain Dart properties; no
/// GLSL required.
///
/// Voice & AI:
/// * [SiriOrb] - fluid, audio-reactive assistant orb.
/// * [SiriWave] - layered glowing voice waves.
///
/// Loading & feedback:
/// * [ShaderSkeleton] - skeleton loader that builds its bones from your real
///   layout; [SkeletonBone] and [SkeletonIgnore] for fine control.
/// * [ShaderShimmer] - glossy shine over any widget.
/// * [ShaderCircularProgressIndicator] and [ShaderLinearProgressIndicator].
/// * [LiquidWaves] - liquid fill gauge or hero background.
/// * [ShaderPulse] - radar rings for live and listening states.
/// * [ShaderRipple] - glowing touch ripples.
///
/// Surfaces & backgrounds:
/// * [LiquidGlass] - blurred, light-catching glass panels.
/// * [NeonButton] and [NeonContainer] - animated neon borders and glow.
/// * [ShaderGradient] - living mesh gradient container.
/// * [AuroraBackground] - northern lights backdrop.
/// * [ParticleField] - snow, embers, fireflies, bokeh, rain, confetti, warp.
/// * [ShaderGradientText] and [ShaderGradientMask] - gradient-filled content.
///
/// Motion:
/// * [ShaderReveal], [AnimatedShaderReveal] and [ShaderRevealRoute] -
///   dissolve, burn, iris, wipe, pixel and liquid transitions.
///
/// Theming & performance:
/// * [ShaderPalette] - shared four-color theming with smooth cross-fades.
/// * [ShaderTheme] - subtree defaults: palette, speed, animate, max FPS.
/// * [ShaderLibrary] - optional shader precaching.
library;

export 'src/palette.dart';
export 'src/shader_library.dart';
export 'src/shader_theme.dart';
export 'src/widgets/aurora_background.dart';
export 'src/widgets/liquid_glass.dart';
export 'src/widgets/liquid_waves.dart';
export 'src/widgets/neon_button.dart';
export 'src/widgets/neon_container.dart';
export 'src/widgets/particle_field.dart';
export 'src/widgets/shader_gradient.dart';
export 'src/widgets/shader_gradient_text.dart';
export 'src/widgets/shader_progress.dart';
export 'src/widgets/shader_pulse.dart';
export 'src/widgets/shader_reveal.dart';
export 'src/widgets/shader_ripple.dart';
export 'src/widgets/shader_shimmer.dart';
export 'src/widgets/shader_skeleton.dart';
export 'src/widgets/siri_orb.dart';
export 'src/widgets/siri_wave.dart';
