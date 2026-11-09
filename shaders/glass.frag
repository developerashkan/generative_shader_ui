// generative_shader_ui :: liquid glass surface. Drawn over a blurred,
// saturated backdrop: tint, refraction-like rim light, pointer-driven
// specular highlight, iridescent edge, glossy sheen and fine grain.
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
uniform vec4 uTint;
uniform float uRim;
uniform float uIris;
uniform float uGrain;
uniform vec3 uTouch;

out vec4 fragColor;

float hash21(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

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
  vec2 b = max(c, vec2(1.0));
  float r = clamp(uRadius, 0.0, min(b.x, b.y));
  float d = sdRoundRect(p, b, r);
  float inside = 1.0 - smoothstep(-0.75, 0.75, d);

  // Outward "normal" of the rounded rect, used to light the rim.
  vec2 inner = b - vec2(r);
  vec2 q = p - clamp(p, -inner, inner);
  float ql = length(q);
  vec2 n = ql > 0.001 ? q / ql : normalize(p / b + vec2(0.0001));

  // Light comes from the top-left, or from the pointer while touching.
  vec2 tp = uTouch.xy * uSize - c;
  vec2 ldir = normalize(mix(vec2(-0.55, -0.85), normalize(tp + vec2(0.0001)), clamp(uTouch.z, 0.0, 1.0)));
  float facing = dot(n, ldir);

  float edge = exp(d / 5.0);
  float edgeWide = exp(d / 22.0);
  float line = 1.0 - smoothstep(0.0, 1.4, abs(d + 0.9));

  float spec = (pow(max(facing, 0.0), 3.0) * 0.9 + pow(max(-facing, 0.0), 3.0) * 0.35);
  float rim = uRim * (line * (0.25 + 0.75 * spec) + edge * 0.35 * spec + edgeWide * 0.07);

  float ang = atan(p.y, p.x) / 6.2831853;
  vec3 iris = cyc(ang + uTime * 0.05 + d * 0.004);
  float irisA = uIris * edgeWide * 0.35 * (0.6 + 0.4 * sin(uTime * 0.7 + ang * 12.0));

  // Glossy sheen across the top and a faint caustic following the pointer.
  vec2 uv = frag / uSize;
  float sheen = 0.10 * smoothstep(0.55, 0.0, uv.y) * smoothstep(0.0, 0.25, uv.y + 0.05);
  sheen *= 0.7 + 0.3 * sin(uTime * 0.6 + uv.x * 3.0);
  vec2 tv = frag - uTouch.xy * uSize;
  float caustic = uTouch.z * 0.22 * exp(-dot(tv, tv) / (0.03 * dot(uSize, uSize) + 1.0));
  float shade = 0.08 * smoothstep(0.55, 1.0, uv.y);

  float grain = (hash21(floor(frag) + floor(uTime * 24.0)) - 0.5) * uGrain;

  vec3 light = vec3(1.0);
  float ta = uTint.a;
  vec3 rgb = uTint.rgb * ta;
  float a = ta;
  float la = clamp(rim + sheen + caustic, 0.0, 1.0);
  rgb = rgb * (1.0 - la) + light * la;
  a = a + la * (1.0 - a);
  rgb = rgb + iris * irisA;
  a = a + irisA * (1.0 - a);
  rgb = rgb * (1.0 - shade);
  a = a + shade * (1.0 - a);
  rgb = rgb + vec3(grain) * a;

  a = clamp(a, 0.0, 1.0) * inside;
  rgb = clamp(rgb * inside, vec3(0.0), vec3(a));
  fragColor = vec4(rgb, a);
}
