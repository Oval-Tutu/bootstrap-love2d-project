---@class Shadows Module for drawing eye shadows
local shadows = {
  -- Shadow configuration
  distanceFromBottom = 200,  -- Fixed position from bottom of screen
  color = {0, 0, 0, 0.1},   -- Shadow color (black with 15% opacity)
  scaleFactor = 0.7,         -- Base shadow scale relative to eye size
  scaleDistance = 300,       -- Distance for scaling shadow size
  minScale = 0.75,           -- Minimum scale factor
  blur = 8,                  -- Shadow blur amount in pixels
  yOffset = 0,               -- Will be calculated in update
}

-- Private functions
---Draws shadow beneath an eye
---@param eyeX number The x-coordinate of the eye
---@param eyeY number The y-coordinate of the eye
---@param eyeSize number The size of the eye
---@param shadowY number The y-coordinate of the shadow
local function drawShadow(eyeX, eyeY, eyeSize, shadowY)
  -- Calculate distance between eye and shadow position
  local distance = math.abs(eyeY - shadowY)

  -- Calculate shadow scale based on distance
  -- The further the eye is from the shadow position, the smaller the shadow
  local distanceRatio = math.min(1, distance / shadows.scaleDistance)
  local shadowScale = shadows.scaleFactor * (shadows.minScale + (1 - shadows.minScale) * (1 - distanceRatio))

  -- Calculate shadow width and height (elliptical)
  local shadowWidth = eyeSize * 1.75 * shadowScale
  local shadowHeight = eyeSize * 0.25 * shadowScale

  -- Save the current blend mode and shader
  local prevBlendMode = love.graphics.getBlendMode()
  local prevShader = love.graphics.getShader()

  -- Set blend mode for proper alpha blending
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.setShader()

  -- Draw the shadow as a blurred ellipse with natural fading to edges
  local blurSteps = 10  -- Increased for smoother gradient
  local maxScale = 1.25 -- Maximum scale factor for outermost blur

  -- Draw from innermost (darkest) to outermost (lightest)
  -- First draw the main shadow ellipse with base opacity
  love.graphics.setColor(shadows.color[1], shadows.color[2], shadows.color[3], shadows.color[4])
  love.graphics.ellipse("fill", eyeX, shadowY, shadowWidth, shadowHeight)

  -- Then draw the blurred edges with decreasing opacity
  for i = 1, blurSteps do
    -- Calculate progress from inner to outer (0 to 1)
    local progress = i / blurSteps

    -- Scale increases as we move outward
    local scaleIncrement = progress * (maxScale - 1.0)
    local currentScale = 1.0 + scaleIncrement

    -- Opacity decreases as we move outward - use a non-linear falloff for more natural look
    -- The power function creates a faster falloff near the edges
    local opacityFactor = math.pow(1.0 - progress, 2.0)
    local opacity = shadows.color[4] * opacityFactor * 0.8

    -- Set the color with calculated opacity
    love.graphics.setColor(shadows.color[1], shadows.color[2], shadows.color[3], opacity)

    -- Draw the blurred ellipse layer
    love.graphics.ellipse("fill", eyeX, shadowY,
                         shadowWidth * currentScale,
                         shadowHeight * currentScale)
  end

  -- Restore graphics state
  love.graphics.setLineWidth(1)
  love.graphics.setBlendMode(prevBlendMode)
  love.graphics.setShader(prevShader)
end

-- Public functions
---Initialize the shadows module
function shadows.load()
  -- Nothing to load for now, but keeping for consistency with other modules
end

---Update shadow positioning based on window height
---@param dt number Delta time since last frame
---@param windowHeight number Current window height
function shadows.update(dt, windowHeight)
  -- Calculate the shadow y position based on window height
  shadows.yOffset = windowHeight - shadows.distanceFromBottom
end

---Draw a shadow for an eye
---@param eyeX number The x-coordinate of the eye
---@param eyeY number The y-coordinate of the eye
---@param eyeSize number The size of the eye
function shadows.draw(eyeX, eyeY, eyeSize)
  drawShadow(eyeX, eyeY, eyeSize, shadows.yOffset)
end

return shadows
