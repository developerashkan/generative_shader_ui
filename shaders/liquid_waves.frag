// generative_shader_ui :: layered liquid waves with foam highlights. Rises to
// uLevel, sloshes under the pointer. Transparent above the liquid.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform float uLevel;
uniform float uAmp;
uniform float uBubbles;
uniform vec3 uTouch;

out vec4 fragColor;

float hash21(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 layerColor(float fi) {
  if (fi < 0.5) return uC0.rgb;
  if (fi < 1.5) return uC1.rgb;
  if (fi < 2.5) return uC2.rgb;
  return uC3.rgb;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float t = uTime;
  float aspect = uSize.x / max(uSize.y, 1.0);
  float x = uv.x * aspect;
  float amp = uAmp * 0.06;

  vec3 rgb = vec3(0.0);
  float a = 0.0;
  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    float sp = 0.6 + fi * 0.25;
    float dir = mod(fi, 2.0) < 0.5 ? 1.0 : -1.0;
    float surface = 1.0 - uLevel - 0.035 * fi;
    surface += amp * (sin(x * (3.2 + fi * 0.9) + t * sp * dir + fi * 1.7)
        + 0.55 * sin(x * (7.1 - fi * 0.8) - t * sp * 1.3 * dir + fi * 4.1)
        + 0.25 * sin(x * 13.0 + t * 2.1 + fi));
    float dx = uv.x - uTouch.x;
    surface -= uTouch.z * amp * 1.8 * exp(-dx * dx * 40.0) * cos(dx * 30.0 - t * 6.0);

    float dist = (uv.y - surface) * uSize.y;
    float body = smoothstep(-0.8, 0.8, dist);
    float foam = exp(-abs(dist) / 1.6) * (0.55 - fi * 0.08);
    float depth = clamp((uv.y - surface) / max(1.0 - surface, 0.05), 0.0, 1.0);
    vec3 c = mix(layerColor(fi), layerColor(fi) * 0.55 + uC3.rgb * 0.35, depth * 0.8);
    float la = body * (0.42 + 0.14 * fi);
    rgb = rgb * (1.0 - la) + c * la;
    a = a + la * (1.0 - a);
    float fa = foam * smoothstep(-3.0, 3.0, dist + 3.0);
    rgb = rgb + vec3(1.0) * fa * (1.0 - a * 0.5);
    a = a + fa * (1.0 - a);
  }

  // Rising bubbles inside the liquid.
  float cell = 34.0;
  vec2 q = frag + vec2(0.0, t * 38.0);
  vec2 id = floor(q / cell);
  vec2 f = q / cell - id;
  float h = hash21(id);
  vec2 ctr = vec2(0.3 + 0.4 * hash21(id + 2.0) + 0.08 * sin(t * 2.0 + h * 6.0), 0.5);
  float br = (1.5 + 2.5 * hash21(id + 5.0));
  float bd = length((f - ctr) * cell);
  float bubble = (1.0 - smoothstep(br - 1.0, br, bd)) * (0.35 + 0.65 * smoothstep(br - 1.6, br, bd));
  float surface0 = 1.0 - uLevel;
  bubble *= step(h, 0.22 * uBubbles) * smoothstep(surface0 + 0.02, surface0 + 0.12, uv.y) * a;
  rgb += vec3(1.0) * bubble * 0.5;

  a = clamp(a, 0.0, 1.0);
  fragColor = vec4(clamp(rgb, vec3(0.0), vec3(a)), a);
}
