// generative_shader_ui :: animated 4-point mesh gradient with domain warp,
// touch push and film grain.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform float uWarp;
uniform float uScale;
uniform float uGrain;
uniform vec3 uTouch;

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

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * vnoise(p);
    p = p * 2.02 + vec2(3.1, 1.7);
    a *= 0.5;
  }
  return v;
}

float weight(vec2 uv, vec2 c, float aspect) {
  vec2 d = (uv - c) * vec2(aspect, 1.0);
  float d2 = dot(d, d);
  return 1.0 / (d2 * sqrt(d2) + 0.0006);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / max(uSize.y, 1.0);
  float t = uTime * 0.25;

  vec2 np = uv * vec2(aspect, 1.0) * uScale;
  vec2 warp = vec2(fbm(np + vec2(t, -t * 0.7)),
                   fbm(np + vec2(-t * 0.6, t) + 7.3)) - 0.5;
  vec2 w = uv + warp * uWarp * 0.5;

  vec2 td = (uv - uTouch.xy) * vec2(aspect, 1.0);
  float infl = uTouch.z * exp(-dot(td, td) * 9.0);
  w += normalize(td + vec2(0.0001)) * infl * 0.08;

  vec2 c0 = vec2(0.20 + 0.18 * sin(t * 1.30), 0.22 + 0.16 * cos(t * 1.10));
  vec2 c1 = vec2(0.82 + 0.15 * cos(t * 0.90), 0.18 + 0.18 * sin(t * 1.70));
  vec2 c2 = vec2(0.22 + 0.17 * cos(t * 1.50), 0.80 + 0.15 * sin(t * 0.80));
  vec2 c3 = vec2(0.78 + 0.16 * sin(t * 1.20), 0.82 + 0.14 * cos(t * 1.40));

  float w0 = weight(w, c0, aspect);
  float w1 = weight(w, c1, aspect);
  float w2 = weight(w, c2, aspect);
  float w3 = weight(w, c3, aspect);
  vec4 col = (uC0 * w0 + uC1 * w1 + uC2 * w2 + uC3 * w3) / (w0 + w1 + w2 + w3);

  col.rgb += infl * 0.18;
  float g = (hash21(frag + fract(uTime) * 91.7) - 0.5) * uGrain * 0.12;
  col.rgb = clamp(col.rgb + g, 0.0, 1.0);
  col.a = clamp(col.a, 0.0, 1.0);
  fragColor = vec4(col.rgb * col.a, col.a);
}
