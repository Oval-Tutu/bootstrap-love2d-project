// WebGL compatibility: only define precision when running on OpenGL ES/WebGL
#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 eyeCenter;
uniform vec2 highlightCenter;
uniform float eyeSize;
uniform vec4 brightColor;
uniform vec4 shadedColor;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  // Calculate distance from center as a percentage of eye size
  float dist = distance(screen_coords, eyeCenter) / eyeSize;

  // Calculate position relative to highlight
  vec2 toHighlight = normalize(highlightCenter - eyeCenter);
  vec2 toPixel = normalize(screen_coords - eyeCenter);

  // Calculate dot product for directional factor (-1 to 1)
  float dotProduct = dot(toPixel, toHighlight);

  // Adjust gradient factor based on direction
  float dirFactor = (dotProduct + 1.0) * 0.5; // Convert -1...1 to 0...1
  float gradientFactor = clamp(dist * (1.0 - 0.4 * dirFactor), 0.0, 1.0);

  // Mix colors based on gradient factor
  vec3 finalColor = mix(brightColor.rgb, shadedColor.rgb, gradientFactor);

  // Keep the same alpha
  return vec4(finalColor, 1.0);
}
