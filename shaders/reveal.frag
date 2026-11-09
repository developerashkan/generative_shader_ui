// generative_shader_ui :: reveal transitions. uMode 0 outputs the reveal
// mask (used with BlendMode.dstIn), uMode 1 the glowing edge drawn on top.
// Styles: 0 dissolve, 1 burn, 2 iris (circle), 3 wipe, 4 pixels, 5 liquid.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform float uProgress;
uniform float uStyle;
uniform vec2 uOrigin;
uniform float uEdge;
uniform float uMode;

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
    p = p * 2.03 + vec2(17.1, 9.2);
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / max(uSize.y, 1.0);
  vec2 o = uOrigin;

  // Threshold field f in 0..1: the order in which pixels appear.
  float f;
  if (uStyle < 1.5) {
    float n = fbm(frag / 70.0 + vec2(uTime * 0.05, 0.0));
    f = clamp((n - 0.2) / 0.6, 0.0, 1.0);
  } else if (uStyle < 2.5) {
    vec2 v = (uv - o) * vec2(aspect, 1.0);
    vec2 far = max(o, 1.0 - o) * vec2(aspect, 1.0);
    f = length(v) / max(length(far), 0.001);
    f += (vnoise(vec2(atan(v.y, v.x) * 3.0, uTime * 0.6)) - 0.5) * 0.05;
  } else if (uStyle < 3.5) {
    vec2 dv = vec2(0.5) - o;
    vec2 dir = length(dv) < 0.001 ? vec2(1.0, 0.0) : normalize(dv);
    float lo = min(dir.x, 0.0) + min(dir.y, 0.0);
    float hi = max(dir.x, 0.0) + max(dir.y, 0.0);
    f = (dot(uv, dir) - lo) / max(hi - lo, 0.001);
    f = f + (vnoise(frag / 40.0) - 0.5) * 0.04;
  } else if (uStyle < 4.5) {
    float cells = 14.0;
    vec2 id = floor(uv * vec2(cells * aspect, cells));
    float diag = dot((id + 0.5) / vec2(cells * aspect, cells), vec2(0.5));
    f = mix(hash21(id), diag, 0.55);
  } else {
    float n = fbm(frag / 120.0 + vec2(0.0, uTime * 0.1));
    float wave = sin(uv.x * 9.0 + uTime * 2.0) * 0.03;
    f = (1.0 - uv.y) * 0.75 + n * 0.25 + wave;
  }
  f = clamp(f, 0.0, 1.0);

  float e = max(uEdge, 0.001);
  float P = uProgress * (1.0 + 2.0 * e) - e;
  float soft = uStyle > 3.5 && uStyle < 4.5 ? 0.004 : 0.012;
  float vis = smoothstep(f - soft, f + soft, P);

  if (uMode < 0.5) {
    fragColor = vec4(vis);
    return;
  }

  // Glowing edge just outside the revealed region.
  float dd = f - P;
  float g = (1.0 - smoothstep(0.0, e, abs(dd))) * (1.0 - vis * 0.6);
  float hot = 1.0 - smoothstep(0.0, e * 0.35, abs(dd));
  vec3 col = mix(uC1.rgb, uC0.rgb, clamp(1.0 - abs(dd) / e, 0.0, 1.0));
  col = mix(col, uC2.rgb, 0.25 + 0.25 * sin(f * 30.0 + uTime * 3.0));
  if (uStyle > 0.5 && uStyle < 1.5) {
    // Burn: charred rim behind a white-hot edge.
    col = mix(col, vec3(1.0, 0.95, 0.85), hot * 0.6);
    float scorch = (1.0 - smoothstep(0.0, e * 1.6, dd)) * step(0.0, dd) * 0.6;
    float a = clamp(g + scorch * (1.0 - g), 0.0, 1.0);
    vec3 rgb = col * g + uC3.rgb * 0.25 * scorch * (1.0 - g);
    fragColor = vec4(min(rgb, vec3(a)), a);
    return;
  }
  col = mix(col, vec3(1.0), hot * 0.35);
  float a = clamp(g * 0.9, 0.0, 1.0);
  fragColor = vec4(min(col * a, vec3(a)), a);
}
