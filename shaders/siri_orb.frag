// generative_shader_ui :: Siri-style fluid orb, audio and touch reactive.
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
uniform float uGlow;
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

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float m = 0.5 * min(uSize.x, uSize.y);
  vec2 p = (frag - 0.5 * uSize) / m;
  vec2 tp = (uTouch.xy * uSize - 0.5 * uSize) / m;
  float amp = clamp(uAmp, 0.0, 1.5);
  float t = uTime;

  float R = 0.64 * (1.0 + 0.10 * amp);
  float len = length(p);
  float ang = atan(p.y, p.x);
  float wob = (fbm(vec2(cos(ang), sin(ang)) * 1.3 + vec2(t * 0.35, -t * 0.27)) - 0.5)
      * (0.05 + 0.16 * amp);
  float edge = R * (1.0 + wob);
  float px = 1.5 / m;
  float inside = 1.0 - smoothstep(edge - px, edge + px, len);

  vec2 q = p / R;
  float speed = 1.0 + amp * 1.5;
  vec3 col = uC3.rgb * 0.45;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float a = t * (0.45 + 0.17 * fi) * speed + fi * 2.0944;
    vec2 c = vec2(cos(a), sin(a * 1.21 + fi)) * (0.38 + 0.08 * sin(t * 0.7 + fi));
    vec2 d = q - c;
    float n = fbm(q * 2.2 + vec2(fi * 3.7 + t * 0.25, -t * 0.2));
    float blob = exp(-dot(d, d) / (0.16 + 0.22 * n + 0.10 * amp));
    vec3 cc = (i == 0) ? uC0.rgb : ((i == 1) ? uC1.rgb : uC2.rgb);
    col = col + cc * blob * (vec3(0.85) - col * 0.45);
  }

  float rib = sin(ang * 3.0 + len * 6.0 - t * 1.6 * speed + fbm(q * 3.0 + t * 0.3) * 4.0);
  col += mix(uC0.rgb, uC2.rgb, 0.5 + 0.5 * sin(t)) * smoothstep(0.75, 1.0, rib)
      * 0.25 * (0.6 + amp);

  float rim = smoothstep(0.55, 1.0, len / edge);
  col += mix(uC1.rgb, uC0.rgb, 0.5 + 0.5 * sin(ang + t)) * rim * 0.55;

  vec2 sc = mix(vec2(-0.32, -0.38), tp / R, clamp(uTouch.z, 0.0, 1.0) * 0.5);
  vec2 sp = q - sc;
  col += vec3(exp(-dot(sp, sp) * 14.0) * 0.22);
  col = clamp(col, 0.0, 1.0);

  float outside = max(len - edge, 0.0);
  vec3 gcol = mix(mix(uC0.rgb, uC1.rgb, 0.5 + 0.5 * sin(ang + t * 0.8)), uC2.rgb,
                  0.5 + 0.5 * cos(ang * 2.0 - t * 0.6));
  float glow = exp(-outside * (7.0 - 3.0 * min(amp, 1.0))) * uGlow * (0.45 + 0.4 * amp);
  glow *= (1.0 - smoothstep(0.82, 1.0, len)) * (1.0 - inside);
  glow = clamp(glow, 0.0, 1.0);

  vec3 rgb = col * inside + clamp(gcol, 0.0, 1.0) * glow;
  float alpha = clamp(inside + glow, 0.0, 1.0);
  fragColor = vec4(min(rgb, vec3(alpha)), alpha);
}
