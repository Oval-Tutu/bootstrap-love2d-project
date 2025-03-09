// WebGL compatibility: only define precision when running on OpenGL ES/WebGL
#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 eyeCenter;
uniform vec2 highlightCenter;
uniform float eyeSize;
uniform vec4 brightColor;
uniform vec4 shadedColor;

vec4 effect(vec4 color, sampler2D texture, vec2 texture_coords, vec2 screen_coords) {
  float gradientCurve = 1.3;  // Controls gradient curve steepness
  float powerFactor = 1.2;    // Controls 3D effect intensity
  float edgeSmoothing = 1.0;  // Controls anti-aliasing amount

  // Calculate distance from current pixel to eye center
  float dist = distance(screen_coords, eyeCenter);

  // Create smooth anti-aliased edge with feathering
  float alpha = 1.0 - smoothstep(eyeSize - edgeSmoothing, eyeSize, dist);

  // Guard against division by zero
  float safeEyeSize = max(eyeSize, 0.001);

  // Calculate normalized distance from highlight center (0-1)
  float highlightDist = distance(screen_coords, highlightCenter) / safeEyeSize;

  // Create gradient curve for shading effect
  float gradientFactor = smoothstep(0.0, gradientCurve, highlightDist);

  // Add power curve to enhance the 3D effect
  gradientFactor = pow(gradientFactor, powerFactor);

  // Interpolate between bright and shaded colors
  vec4 finalColor = mix(brightColor, shadedColor, gradientFactor);

  // Apply anti-aliased edge to alpha
  return vec4(finalColor.rgb, finalColor.a * alpha);
}
