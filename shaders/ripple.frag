// generative_shader_ui :: up to four simultaneous glowing touch ripples.
// Each uR* is (x px, y px, progress 0..1, strength); strength 0 = unused.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform vec4 uR0;
uniform vec4 uR1;
uniform vec4 uR2;
uniform vec4 uR3;
uniform float uIntensity;

out vec4 fragColor;

vec3 cyc(float s) {
  float x = fract(s) * 3.0;
  if (x < 1.0) return mix(uC0.rgb, uC1.rgb, smoothstep(0.0, 1.0, x));
  if (x < 2.0) return mix(uC1.rgb, uC2.rgb, smoothstep(0.0, 1.0, x - 1.0));
  return mix(uC2.rgb, uC0.rgb, smoothstep(0.0, 1.0, x - 2.0));
}

vec4 ripple(vec2 p, vec4 r, float maxR) {
  if (r.w <= 0.0) return vec4(0.0);
  float prog = clamp(r.z, 0.0, 1.0);
  float ease = 1.0 - pow(1.0 - prog, 3.0);
  float rad = ease * maxR;
  vec2 v = p - r.xy;
  float d = length(v);
  float fade = pow(1.0 - prog, 1.6) * r.w;
  float w = 6.0 + 26.0 * prog;
  float x = (d - rad) / w;
  float ring = exp(-x * x * 2.5);
  float trail = 0.35 * exp(-pow((d - rad * 0.72) / (w * 0.8), 2.0) * 2.5);
  float flash = 0.5 * exp(-d * d / (900.0 + 4000.0 * prog)) * pow(1.0 - prog, 4.0);
  float a = (ring + trail + flash) * fade;
  vec3 c = cyc(atan(v.y, v.x) / 6.2831853 + prog * 0.6 + uTime * 0.05);
  c = mix(c, uC3.rgb, trail / max(ring + trail + flash, 0.001) * 0.5);
  c = mix(c, vec3(1.0), ring * 0.35);
  return vec4(c * a, a);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  float maxR = length(uSize) * 0.85;
  vec4 acc = ripple(p, uR0, maxR) + ripple(p, uR1, maxR) + ripple(p, uR2, maxR) + ripple(p, uR3, maxR);
  float a = clamp(acc.a * uIntensity, 0.0, 1.0);
  vec3 rgb = clamp(acc.rgb * uIntensity, vec3(0.0), vec3(a));
  fragColor = vec4(rgb, a);
}
