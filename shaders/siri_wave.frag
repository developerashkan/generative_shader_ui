// generative_shader_ui :: layered Siri-style voice waves.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform float uAmp;
uniform float uThickness;
uniform float uGlow;

out vec4 fragColor;

float waveY(float x, float fi, float t, float amp) {
  float e = max(1.0 - x * x, 0.0);
  float att = e * sqrt(e);
  float k = 1.6 + fi * 0.55;
  float sp = 1.2 + fi * 0.35;
  float a = amp * (1.05 - fi * 0.14) * (0.75 + 0.25 * sin(t * 0.9 + fi * 2.3));
  return att * a * sin(x * k * 3.14159 + t * sp + fi * 1.7)
      * (0.6 + 0.4 * sin(x * 2.1 - t * 0.7 + fi));
}

vec3 wave(vec2 p, float fi, vec3 color, float t, float amp, float px) {
  float y = waveY(p.x, fi, t, amp);
  float d = abs(p.y - y);
  float th = max(uThickness, 0.5) * px;
  float line = 1.0 - smoothstep(th * 0.5, th * 0.5 + px * 1.5, d);
  float glow = exp(-d / (px * 6.0 * max(uGlow, 0.05))) * 0.55;
  float fill = step(0.0, p.y * y)
      * (1.0 - smoothstep(abs(y) - px, abs(y) + px, abs(p.y))) * 0.22;
  return color * (line + glow + fill);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = vec2(frag.x / uSize.x * 2.0 - 1.0, frag.y / uSize.y * 2.0 - 1.0);
  float px = 2.0 / uSize.y;
  float amp = clamp(uAmp, 0.0, 1.2) * 0.9 + 0.03;
  float t = uTime;

  vec3 col = vec3(0.0);
  col += wave(p, 0.0, uC0.rgb, t, amp, px);
  col += wave(p, 1.0, uC1.rgb, t, amp, px);
  col += wave(p, 2.0, uC2.rgb, t, amp, px);
  col += wave(p, 3.0, uC3.rgb, t, amp, px);

  float edge = 1.0 - p.x * p.x;
  col += mix(uC0.rgb, uC1.rgb, 0.5 + 0.5 * p.x) * exp(-abs(p.y) / (px * 2.0))
      * 0.16 * edge * (1.0 - smoothstep(0.0, 0.35, uAmp));

  col = vec3(1.0) - exp(-col * 1.4);
  float alpha = clamp(max(col.r, max(col.g, col.b)), 0.0, 1.0);
  fragColor = vec4(min(col, vec3(alpha)), alpha);
}
