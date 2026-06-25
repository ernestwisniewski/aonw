#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 u_size;
uniform float u_time;
uniform sampler2D u_mask;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float sampleFog(vec2 uv) {
  return texture(u_mask, clamp(uv, 0.0, 1.0)).r;
}

float blurredFog(vec2 uv) {
  vec2 texel = vec2(2.9) / max(u_size, vec2(1.0));
  vec2 wideTexel = texel * 2.0;
  float fog = sampleFog(uv) * 0.24;

  fog += sampleFog(uv + vec2(texel.x, 0.0)) * 0.1;
  fog += sampleFog(uv - vec2(texel.x, 0.0)) * 0.1;
  fog += sampleFog(uv + vec2(0.0, texel.y)) * 0.1;
  fog += sampleFog(uv - vec2(0.0, texel.y)) * 0.1;

  fog += sampleFog(uv + texel) * 0.055;
  fog += sampleFog(uv - texel) * 0.055;
  fog += sampleFog(uv + vec2(texel.x, -texel.y)) * 0.055;
  fog += sampleFog(uv + vec2(-texel.x, texel.y)) * 0.055;

  fog += sampleFog(uv + vec2(wideTexel.x, 0.0)) * 0.035;
  fog += sampleFog(uv - vec2(wideTexel.x, 0.0)) * 0.035;
  fog += sampleFog(uv + vec2(0.0, wideTexel.y)) * 0.035;
  fog += sampleFog(uv - vec2(0.0, wideTexel.y)) * 0.035;

  return fog;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float fog = blurredFog(uv);

  if (fog <= 0.01) {
    fragColor = vec4(0.0);
    return;
  }

  float low = noise(uv * 7.0 + vec2(u_time * 0.025, -u_time * 0.015));
  float high = noise(uv * 26.0 + vec2(-u_time * 0.055, u_time * 0.035));
  float mist = low * 0.65 + high * 0.35;
  float breathe = 0.94 + 0.06 * sin(u_time * 1.15 + mist * 6.2831853);

  vec3 memoryColor = vec3(0.050, 0.055, 0.070);
  vec3 hiddenColor = vec3(0.0);
  vec3 color = mix(memoryColor, hiddenColor, smoothstep(0.62, 0.97, fog));

  float fogPresence = smoothstep(0.015, 0.24, fog);
  float hiddenCore = smoothstep(0.94, 0.995, fog);
  float edgeVariation = (mist - 0.5) * 0.075 * fogPresence;
  float alpha = clamp(fog * breathe + edgeVariation, 0.0, 1.0);
  alpha = mix(alpha, 1.0, hiddenCore);
  fragColor = vec4(color * alpha, alpha);
}
