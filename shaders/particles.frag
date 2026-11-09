// generative_shader_ui :: procedural particle field. One draw, no particle
// buffers: every particle lives in its own grid cell and is animated
// analytically. Styles: 0 snow, 1 embers, 2 fireflies, 3 bokeh, 4 rain,
// 5 confetti, 6 warp (hyperspace stars).
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform vec4 uC3;
uniform float uStyle;
uniform float uDensity;
uniform float uScale;
uniform float uOpacity;
uniform vec3 uTouch;

out vec4 fragColor;

float hash21(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

// Fades a particle's glow out before the edge of its grid cell, so halos are
// never cut off into visible squares.
float cellFade(vec2 f, float w) {
  vec2 e = min(f, 1.0 - f);
  return smoothstep(0.0, w, min(e.x, e.y));
}

vec3 pick(float h) {
  if (h < 0.34) return uC0.rgb;
  if (h < 0.67) return uC1.rgb;
  return uC2.rgb;
}

vec3 pick4(float h) {
  if (h < 0.25) return uC0.rgb;
  if (h < 0.5) return uC1.rgb;
  if (h < 0.75) return uC2.rgb;
  return uC3.rgb;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  float t = uTime;
  float sc = max(uScale, 0.2);
  float dens = clamp(uDensity, 0.0, 1.0);
  vec3 col = vec3(0.0);
  float alpha = 0.0;

  if (uStyle < 0.5) {
    // Snow: three parallax layers drifting down with a gentle sway.
    for (int i = 0; i < 3; i++) {
      float fi = float(i);
      float depth = 1.0 - fi * 0.3;
      float cell = (64.0 - fi * 14.0) * sc;
      vec2 q = p;
      q.y -= t * (52.0 - fi * 14.0) * sc;
      q.x += sin(t * 0.35 + fi * 1.7) * 18.0 * depth;
      vec2 id = floor(q / cell);
      vec2 f = q / cell - id;
      float h = hash21(id + fi * 17.31);
      vec2 ctr = 0.25 + 0.5 * vec2(hash21(id + 3.7 + fi), hash21(id + 9.1 + fi));
      ctr.x += 0.12 * sin(t * (0.8 + h) + h * 6.2831);
      float rad = (1.1 + 2.4 * hash21(id + 5.3)) * depth * sc;
      float dd = length((f - ctr) * cell);
      float a = (1.0 - smoothstep(rad * 0.45, rad, dd)) + 0.35 * exp(-dd * dd / (rad * rad * 5.0));
      a *= step(h, dens) * (0.55 + 0.45 * depth) * cellFade(f, 0.1);
      col += mix(vec3(1.0), uC1.rgb, 0.25 * fi) * a;
      alpha += a;
    }
  } else if (uStyle < 1.5) {
    // Embers: hot sparks rising, flickering and fading towards the top.
    for (int i = 0; i < 3; i++) {
      float fi = float(i);
      float cell = (58.0 - fi * 12.0) * sc;
      vec2 q = p;
      q.y += t * (70.0 - fi * 16.0) * sc;
      vec2 id = floor(q / cell);
      q.x += sin(t * 1.3 + id.y * 0.7 + fi) * 10.0;
      id = floor(q / cell);
      vec2 f = q / cell - id;
      float h = hash21(id + fi * 23.7);
      vec2 ctr = 0.3 + 0.4 * vec2(hash21(id + 1.3 + fi), hash21(id + 4.9 + fi));
      ctr.x += 0.1 * sin(t * (2.0 + 2.0 * h) + h * 9.0);
      float rad = (0.9 + 1.8 * hash21(id + 8.2)) * sc;
      vec2 dv = (f - ctr) * cell;
      dv.y *= 0.55;
      float dd = length(dv);
      float flick = 0.55 + 0.45 * sin(t * (7.0 + 9.0 * h) + h * 40.0);
      float a = (1.0 - smoothstep(rad * 0.3, rad, dd)) + 0.6 * exp(-dd * dd / (rad * rad * 9.0));
      a *= flick * step(h, dens) * smoothstep(0.0, 0.55, p.y / uSize.y) * cellFade(f, 0.18);
      col += mix(pick(hash21(id + 2.2)), vec3(1.0, 0.95, 0.8), 0.25) * a;
      alpha += a * 0.85;
    }
  } else if (uStyle < 2.5) {
    // Fireflies: wandering glows that slowly blink on and off.
    for (int i = 0; i < 2; i++) {
      float fi = float(i);
      float cell = (78.0 - fi * 22.0) * sc;
      vec2 q = p + fi * 37.0;
      vec2 id = floor(q / cell);
      vec2 f = q / cell - id;
      float h = hash21(id + fi * 11.1);
      float h2 = hash21(id + 6.6 + fi);
      vec2 ctr = 0.5 + 0.3 * vec2(sin(t * (0.3 + 0.4 * h) + h * 6.2831), cos(t * (0.25 + 0.35 * h2) + h2 * 6.2831));
      float dd = length((f - ctr) * cell);
      float blink = pow(0.5 + 0.5 * sin(t * (0.9 + h) + h * 30.0), 2.0);
      float core = 1.0 - smoothstep(1.0 * sc, 2.4 * sc, dd);
      float halo = exp(-dd * dd / (110.0 * sc * sc));
      float a = (core + 0.7 * halo) * blink * step(h, dens) * cellFade(f, 0.18);
      col += mix(pick(h2), vec3(1.0), 0.3 * core) * a;
      alpha += a * 0.9;
    }
  } else if (uStyle < 3.5) {
    // Bokeh: large soft discs drifting upwards, out of focus.
    for (int i = 0; i < 2; i++) {
      float fi = float(i);
      float cell = (170.0 - fi * 50.0) * sc;
      vec2 q = p;
      q.y += t * (9.0 + fi * 7.0) * sc;
      q.x += sin(t * 0.2 + fi * 2.0) * 14.0;
      vec2 id = floor(q / cell);
      vec2 f = q / cell - id;
      float h = hash21(id + fi * 31.3);
      vec2 ctr = 0.32 + 0.36 * vec2(hash21(id + 2.1 + fi), hash21(id + 7.4 + fi));
      float rad = cell * (0.11 + 0.12 * hash21(id + 5.5));
      float dd = length((f - ctr) * cell);
      float disc = 1.0 - smoothstep(rad - 2.5, rad, dd);
      float ring = (1.0 - smoothstep(0.0, 2.0, abs(dd - rad + 2.0))) * 0.5;
      float breathe = 0.65 + 0.35 * sin(t * (0.5 + h) + h * 12.0);
      float a = (disc * 0.16 + ring * 0.18 + 0.06 * exp(-dd * dd / (rad * rad * 0.5))) * breathe * step(h, dens) * cellFade(f, 0.07);
      col += pick(hash21(id + 9.9)) * a;
      alpha += a;
    }
  } else if (uStyle < 4.5) {
    // Rain: slanted streaks falling fast.
    for (int i = 0; i < 3; i++) {
      float fi = float(i);
      vec2 cell = vec2(18.0 + fi * 6.0, 140.0 - fi * 25.0) * sc;
      vec2 q = p;
      q.x += q.y * 0.18;
      q.y -= t * (820.0 - fi * 190.0) * sc;
      vec2 id = floor(q / cell);
      vec2 f = q / cell - id;
      float h = hash21(id + fi * 13.7);
      vec2 ctr = vec2(0.3 + 0.4 * hash21(id + 4.4), 0.5);
      vec2 dv = (f - ctr) * cell;
      float len = (14.0 + 22.0 * hash21(id + 1.9)) * sc * (1.0 - fi * 0.2);
      float a = (1.0 - smoothstep(0.35, 1.1, abs(dv.x))) * (1.0 - smoothstep(len * 0.3, len, abs(dv.y)));
      a *= step(h, dens) * (0.6 - fi * 0.15);
      col += mix(uC0.rgb, vec3(1.0), 0.5) * a;
      alpha += a;
    }
  } else if (uStyle < 5.5) {
    // Confetti: tumbling paper pieces in palette colors.
    for (int i = 0; i < 2; i++) {
      float fi = float(i);
      float cell = (54.0 - fi * 12.0) * sc;
      vec2 q = p;
      q.y -= t * (85.0 - fi * 25.0) * sc;
      vec2 id = floor(q / cell);
      q.x += sin(t * 1.4 + id.y * 1.3 + fi) * 8.0;
      id = floor(q / cell);
      vec2 f = q / cell - id;
      float h = hash21(id + fi * 19.9);
      vec2 ctr = 0.3 + 0.4 * vec2(hash21(id + 3.3 + fi), hash21(id + 6.1 + fi));
      vec2 dv = (f - ctr) * cell;
      float ang = t * (1.5 + 3.0 * h) + h * 6.2831;
      float cs = cos(ang);
      float sn = sin(ang);
      dv = vec2(cs * dv.x - sn * dv.y, sn * dv.x + cs * dv.y);
      float flip = abs(cos(t * (2.0 + 3.0 * hash21(id + 2.7)) + h * 5.0));
      vec2 hs = vec2(5.0 * max(flip, 0.12), 2.6) * sc * (1.0 - fi * 0.2);
      vec2 qd = abs(dv) - hs;
      float sd = length(max(qd, 0.0)) + min(max(qd.x, qd.y), 0.0);
      float a = (1.0 - smoothstep(-0.6, 0.6, sd)) * step(h, dens);
      col += pick4(hash21(id + 8.8)) * (0.75 + 0.25 * flip) * a;
      alpha += a;
    }
  } else {
    // Warp: stars streaking out of the centre (or the pointer).
    vec2 center = mix(0.5 * uSize, uTouch.xy * uSize, clamp(uTouch.z, 0.0, 1.0) * 0.6);
    vec2 v = p - center;
    float r = length(v);
    float maxR = length(uSize) * 0.6;
    float ang = atan(v.y, v.x) / 6.2831853 + 0.5;
    for (int i = 0; i < 3; i++) {
      float fi = float(i);
      float n = 70.0 + fi * 45.0;
      float a0 = ang * n;
      float sid = floor(a0);
      float fa = fract(a0);
      float h = hash21(vec2(sid, fi * 7.0));
      float rho = fract(h * 13.7 + t * (0.18 + 0.22 * hash21(vec2(sid, fi + 3.0))) * sc);
      float rr = rho * rho * maxR;
      float len = (2.0 + rho * rho * 90.0) * sc;
      float across = (fa - 0.5) * r * 6.2831853 / n;
      float dr = r - rr;
      float a = (1.0 - smoothstep(0.4, 1.3 + rho, abs(across)));
      a *= smoothstep(-len, 0.0, dr) * (1.0 - smoothstep(0.0, 1.5, dr));
      a *= rho * 1.6 * step(h, dens);
      col += mix(vec3(1.0), pick(hash21(vec2(sid, fi))), 0.5) * a;
      alpha += a;
    }
  }

  // The pointer brightens nearby particles.
  vec2 tv = p - uTouch.xy * uSize;
  float boost = 1.0 + uTouch.z * 1.4 * exp(-dot(tv, tv) / (0.02 * dot(uSize, uSize) + 1.0));
  float a = clamp(alpha * boost, 0.0, 1.0) * uOpacity;
  vec3 rgb = clamp(col * boost * uOpacity, vec3(0.0), vec3(a));
  fragColor = vec4(rgb, a);
}
