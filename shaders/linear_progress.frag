// generative_shader_ui :: liquid neon linear progress bar.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform float uStart;
uniform float uEnd;
uniform float uRadius;
uniform float uGlow;
uniform float uInset;
uniform vec4 uTrack;

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
  vec2 b = max(c - vec2(uInset), vec2(0.5));
  float r = clamp(uRadius, 0.0, min(b.x, b.y));
  float trackD = sdRoundRect(p, b, r);

  float s0 = clamp(min(uStart, uEnd), 0.0, 1.0);
  float s1 = clamp(max(uStart, uEnd), 0.0, 1.0);
  float x0 = -b.x + 2.0 * b.x * s0;
  float x1 = -b.x + 2.0 * b.x * s1;
  vec2 sb = vec2(max(0.5 * (x1 - x0), 0.0), b.y);
  float segD = sdRoundRect(p - vec2(0.5 * (x0 + x1), 0.0), sb, min(r, sb.x));
  segD = max(segD, trackD);
  float visible = step(0.0005, s1 - s0);

  float u = (frag.x - uInset) / max(2.0 * b.x, 1.0);
  float v = (frag.y - uInset) / max(2.0 * b.y, 1.0);
  float n = vnoise(vec2(u * 6.0 - uTime * 0.8, v * 2.0 + uTime * 0.3));
  vec3 col = cyc(u * 0.9 - uTime * 0.35 + n * 0.25);
  col += vec3(pow(0.5 + 0.5 * sin(u * 9.0 - uTime * 5.0), 14.0) * 0.4);
  col += vec3(0.18) * (1.0 - smoothstep(0.0, 0.55, v));

  float cov = (1.0 - smoothstep(-0.8, 0.8, segD)) * visible;
  float tcov = (1.0 - smoothstep(-0.8, 0.8, trackD)) * uTrack.a;
  float glow = exp(-max(segD, 0.0) / max(uGlow * 0.45, 0.5)) * 0.65 * visible;
  glow *= 1.0 - smoothstep(uInset * 0.7, uInset + 0.001, trackD);

  vec3 rgb = uTrack.rgb * tcov;
  float alpha = tcov;
  rgb = rgb * (1.0 - cov) + clamp(col, 0.0, 1.0) * cov;
  alpha = alpha * (1.0 - cov) + cov;
  float gl = glow * (1.0 - alpha);
  rgb += clamp(cyc(u * 0.9 - uTime * 0.35), 0.0, 1.0) * gl;
  alpha += gl;
  fragColor = vec4(min(rgb, vec3(alpha)), alpha);
}
