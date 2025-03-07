uniform vec2 eyeCenter;
uniform vec2 highlightCenter;
uniform float eyeSize;
uniform vec4 brightColor;
uniform vec4 shadedColor;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  // Calculate distance from current pixel to eye center
  float dist = distance(screen_coords, eyeCenter);

  // Create smooth anti-aliased edge with 1 pixel feathering
  float edgeSmoothing = 1.0;
  float alpha = 1.0 - smoothstep(eyeSize - edgeSmoothing, eyeSize, dist);

  // Only apply effect within the eye circle
  if (dist > eyeSize) {
    return vec4(0.0, 0.0, 0.0, 0.0); // Transparent outside the eye
  }

  // Calculate normalized distance from highlight center (0-1)
  float highlightDist = distance(screen_coords, highlightCenter) / eyeSize;

  // Create a more pronounced gradient curve that's brightest at highlight center
  // and more strongly shadows the edges
  float gradientFactor = smoothstep(0.0, 1.3, highlightDist); // Adjusted from 1.5 to 1.3

  // Add a slight power curve to enhance the 3D effect
  gradientFactor = pow(gradientFactor, 1.2);

  // Interpolate between bright and shaded colors
  vec4 finalColor = mix(brightColor, shadedColor, gradientFactor);

  // Apply anti-aliased edge to alpha
  return vec4(finalColor.rgb, finalColor.a * alpha);
}
