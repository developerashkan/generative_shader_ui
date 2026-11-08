// generative_shader_ui :: glowing gradient arc progress ring.
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
uniform float uSweep;
uniform float uStroke;
uniform float uRadius;
uniform float uGlow;
uniform vec4 uTrack;

out vec4 fragColor;

const float TAU = 6.2831853;

vec3 grad(float s) {
  float x = clamp(s, 0.0, 1.0) * 3.0;
  if (x < 1.0) return mix(uC0.rgb, uC1.rgb, x);
  if (x < 2.0) return mix(uC1.rgb, uC2.rgb, x - 1.0);
  return mix(uC2.rgb, uC3.rgb, x - 2.0);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = frag - 0.5 * uSize;
  float len = length(p);
  float hw = 0.5 * uStroke;
  float ringD = abs(len - uRadius) - hw;

  float a = fract(atan(p.y, p.x) / TAU + 0.25);
  float sweep = clamp(uSweep, 0.0, 1.0);
  float rel = fract(a - uStart);
  float a0 = uStart * TAU;
  float a1 = (uStart + sweep) * TAU;
  vec2 e0 = uRadius * vec2(sin(a0), -cos(a0));
  vec2 e1 = uRadius * vec2(sin(a1), -cos(a1));
  float l0 = length(p - e0);
  float l1 = length(p - e1);

  bool onArc = rel <= sweep;
  float arcD = onArc ? ringD : min(l0, l1) - hw;
  if (sweep >= 0.999) arcD = ringD;
  float visible = step(0.0005, sweep);
  float cov = (1.0 - smoothstep(-0.8, 0.8, arcD)) * visible;

  float s = onArc ? rel / max(sweep, 0.0001) : (l0 < l1 ? 0.0 : 1.0);
  vec3 col = grad(s);
  col += vec3(pow(0.5 + 0.5 * sin(rel * TAU * 2.0 - uTime * 3.0), 10.0) * 0.35);
  col += grad(1.0) * exp(-l1 / max(uStroke * 0.9, 1.0)) * 0.6 * visible;

  float glow = exp(-max(arcD, 0.0) / max(uGlow * 0.5, 0.5)) * 0.6 * visible * (1.0 - cov);
  float tcov = (1.0 - smoothstep(-0.8, 0.8, ringD)) * uTrack.a;

  vec3 rgb = uTrack.rgb * tcov;
  float alpha = tcov;
  rgb = rgb * (1.0 - cov) + clamp(col, 0.0, 1.0) * cov;
  alpha = alpha * (1.0 - cov) + cov;
  float gl = glow * (1.0 - alpha);
  rgb += clamp(grad(s), 0.0, 1.0) * gl;
  alpha += gl;
  fragColor = vec4(min(rgb, vec3(alpha)), alpha);
}
