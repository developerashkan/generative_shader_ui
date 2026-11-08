// generative_shader_ui :: northern-lights curtains over a starry sky.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform vec4 uBase;
uniform float uStars;
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
  vec2 uv = frag / uSize;
  float aspect = uSize.x / max(uSize.y, 1.0);
  float t = uTime * 0.3;

  vec3 col = mix(uBase.rgb * 1.35, uBase.rgb * 0.65, uv.y);

  vec2 cell = floor(frag / 2.0);
  float h = hash21(cell);
  float star = step(1.0 - 0.0022 * uStars, h) * (0.55 + 0.45 * sin(uTime * 2.0 + h * 100.0));
  col += vec3(star * 0.85 * (1.0 - uv.y * 0.7));

  vec2 td = (uv - uTouch.xy) * vec2(aspect, 1.0);
  float boost = 1.0 + uTouch.z * 1.4 * exp(-dot(td, td) * 6.0);

  float x = uv.x * aspect;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float center = 0.30 + fi * 0.13
        + 0.07 * sin(x * 1.7 + t * (1.0 + fi * 0.4) + fi * 2.0)
        + 0.12 * (fbm(vec2(x * 1.2 + t * 0.4 + fi * 5.0, t * 0.2)) - 0.5);
    float dy = uv.y - center;
    float rays = 0.35 + 0.9 * fbm(vec2(x * 14.0 + fi * 9.0 + t * 0.6, uv.y * 1.5 - t * 0.8));
    float curtain = dy < 0.0 ? exp(dy * 7.0) : exp(-dy * dy * 900.0);
    vec3 cc = (i == 0) ? uC0.rgb : ((i == 1) ? uC1.rgb : uC2.rgb);
    col += cc * curtain * rays * 0.55 * boost;
  }
  col += uC3.rgb * smoothstep(0.55, 1.0, uv.y) * 0.35;

  col = clamp(col, 0.0, 1.0);
  float a = clamp(uBase.a, 0.0, 1.0);
  fragColor = vec4(col * a, a);
}
