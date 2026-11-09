// generative_shader_ui :: radar-style rings pulsing out of a widget, with a
// soft halo. Used for "live", "listening" and attention states.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform float uSpread;
uniform float uRings;
uniform float uIntensity;
uniform float uRadius;

out vec4 fragColor;

vec3 cyc(float s) {
  float x = fract(s) * 3.0;
  if (x < 1.0) return mix(uC0.rgb, uC1.rgb, smoothstep(0.0, 1.0, x));
  if (x < 2.0) return mix(uC1.rgb, uC2.rgb, smoothstep(0.0, 1.0, x - 1.0));
  return mix(uC2.rgb, uC0.rgb, smoothstep(0.0, 1.0, x - 2.0));
}

float sdRoundRect(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + vec2(r);
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 c = 0.5 * uSize;
  vec2 p = frag - c;
  // Distance from the child's outline (rounded rect; a circle when uRadius
  // is at least half the child size).
  vec2 b = max(c - vec2(uSpread), vec2(1.0));
  float r = clamp(uRadius, 0.0, min(b.x, b.y));
  float d = sdRoundRect(p, b, r);

  float n = clamp(uRings, 1.0, 5.0);
  vec3 rgb = vec3(0.0);
  float a = 0.0;
  for (int i = 0; i < 5; i++) {
    float fi = float(i);
    float on = step(fi + 0.5, n);
    float ph = fract(uTime * 0.45 + fi / n);
    float rad = ph * uSpread;
    float w = 1.5 + 5.0 * ph;
    float x = (d - rad) / w;
    float ring = exp(-x * x * 2.0) * pow(1.0 - ph, 1.4) * on;
    float fill = 0.18 * (1.0 - smoothstep(0.0, rad + 0.001, d)) * pow(1.0 - ph, 2.0) * on;
    float k = ring + fill;
    rgb += cyc(fi / n + uTime * 0.08) * k;
    a += k;
  }
  float halo = 0.35 * exp(-max(d, 0.0) / max(uSpread * 0.22, 1.0)) * step(0.0, d);
  rgb += mix(cyc(uTime * 0.08), uC3.rgb, 0.3) * halo;
  a += halo;

  // Nothing is drawn under the child itself.
  float outside = smoothstep(-1.0, 0.5, d);
  a = clamp(a * uIntensity * outside, 0.0, 1.0);
  rgb = clamp(rgb * uIntensity * outside, vec3(0.0), vec3(a));
  fragColor = vec4(rgb, a);
}
