// generative_shader_ui :: glossy shine that sweeps over a child, then rests.
// Composited with srcATop, so it only lights the child's own pixels.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uColor;
uniform float uAngle;
uniform float uWidth;
uniform float uPeriod;

out vec4 fragColor;

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 dir = vec2(cos(uAngle), sin(uAngle));
  float span = abs(dir.x) * uSize.x + abs(dir.y) * uSize.y + 1.0;
  vec2 c = 0.5 * uSize;
  float pos = dot(p - c, dir) / span + 0.5;

  float period = max(uPeriod, 0.3);
  float sweep = min(1.2, period);
  float t = mod(uTime, period) / sweep;
  float w = max(uWidth, 0.02);
  float head = mix(-w * 2.0, 1.0 + w * 2.0, t * t * (3.0 - 2.0 * t));
  float x = (pos - head) / w;

  // Bright core with a softer glossy skirt.
  float k = exp(-x * x * 3.0) + 0.35 * exp(-x * x * 0.6);
  k *= step(t, 1.0);
  float a = clamp(k * uColor.a, 0.0, 1.0);
  fragColor = vec4(uColor.rgb * a, a);
}
