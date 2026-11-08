// generative_shader_ui :: animated neon rounded-rect border with glow, glassy
// fill, travelling comet highlight and touch light.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform float uRadius;
uniform float uStroke;
uniform float uGlow;
uniform float uInset;
uniform vec4 uFill;
uniform float uHighlight;
uniform vec3 uTouch;

out vec4 fragColor;

vec3 cyc(float s) {
  float x = fract(s) * 4.0;
  if (x < 1.0) return mix(uC0.rgb, uC1.rgb, smoothstep(0.0, 1.0, x));
  if (x < 2.0) return mix(uC1.rgb, uC2.rgb, smoothstep(0.0, 1.0, x - 1.0));
  if (x < 3.0) return mix(uC2.rgb, uC3.rgb, smoothstep(0.0, 1.0, x - 2.0));
  return mix(uC3.rgb, uC0.rgb, smoothstep(0.0, 1.0, x - 3.0));
}

float sdRoundRect(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + vec2(r);
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 c = 0.5 * uSize;
  vec2 p = frag - c;
  vec2 b = max(c - vec2(uInset), vec2(1.0));
  float r = clamp(uRadius, 0.0, min(b.x, b.y));
  float d = sdRoundRect(p, b, r);

  float ang = atan(p.y, p.x) / 6.2831853;
  vec3 neon = cyc(ang - uTime * 0.12);
  float comet = pow(0.5 + 0.5 * cos(fract(ang - uTime * 0.25) * 6.2831853), 12.0);
  float hl = clamp(uHighlight, 0.0, 1.0);

  float hw = 0.5 * uStroke;
  float ad = abs(d + hw);
  float stroke = 1.0 - smoothstep(hw - 0.8, hw + 0.8, ad);
  float g = exp(-max(ad - hw, 0.0) / max(uGlow * 0.4, 0.5));
  g *= 1.0 - smoothstep(uInset * 0.7, uInset + 0.001, d);
  float inner = 1.0 - smoothstep(-0.8, 0.8, d);

  vec2 tp = uTouch.xy * uSize;
  vec2 tv = frag - tp;
  float tl = uTouch.z * exp(-dot(tv, tv) / (0.02 * dot(uSize, uSize) + 1.0));

  vec3 fillRgb = clamp(uFill.rgb + neon * (0.06 + 0.22 * hl) + neon * tl * 0.35, 0.0, 1.0);
  float fillA = clamp(uFill.a + 0.15 * hl + tl * 0.2, 0.0, 1.0) * inner;

  float sa = clamp(stroke * (0.85 + 0.15 * comet), 0.0, 1.0);
  vec3 neonCol = clamp(neon * (1.0 + comet * 0.8 + hl * 0.3), 0.0, 1.0);
  vec3 rgb = fillRgb * fillA * (1.0 - sa) + neonCol * sa;
  float a = fillA * (1.0 - sa) + sa;

  float ga = clamp(g * 0.55 * (0.75 + 0.6 * hl) * (0.7 + 0.6 * comet), 0.0, 1.0) * (1.0 - sa);
  a = clamp(a + ga * (1.0 - a), 0.0, 1.0);
  rgb = rgb + neon * ga;
  fragColor = vec4(min(rgb, vec3(a)), a);
}
