## 1.1.0

* **`ShaderSkeleton`** - skeleton loader that builds its bones automatically
  from your real layout (text lines, images, avatars, inputs, colored boxes).
  Three effects (`shimmer`, `pulse`, `glow`), screen-space shine that stays in
  sync across every skeleton, smooth cross-fade to content, taps blocked and
  a "Loading" label for screen readers while loading. `SkeletonBone`
  (`.circle`, `.text`) and `SkeletonIgnore` for fine control.
* **`LiquidGlass`** - blurred and saturated backdrop with a pointer-following
  specular highlight, rim light, iridescent edge, sheen and grain.
* **`ParticleField`** - snow, embers, fireflies, bokeh, rain, confetti and
  warp, fully procedural in one draw call, touch reactive.
* **`ShaderReveal`**, **`AnimatedShaderReveal`**, **`ShaderRevealRoute`** and
  `ShaderReveal.transitionBuilder` - dissolve, burn, iris, wipe, pixel and
  liquid transitions for widgets, `AnimatedSwitcher` and page routes.
* **`ShaderRipple`** (with `ShaderRippleController`), **`ShaderPulse`**,
  **`LiquidWaves`** and **`ShaderShimmer`**.
* **`ShaderTheme`** - set the palette, speed, animation switch and a frame
  rate cap (`maxFps`) for a whole subtree. Widget `palette` parameters are now
  nullable and fall back to the theme, then to their previous defaults.
* New `ShaderPalette.frost` and `ShaderPalette.firefly` presets.
* Fix: a `GestureDetector` wrapped around a touch-reactive widget (for example
  `ShaderGradient`) now receives taps.

## 1.0.0

* Initial release.
* Widgets: `SiriOrb`, `SiriWave`, `NeonButton`, `NeonContainer`,
  `ShaderGradient`, `AuroraBackground`, `ShaderCircularProgressIndicator`,
  `ShaderLinearProgressIndicator`, `ShaderGradientText`, `ShaderGradientMask`.
* `ShaderPalette` with 9 presets and smooth palette cross-fades.
* `ShaderLibrary.precache()` for first-frame GPU rendering.
* Audio-amplitude smoothing, touch and hover reactivity, reduce-motion support.
* Supports Android, iOS, web (CanvasKit and WASM), Windows, macOS and Linux.
