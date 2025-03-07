---@class Eyes Module for drawing and managing interactive eyes
local background = require("eyes.background")
local audio = require("eyes.audio")
local fire = require("eyes.fire")
local shadows = require("eyes.shadows")

---@class Eye Represents a single eye with all its properties
---@field x number X-coordinate of the eye
---@field y number Y-coordinate of the eye
---@field size number Size of the eye
---@field fade number Current fade state (0-1)
---@field floatOffset table {x=number, y=number} Current floating offsets
---@field velocity table {x=number, y=number} Current attraction velocity
---@field attractOffset table {x=number, y=number} Current attraction offset
---@field reflection table {intensity=number, x=number, y=number} Reflection properties
---@field pupilDilation number Current pupil dilation value (0-1)
---@field isTouching boolean Whether the eye is currently being touched
local Eye = {}
Eye.__index = Eye

---Creates a new Eye instance
---@param id string Eye identifier (e.g. "left", "right")
---@param x number Initial X position
---@param y number Initial Y position
---@param size number Eye size
---@param phaseX number Initial phase for X floating
---@param phaseY number Initial phase for Y floating
---@return Eye
function Eye.new(id, x, y, size, phaseX, phaseY)
  local self = setmetatable({}, Eye)
  self.id = id
  self.x = x
  self.y = y
  self.baseX = x -- Store the base position
  self.baseY = y
  self.size = size
  self.fade = 0
  self.floatOffset = {x = 0, y = 0}
  self.velocity = {x = 0, y = 0}
  self.attractOffset = {x = 0, y = 0}
  self.phaseX = phaseX
  self.phaseY = phaseY
  self.reflection = {
    intensity = 0,
    x = 0,
    y = 0
  }
  self.pupilDilation = 0
  self.isTouching = false
  return self
end

---Updates the position of the eye based on base position and float offset
---@return number x The actual X position
---@return number y The actual Y position
function Eye:getPosition()
  return self.baseX + self.floatOffset.x,
         self.baseY + self.floatOffset.y
end

---Sets the base position for the eye
---@param x number Base X position
---@param y number Base Y position
function Eye:setBasePosition(x, y)
  self.baseX = x
  self.baseY = y
end

---Updates the floating effect for this eye
---@param dt number Delta time
---@param timeX number Global time X
---@param timeY number Global time Y
---@param config table Floating configuration
---@param attractionPoint table {x=number, y=number} Point of attraction (e.g. mouse/fire position)
function Eye:updateFloating(dt, timeX, timeY, config, attractionPoint)
  -- Calculate basic floating motion with independent X and Y oscillation
  local floatX = math.sin(timeX + self.phaseX) * config.amplitudeX
  local floatY = math.sin(timeY + self.phaseY) * config.amplitudeY

  -- Apply damping to current velocities
  self.velocity.x = self.velocity.x * config.dampingFactor
  self.velocity.y = self.velocity.y * config.dampingFactor

  -- Get the current actual position
  local eyeX, eyeY = self:getPosition()

  -- Calculate distance to attraction point
  local dx = attractionPoint.x - eyeX
  local dy = attractionPoint.y - eyeY
  local distance = math.sqrt(dx * dx + dy * dy)

  -- Apply attraction force if within range
  if distance < config.attractionRange then
    -- Normalize direction vector
    local normalizedX = dx / distance
    local normalizedY = dy / distance

    -- Calculate attraction strength based on distance (stronger when closer)
    local strengthFactor = 1.0 - (distance / config.attractionRange)
    local attractForce = strengthFactor * config.attractionStrength

    -- Apply acceleration to velocity (limited by maxAttractionForce)
    local accelerationX = normalizedX * attractForce
    local accelerationY = normalizedY * attractForce

    self.velocity.x = self.velocity.x + accelerationX * dt
    self.velocity.y = self.velocity.y + accelerationY * dt

    -- Clamp maximum velocity
    local maxVel = config.maxAttractionForce * dt
    local velLength = math.sqrt(self.velocity.x^2 + self.velocity.y^2)
    if (velLength > maxVel) then
      local factor = maxVel / velLength
      self.velocity.x = self.velocity.x * factor
      self.velocity.y = self.velocity.y * factor
    end
  end

  -- Update attraction offsets using velocities
  self.attractOffset.x = self.attractOffset.x + self.velocity.x
  self.attractOffset.y = self.attractOffset.y + self.velocity.y

  -- Combine oscillation with attraction offset
  self.floatOffset.x = floatX + self.attractOffset.x
  self.floatOffset.y = floatY + self.attractOffset.y
end

---Checks if a point is over this eye
---@param x number X coordinate of the point
---@param y number Y coordinate of the point
---@return boolean isOver True if the point is over this eye
function Eye:isPointOver(x, y)
  local eyeX, eyeY = self:getPosition()
  local distance = math.sqrt((x - eyeX)^2 + (y - eyeY)^2)
  return distance < self.size
end

---Updates the touch state and fade value
---@param dt number Delta time
---@param isTouched boolean Whether the eye is being touched
---@param fadeSpeed number Speed at which fade changes
function Eye:updateTouchState(dt, isTouched, fadeSpeed)
  self.isTouching = isTouched

  if isTouched then
    self.fade = math.min(1, self.fade + dt * fadeSpeed)
  else
    self.fade = math.max(0, self.fade - dt * fadeSpeed)
  end
end

---Updates the reflection properties
---@param targetIntensity number Target reflection intensity
---@param x number Reflection X position
---@param y number Reflection Y position
---@param fadeSpeed number Speed at which reflection fades
---@param dt number Delta time
function Eye:updateReflection(targetIntensity, x, y, fadeSpeed, dt)
  self.reflection.intensity = self.reflection.intensity +
    (targetIntensity - self.reflection.intensity) * dt * fadeSpeed
  self.reflection.x = x
  self.reflection.y = y
end

---Updates the pupil dilation
---@param targetDilation number Target pupil dilation
---@param fadeSpeed number Speed at which dilation changes
---@param dt number Delta time
function Eye:updatePupilDilation(targetDilation, fadeSpeed, dt)
  self.pupilDilation = self.pupilDilation +
    (targetDilation - self.pupilDilation) * dt * fadeSpeed
end

-- The public module
local eyes = {
  -- Configuration
  eyeSize = 128,
  eyeSpacing = 320,
  shakeAmount = 5,
  fadeSpeed = 2, -- Speed of color fade transition (units per second)

  -- State variables
  shakeX = 0,
  shakeY = 0,
  x = 0,
  y = 0,

  -- Eyes collection
  eyes = {},

  -- Floating effect configuration
  floating = {
    -- Base floating speed (radians per second)
    speedX = 0.9,
    speedY = 0.9,
    -- Maximum float distance from origin
    amplitudeX = 15,
    amplitudeY = 10,
    -- Time accumulator for animation
    timeX = 0,
    timeY = 0,
    -- Fire attraction parameters
    attractionStrength = 0.08,   -- Reduced from 0.15 for more gradual movement
    attractionRange = 400,       -- Maximum distance at which attraction has an effect
    maxAttractionForce = 0.4,    -- Maximum force of attraction per second
    dampingFactor = 0.85,        -- How quickly attraction velocity decays
  },

  -- Reflection state for fire effects
  reflection = {
    fadeSpeed = 3,      -- How quickly reflection fades in/out
    maxIntensity = 0.9, -- Maximum reflection intensity (increased for visibility)
    minDistance = 80,   -- Minimum distance for reflection to appear
    maxDistance = 350,  -- Distance at which reflection is at minimum intensity
    baseSize = 0.07     -- Base size of reflection as fraction of eye size (smaller)
  },

  -- Pupil dilation state (responds to fire proximity)
  pupilDilation = {
    fadeSpeed = 2.5,       -- Speed of dilation transitions
    maxDilation = 0.30,    -- Maximum additional size factor (30% larger)
    minDistance = 100,     -- Distance at which maximum dilation occurs
    maxDistance = 400,     -- Distance at which dilation begins
  },

  -- Blood veins texture
  bloodVeinsTexture = nil,

  -- Eye textures
  irisTexture = nil,
  pupilTexture = nil,

  -- Eye shading shader
  eyeShader = nil,

  -- Online status
  isOnline = false,
}

-- Constants - Define colors
eyes.colors = {
  white = { 1, 1, 1 },
  shadedWhite = { 0.8, 0.8, 0.9 },
  blue = { 0, 0.5, 0.95 },
  yellow = { 1, 1, 0 },
  orange = { 1, 0.5, 0 },
  red = { 1, 0, 0 },
  purple = { 1, 0, 1 },
  green = { 0, 0.8, 0.2 },
  darkGrey = { 0.1, 0.1, 0.1 },
  lightPink = { 1, 0.92, 0.92 },
  darkRed = { 0.6, 0, 0 },
  -- Fire-related colors are now in fire module
}

-- Eye state
eyes.state = {
  touching = false,
}

-- Private functions defined as locals
---Interpolates between two colors based on a factor (0 to 1)
---@param color1 table First color {r, g, b}
---@param color2 table Second color {r, g, b}
---@param factor number Interpolation factor (0 = color1, 1 = color2)
---@return table Interpolated color {r, g, b}
local function interpolateColor(color1, color2, factor)
  factor = math.max(0, math.min(1, factor)) -- Clamp factor between 0 and 1
  return {
    color1[1] + (color2[1] - color1[1]) * factor,
    color1[2] + (color2[2] - color1[2]) * factor,
    color1[3] + (color2[3] - color1[3]) * factor
  }
end

---Calculates the eye positions based on window dimensions
---@param windowWidth number Width of the window
---@param windowHeight number Height of the window
---@param eyeSpacing number The spacing between eyes
---@return number leftEyeX The x-coordinate of the left eye
---@return number rightEyeX The x-coordinate of the right eye
---@return number centerY The y-coordinate of both eyes
local function calculateEyePositions(windowWidth, windowHeight, eyeSpacing)
  local centerY = windowHeight / 2
  local leftEyeX = (windowWidth / 2) - (eyeSpacing / 2)
  local rightEyeX = (windowWidth / 2) + (eyeSpacing / 2)
  return leftEyeX, rightEyeX, centerY
end

---Draws a single eye
---@param eye Eye The eye to draw
---@param colors table Color definitions
---@param isOnline boolean Whether the system is online
local function drawEye(eye, colors, isOnline)
  local eyeX, eyeY = eye:getPosition()
  local eyeSize = eye.size
  local fadeValue = eye.fade
  local reflectionIntensity = eye.reflection.intensity
  local reflectionX = eye.reflection.x
  local reflectionY = eye.reflection.y
  local dilationFactor = eye.pupilDilation

  -- Interpolate between white and pink based on fade value
  local eyeColor = interpolateColor(colors.white, colors.lightPink, fadeValue)
  local shadedEyeColor = interpolateColor(colors.shadedWhite, colors.lightPink, fadeValue)

  -- Select iris color based on online status
  local baseIrisColor = isOnline and colors.green or colors.blue
  local pupilColor = interpolateColor(baseIrisColor, colors.darkRed, fadeValue)

  -- Calculate the direction vector from eye to fire/cursor
  local fireX, fireY = love.mouse.getPosition()
  local dirX = fireX - eyeX
  local dirY = fireY - eyeY
  local length = math.sqrt(dirX * dirX + dirY * dirY)

  -- Normalize direction vector
  if length > 0 then
    dirX = dirX / length
    dirY = dirY / length
  else
    dirX, dirY = 0, -1  -- Default direction if cursor is exactly on eye center
  end

  -- Calculate offset for highlight position (towards the fire/cursor)
  local highlightOffsetFactor = 0.4
  local highlightX = eyeX + (dirX * eyeSize * highlightOffsetFactor)
  local highlightY = eyeY + (dirY * eyeSize * highlightOffsetFactor)

  -- Send the values to the shader
  eyes.eyeShader:send("eyeCenter", {eyeX, eyeY})
  eyes.eyeShader:send("highlightCenter", {highlightX, highlightY})
  eyes.eyeShader:send("eyeSize", eyeSize)
  eyes.eyeShader:send("brightColor", {eyeColor[1], eyeColor[2], eyeColor[3], 1.0})
  eyes.eyeShader:send("shadedColor", {shadedEyeColor[1], shadedEyeColor[2], shadedEyeColor[3], 1.0})

  -- Draw the eye base with shader for gradient effect
  love.graphics.setShader(eyes.eyeShader)
  love.graphics.setColor(1, 1, 1, 1) -- Set to white with full alpha for proper shader application
  love.graphics.circle("fill", eyeX, eyeY, eyeSize)
  love.graphics.setShader()

  -- Draw blood veins if texture is loaded with opacity based on fade value
  if eyes.bloodVeinsTexture and fadeValue > 0 then
    -- Save current blend mode
    local prevBlendMode = love.graphics.getBlendMode()
    love.graphics.setBlendMode("alpha")

    -- Calculate scale factor to match eye size
    -- Original texture is 512x512, so scale to match the eye diameter (2 * eyeSize)
    local scale = (2 * eyeSize) / 512

    -- Draw the texture centered on the eye with alpha based on fade value
    love.graphics.setColor(1, 1, 1, fadeValue)
    love.graphics.draw(
      eyes.bloodVeinsTexture,
      eyeX, eyeY,
      0,                     -- rotation (0 means no rotation)
      scale, scale,          -- scale X and Y
      256, 256               -- origin point (center of the 512x512 texture)
    )

    -- Restore previous blend mode
    love.graphics.setBlendMode(prevBlendMode)
  end

  -- Calculate tracking position (where pupil would be when tracking mouse)
  local distanceX = love.mouse.getX() - eyeX
  local distanceY = love.mouse.getY() - eyeY
  local distance = math.min(math.sqrt(distanceX^2 + distanceY^2), eyeSize / 2)
  local angle = math.atan2(distanceY, distanceX)

  local trackingX = eyeX + (math.cos(angle) * distance)
  local trackingY = eyeY + (math.sin(angle) * distance)

  -- Calculate oscillation position (where pupil would be when eye is touched)
  local oscillationRange = eyeSize / 16
  local oscillationX = eyeX + love.math.random(-oscillationRange, oscillationRange)
  local oscillationY = eyeY + love.math.random(-oscillationRange, oscillationRange)

  -- Interpolate between tracking and oscillation based on fade value
  local irisX = trackingX + (oscillationX - trackingX) * fadeValue
  local irisY = trackingY + (oscillationY - trackingY) * fadeValue

  -- Calculate a subtle additional offset for the pupil (25% of the main tracking)
  local pupilOffsetFactor = 0.10 -- Controls how much extra the pupil moves relative to iris
  local subtleDistance = distance * pupilOffsetFactor

  -- Apply the subtle offset to the pupil position
  local pupilX = irisX + (math.cos(angle) * subtleDistance)
  local pupilY = irisY + (math.sin(angle) * subtleDistance)

  -- Draw textured iris with color tinting based on fade value
  if eyes.irisTexture then
    -- Calculate scale for iris texture (about 140% of the eye size)
    local irisScale = (eyeSize * 1.4) / 512

    -- Apply color tinting to iris
    love.graphics.setColor(pupilColor)
    love.graphics.draw(
      eyes.irisTexture,
      irisX, irisY,
      0,                -- no rotation
      irisScale, irisScale,
      256, 256         -- center of 512x512 texture
    )
  end

  -- Draw pupil texture on top of iris with subtle offset
  if eyes.pupilTexture then
    -- Calculate base pupil scale with dilation effect
    local basePupilScale = eyeSize * 0.8 / 512
    -- Apply dilation factor (up to maxDilation % larger)
    local dilatedScale = basePupilScale * (1 + (eyes.pupilDilation.maxDilation * dilationFactor))

    -- Draw pupil with original color
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
      eyes.pupilTexture,
      pupilX, pupilY,
      0,                -- no rotation
      dilatedScale, dilatedScale,
      256, 256         -- center of 512x512 texture
    )
  end

  -- Draw fire reflection as a glint on the edge of pupil opposite to the fire source
  -- The glint should fade away completely when the eye is being touched
  if reflectionIntensity > 0 then
    -- Calculate actual reflection intensity - fades out completely when eye is touched
    local actualIntensity = reflectionIntensity * (1.0 - fadeValue)

    if actualIntensity > 0.01 then -- Only draw if visible
      -- Save current blend mode and line style
      local prevBlendMode = love.graphics.getBlendMode()
      local prevLineStyle = love.graphics.getLineStyle()
      local prevLineWidth = love.graphics.getLineWidth()

      -- Enable smooth line drawing
      love.graphics.setLineStyle("smooth")
      love.graphics.setLineWidth(2)

      -- Calculate the angle from pupil to cursor (fire source)
      local fireAngle = math.atan2(love.mouse.getY() - pupilY, love.mouse.getX() - pupilX)

      -- Calculate the opposite angle (pupil edge away from fire)
      local glintAngle = fireAngle + math.pi

      -- Calculate the pupil radius and position glint on its edge
      local pupilRadius = eyeSize * 0.15 -- Approximation of pupil radius
      local glintX = pupilX + math.cos(glintAngle) * pupilRadius
      local glintY = pupilY + math.sin(glintAngle) * pupilRadius

      -- Calculate glint size - significantly smaller than before
      local baseGlintSize = eyeSize * eyes.reflection.baseSize
      local glintSize = baseGlintSize * actualIntensity

      -- Use additive blending for glow effect
      love.graphics.setBlendMode("add")

      -- Draw the main glint with anti-aliasing
      love.graphics.setColor(1, 0.95, 0.8, 0.8 * actualIntensity)
      love.graphics.circle("fill", glintX, glintY, glintSize)

      -- Add a brighter core with anti-aliasing
      love.graphics.setColor(1, 1, 0.9, 0.9 * actualIntensity)
      love.graphics.circle("fill", glintX, glintY, glintSize * 0.6)

      -- Restore previous graphics settings
      love.graphics.setBlendMode(prevBlendMode)
      love.graphics.setLineStyle(prevLineStyle)
      love.graphics.setLineWidth(prevLineWidth)
    end
  end
end

---Updates the fire effect and fire dot
---@param x number Mouse X position
---@param y number Mouse Y position
local function drawFireEffect(x, y)
  -- Draw fire effect using the fire module
  fire.draw()

  -- Make the mouse invisible
  love.mouse.setVisible(false)
end

---Updates the online status by performing a network request
---@return boolean isOnline True if the site is online
local function checkOnlineStatus()
  if not https then return false end

  local success, result = pcall(function()
    local code, body, headers = https.request("https://oval-tutu.com")
    return { code = code, body = body, headers = headers }
  end)

  return success and result and result.code and result.code < 400
end

---Updates the shake effect when mouse is over eyes
---@param shakeAmount number Maximum shake amount
---@return number shakeX Resulting X shake value
---@return number shakeY Resulting Y shake value
local function updateShakeEffect(shakeAmount)
  if eyes.state.touching then
    return love.math.random(-shakeAmount, shakeAmount), love.math.random(-shakeAmount, shakeAmount)
  else
    return 0, 0
  end
end

---Loads resources and initializes the eyes
function eyes.load()
  background:load()
  audio:load()
  fire:load()
  shadows.load()

  -- Check online status
  eyes.isOnline = checkOnlineStatus()

  -- Load textures
  eyes.bloodVeinsTexture = love.graphics.newImage("eyes/gfx/blood_veins_100.png")
  eyes.irisTexture = love.graphics.newImage("eyes/gfx/iris.png")
  eyes.pupilTexture = love.graphics.newImage("eyes/gfx/pupil.png")

  -- Load eye shader from file
  local success, result = pcall(function()
    return love.graphics.newShader("eyes/shaders/eye.glsl")
  end)

  if success then
    eyes.eyeShader = result
  else
    print("Error loading eye shader: " .. tostring(result))
    -- Create a simple fallback shader if loading fails
    eyes.eyeShader = love.graphics.newShader([[
      vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        return color;
      }
    ]])
  end

  -- Create our eye instances
  local windowWidth, windowHeight = love.graphics.getDimensions()
  local leftX, rightX, centerY = calculateEyePositions(windowWidth, windowHeight, eyes.eyeSpacing)

  -- Create eyes with their appropriate phases
  eyes.eyes.left = Eye.new("left", leftX, centerY, eyes.eyeSize,
                          eyes.floating.phaseLeftX or 0,
                          eyes.floating.phaseLeftY or math.pi * 0.5)

  eyes.eyes.right = Eye.new("right", rightX, centerY, eyes.eyeSize,
                           eyes.floating.phaseRightX or math.pi * 0.7,
                           eyes.floating.phaseRightY or math.pi * 0.3)

  love.graphics.setFont(love.graphics.newFont(42))
  love.mouse.setVisible(false)
end

function eyes.update(dt)
  background:update(dt)

  eyes.x, eyes.y = love.mouse.getPosition()
  eyes.x = math.floor(eyes.x)
  eyes.y = math.floor(eyes.y)
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()

  -- Update shadow positions
  shadows.update(dt, windowHeight)

  -- Calculate base eye positions once per frame
  local leftEyeX, rightEyeX, centerY = calculateEyePositions(windowWidth, windowHeight, eyes.eyeSpacing)

  -- Update base positions for our eye objects
  eyes.eyes.left:setBasePosition(leftEyeX, centerY)
  eyes.eyes.right:setBasePosition(rightEyeX, centerY)

  -- Update floating time accumulators
  eyes.floating.timeX = (eyes.floating.timeX + dt * eyes.floating.speedX) % (2 * math.pi)
  eyes.floating.timeY = (eyes.floating.timeY + dt * eyes.floating.speedY) % (2 * math.pi)

  -- Update floating effect for each eye
  local mousePos = {x = eyes.x, y = eyes.y}
  eyes.eyes.left:updateFloating(dt, eyes.floating.timeX, eyes.floating.timeY, eyes.floating, mousePos)
  eyes.eyes.right:updateFloating(dt, eyes.floating.timeX, eyes.floating.timeY, eyes.floating, mousePos)

  -- Update touch detection for each eye
  eyes.eyes.left:updateTouchState(dt, eyes.eyes.left:isPointOver(eyes.x, eyes.y), eyes.fadeSpeed)
  eyes.eyes.right:updateTouchState(dt, eyes.eyes.right:isPointOver(eyes.x, eyes.y), eyes.fadeSpeed)

  -- Update overall touch state
  eyes.state.touching = eyes.eyes.left.isTouching or eyes.eyes.right.isTouching

  -- Update audio system with current state and cursor position
  audio:update(dt, {
    touching = eyes.state.touching,
    touchingLeft = eyes.eyes.left.isTouching,
    touchingRight = eyes.eyes.right.isTouching
  }, eyes.x, eyes.y)

  -- Update fire module with current mouse position
  fire.update(dt, eyes.x, eyes.y)

  -- Calculate and update reflections for both eyes
  local leftEyeX, leftEyeY = eyes.eyes.left:getPosition()
  local rightEyeX, rightEyeY = eyes.eyes.right:getPosition()

  local leftIntensityTarget, rightIntensityTarget, leftX, leftY, rightX, rightY =
    fire.calculateReflectionProperties(
      eyes.x, eyes.y,
      leftEyeX, rightEyeX, leftEyeY,
      eyes.eyeSize, eyes.reflection
    )

  eyes.eyes.left:updateReflection(
    leftIntensityTarget, leftX, leftY,
    eyes.reflection.fadeSpeed, dt
  )

  eyes.eyes.right:updateReflection(
    rightIntensityTarget, rightX, rightY,
    eyes.reflection.fadeSpeed, dt
  )

  -- Calculate and update pupil dilation for both eyes
  local leftDilationTarget, rightDilationTarget =
    fire.calculatePupilDilation(
      eyes.x, eyes.y,
      leftEyeX, rightEyeX, leftEyeY,
      eyes.pupilDilation
    )

  eyes.eyes.left:updatePupilDilation(
    leftDilationTarget,
    eyes.pupilDilation.fadeSpeed,
    dt
  )

  eyes.eyes.right:updatePupilDilation(
    rightDilationTarget,
    eyes.pupilDilation.fadeSpeed,
    dt
  )
end

function eyes.draw()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()

  -- Draw a solid black background first
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

  -- Calculate shake effect
  eyes.shakeX, eyes.shakeY = updateShakeEffect(eyes.shakeAmount)

  love.graphics.push()
  love.graphics.translate(eyes.shakeX, eyes.shakeY)
  background:draw()

  -- Get actual eye positions for shadows
  local leftX, leftY = eyes.eyes.left:getPosition()
  local rightX, rightY = eyes.eyes.right:getPosition()

  -- Draw shadows first so they appear beneath the eyes
  shadows.draw(leftX, leftY, eyes.eyeSize)
  shadows.draw(rightX, rightY, eyes.eyeSize)

  -- Draw eyes with their respective fade values, reflection effects, pupil dilation, and online status
  drawEye(eyes.eyes.left, eyes.colors, eyes.isOnline)
  drawEye(eyes.eyes.right, eyes.colors, eyes.isOnline)

  -- Draw only the fire effect, no mouse coordinates or online status
  drawFireEffect(eyes.x, eyes.y)

  love.graphics.pop()
end

-- Add cleanup for audio when the scene is exited
function eyes.unload()
  audio:stop()
end

return eyes
