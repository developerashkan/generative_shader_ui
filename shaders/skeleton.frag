// generative_shader_ui :: skeleton loader fill. The widget clips this to the
// bone shapes; the sweep runs in screen space so every skeleton on screen
// shimmers in sync.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec2 uOrigin;
uniform vec2 uView;
uniform vec4 uBase;
uniform vec4 uHigh;
uniform vec4 uAccent;
uniform float uMode;
uniform float uAngle;
uniform float uBand;
uniform float uOpacity;

out vec4 fragColor;

float hash21(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash21(i);
  float b = hash21(i + vec2(1.0, 0.0));
  float c = hash21(i + vec2(0.0, 1.0));
  float d = hash21(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void main() {
  vec2 local = min(FlutterFragCoord().xy, uSize);
  vec2 g = local + uOrigin;
  vec2 dir = vec2(cos(uAngle), sin(uAngle));
  float span = abs(dir.x) * uView.x + abs(dir.y) * uView.y + 1.0;
  float pos = dot(g, dir) / span;
  float band = max(uBand, 0.02);

  vec4 col = uBase;
  if (uMode < 0.5) {
    // Shimmer: a soft diagonal band sweeps across the whole screen.
    float t = fract(uTime * 0.55);
    float c = mix(-band * 1.5, 1.0 + band * 1.5, t);
    float x = (pos - c) / band;
    float k = exp(-x * x * 2.2);
    col = mix(uBase, uHigh, k);
  } else if (uMode < 1.5) {
    // Pulse: everything breathes together.
    float k = 0.5 + 0.5 * sin(uTime * 3.1 - pos * 1.5);
    col = mix(uBase, uHigh, k * k * (3.0 - 2.0 * k));
  } else {
    // Glow: an accent tinted sheen with slow liquid noise.
    float t = fract(uTime * 0.4);
    float c = mix(-band * 2.0, 1.0 + band * 2.0, t);
    float x = (pos - c) / (band * 1.6);
    float k = exp(-x * x * 1.6);
    float n = vnoise(g / 90.0 + vec2(uTime * 0.25, -uTime * 0.18));
    vec4 lit = mix(uHigh, uAccent, 0.55 + 0.45 * n);
    col = mix(uBase, lit, k * 0.9 + n * 0.12);
  }

  float a = clamp(col.a * uOpacity, 0.0, 1.0);
  fragColor = vec4(col.rgb * a, a);
}
