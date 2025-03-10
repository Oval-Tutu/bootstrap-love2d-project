---@class Eyes Module for drawing and managing interactive eyes
local background = require("eyes.background")
local audio = require("eyes.audio")
local fire = require("eyes.fire")
local shadows = require("eyes.shadows")
local vector = require("eyes.utils.vector")
local colorUtils = require("eyes.utils.color_utils")
local StateManager = require("eyes.utils.state_manager")
local ResourceManager = require("eyes.utils.resource_manager")

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
---@field pupilTarget table {x=number, y=number} Target position for the pupil
---@field pupilCurrent table {x=number, y=number} Current position of the pupil
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

  -- Initialize pupil tracking properties
  self.pupilTarget = {x = x, y = y}
  self.pupilCurrent = {x = x, y = y}

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
  -- Calculate oscillation component (simple harmonic motion)
  local floatX = math.sin(timeX + self.phaseX) * config.amplitudeX
  local floatY = math.sin(timeY + self.phaseY) * config.amplitudeY

  -- Update attraction physics (velocity-based movement towards attraction point)
  self:updateAttractionPhysics(dt, attractionPoint, config)

  -- Combine oscillation with attraction offset for final position
  self.floatOffset.x = floatX + self.attractOffset.x
  self.floatOffset.y = floatY + self.attractOffset.y
end

---Updates the attraction physics for the eye
---@param dt number Delta time
---@param attractionPoint table {x=number, y=number} Point of attraction
---@param config table Floating configuration with attraction parameters
function Eye:updateAttractionPhysics(dt, attractionPoint, config)
  -- Apply damping to current velocity (simulates drag/friction)
  self.velocity.x = self.velocity.x * config.dampingFactor
  self.velocity.y = self.velocity.y * config.dampingFactor

  -- Get current eye position
  local eyeX, eyeY = self:getPosition()

  -- Calculate vector to attraction point
  local dx = attractionPoint.x - eyeX
  local dy = attractionPoint.y - eyeY
  local distance = vector.length(dx, dy)

  -- Only apply attraction if within range
  if distance < config.attractionRange then
    -- Calculate attraction force (stronger when closer)
    local normalizedX, normalizedY = vector.normalize(dx, dy)
    local strengthFactor = 1.0 - (distance / config.attractionRange)
    local attractForce = strengthFactor * config.attractionStrength

    -- Apply acceleration to velocity
    local accelerationX = normalizedX * attractForce
    local accelerationY = normalizedY * attractForce

    self.velocity.x = self.velocity.x + accelerationX * dt
    self.velocity.y = self.velocity.y + accelerationY * dt

    -- Clamp maximum velocity
    local maxVel = config.maxAttractionForce * dt
    self.velocity.x, self.velocity.y = vector.clamp(
      self.velocity.x, self.velocity.y, maxVel
    )
  end

  -- Update position based on velocity
  self.attractOffset.x = self.attractOffset.x + self.velocity.x
  self.attractOffset.y = self.attractOffset.y + self.velocity.y
end

---Checks if a point is over this eye
---@param x number X coordinate of the point
---@param y number Y coordinate of the point
---@return boolean isOver True if the point is over this eye
function Eye:isPointOver(x, y)
  local eyeX, eyeY = self:getPosition()
  local distance = vector.distance(x, y, eyeX, eyeY)
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

---Updates the tracking position of the pupil with inertia
---@param dt number Delta time
---@param targetX number Target X position
---@param targetY number Target Y position
---@param trackingSpeed number How quickly the pupil tracks the target
function Eye:updatePupilTracking(dt, targetX, targetY, trackingSpeed)
  -- Update the target position
  self.pupilTarget.x = targetX
  self.pupilTarget.y = targetY

  -- Move current position toward target with inertia
  self.pupilCurrent.x = self.pupilCurrent.x +
    (self.pupilTarget.x - self.pupilCurrent.x) * dt * trackingSpeed
  self.pupilCurrent.y = self.pupilCurrent.y +
    (self.pupilTarget.y - self.pupilCurrent.y) * dt * trackingSpeed
end

-- The public module
local eyes = {
  -- Configuration
  eyeSize = 128,
  eyeSpacing = 320,
  shakeAmount = 5,
  fadeSpeed = 2, -- Speed of color fade transition (units per second)

  -- State variables - will be managed by StateManager
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
    -- Fire attraction parameters
    attractionStrength = 0.08,   -- Reduced from 0.15 for more gradual movement
    attractionRange = 400,       -- Maximum distance at which attraction has an effect
    maxAttractionForce = 0.4,    -- Maximum force of attraction per second
    dampingFactor = 0.85,        -- How quickly attraction velocity decays
  },

  -- Eye tracking configuration
  tracking = {
    speed = 15.0,                -- Base speed of eye tracking (higher = faster tracking)
    touchedSpeedFactor = 0.3,    -- When touched, tracking is this much slower
    maxTrackingDistance = 0.5,   -- Max percentage of eye size the pupil can move from center
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

  -- Resource manager
  resources = nil,
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

-- Drawing helper functions
---Draws the base of an eye using a shader for gradient effect
---@param eyeX number X position of the eye
---@param eyeY number Y position of the eye
---@param eyeSize number Size of the eye
---@param eyeColor table {r,g,b} bright color
---@param shadedEyeColor table {r,g,b} shaded color
---@param dirX number X direction to light source
---@param dirY number Y direction to light source
local function drawEyeBase(eyeX, eyeY, eyeSize, eyeColor, shadedEyeColor, dirX, dirY)
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
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  love.graphics.circle("fill", eyeX, eyeY, eyeSize)
  love.graphics.setShader()
end

---Draws blood veins on the eye if eye is touched
---@param eyeX number X position of the eye
---@param eyeY number Y position of the eye
---@param eyeSize number Size of the eye
---@param fadeValue number 0-1 fade value for the veins
local function drawBloodVeins(eyeX, eyeY, eyeSize, fadeValue)
  if not eyes.bloodVeinsTexture or fadeValue <= 0 then return end

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

---Calculates the iris and pupil position
---@param eyeX number X position of the eye
---@param eyeY number Y position of the eye
---@param eyeSize number Size of the eye
---@param fadeValue number 0-1 fade value for oscillation
---@param currentPupilX number Current X position of the pupil (for inertia)
---@param currentPupilY number Current Y position of the pupil (for inertia)
---@return number irisX X position of the iris
---@return number irisY Y position of the iris
---@return number pupilX X position of the pupil
---@return number pupilY Y position of the pupil
---@return number angle Direction angle
local function calculatePupilPosition(eyeX, eyeY, eyeSize, fadeValue, currentPupilX, currentPupilY)
  local mouseX, mouseY = love.mouse.getPosition()
  local distanceX = mouseX - eyeX
  local distanceY = mouseY - eyeY

  -- Calculate the maximum distance the pupil can move
  local maxDistance = eyeSize * eyes.tracking.maxTrackingDistance

  -- Calculate tracking position
  local distance = math.min(math.sqrt(distanceX^2 + distanceY^2), maxDistance)
  local angle = math.atan2(distanceY, distanceX)

  -- Use the current position from the eye's tracking system
  local trackingX = currentPupilX
  local trackingY = currentPupilY

  -- Calculate oscillation position (where pupil would be when eye is touched)
  local oscillationRange = eyeSize / 16
  local oscillationX = eyeX + love.math.random(-oscillationRange, oscillationRange)
  local oscillationY = eyeY + love.math.random(-oscillationRange, oscillationRange)

  -- Interpolate between tracking and oscillation based on fade value
  local irisX = trackingX + (oscillationX - trackingX) * fadeValue
  local irisY = trackingY + (oscillationY - trackingY) * fadeValue

  -- Calculate a subtle additional offset for the pupil
  local pupilOffsetFactor = 0.10 -- Controls how much extra the pupil moves relative to iris
  local subtleDistance = distance * pupilOffsetFactor

  -- Apply the subtle offset to the pupil position
  local pupilX = irisX + (math.cos(angle) * subtleDistance)
  local pupilY = irisY + (math.sin(angle) * subtleDistance)

  return irisX, irisY, pupilX, pupilY, angle
end

---Draws the iris texture
---@param irisX number X position of the iris
---@param irisY number Y position of the iris
---@param eyeSize number Size of the eye
---@param pupilColor table {r,g,b} Color of the pupil
local function drawIris(irisX, irisY, eyeSize, pupilColor)
  if not eyes.irisTexture then return end

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

---Draws the pupil texture with dilation
---@param pupilX number X position of the pupil
---@param pupilY number Y position of the pupil
---@param eyeSize number Size of the eye
---@param dilationFactor number 0-1 dilation factor
local function drawPupil(pupilX, pupilY, eyeSize, dilationFactor)
  if not eyes.pupilTexture then return end

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

---Draws the fire reflection glint
---@param pupilX number X position of the pupil
---@param pupilY number Y position of the pupil
---@param eyeSize number Size of the eye
---@param reflectionIntensity number Intensity of the reflection
---@param fadeValue number Fade value of the eye (reduces reflection)
local function drawReflection(pupilX, pupilY, eyeSize, reflectionIntensity, fadeValue)
  -- Calculate actual reflection intensity - fades out completely when eye is touched
  local actualIntensity = reflectionIntensity * (1.0 - fadeValue)

  if actualIntensity <= 0.01 then return end -- Only draw if visible

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

  -- Get reflection colors from the palette
  local mainGlintColor = colorUtils.getColor("reflections", "main")
  local coreGlintColor = colorUtils.getColor("reflections", "core")

  -- Draw the main glint with anti-aliasing
  love.graphics.setColor(
    mainGlintColor[1], mainGlintColor[2], mainGlintColor[3],
    0.8 * actualIntensity
  )
  love.graphics.circle("fill", glintX, glintY, glintSize)

  -- Add a brighter core with anti-aliasing
  love.graphics.setColor(
    coreGlintColor[1], coreGlintColor[2], coreGlintColor[3],
    0.9 * actualIntensity
  )
  love.graphics.circle("fill", glintX, glintY, glintSize * 0.6)

  -- Restore previous graphics settings
  love.graphics.setBlendMode(prevBlendMode)
  love.graphics.setLineStyle(prevLineStyle)
  love.graphics.setLineWidth(prevLineWidth)
end

---Draws a single eye
---@param eye Eye The eye to draw
---@param isOnline boolean Whether the system is online
local function drawEye(eye, isOnline)
  local eyeX, eyeY = eye:getPosition()
  local eyeSize = eye.size
  local fadeValue = eye.fade
  local reflectionIntensity = eye.reflection.intensity
  local dilationFactor = eye.pupilDilation

  -- Get base colors from color utility
  local whiteColor = colorUtils.getMainColor("white")
  local shadedWhiteColor = colorUtils.getMainColor("shadedWhite")
  local lightPinkColor = colorUtils.getMainColor("lightPink")
  local baseIrisColor

  -- Select iris color based on online status
  if isOnline then
    baseIrisColor = colorUtils.getColor("eyes", "online.iris")
  else
    baseIrisColor = colorUtils.getColor("eyes", "normal.iris")
  end

  local touchedIrisColor = colorUtils.getColor("eyes", "touched.iris")

  -- Interpolate between white and pink based on fade value
  local eyeColor = colorUtils.lerp(whiteColor, lightPinkColor, fadeValue)
  local shadedEyeColor = colorUtils.lerp(shadedWhiteColor, lightPinkColor, fadeValue)

  -- Interpolate iris color based on touch state
  local pupilColor = colorUtils.lerp(baseIrisColor, touchedIrisColor, fadeValue)

  -- Calculate the direction vector from eye to fire/cursor
  local fireX, fireY = love.mouse.getPosition()
  local dirX, dirY = vector.normalize(fireX - eyeX, fireY - eyeY)

  -- If normalization failed (rare case where cursor is exactly at eye center)
  if dirX == 0 and dirY == 0 then
    dirX, dirY = 0, -1
  end

  -- Draw the eye components in order (back to front)
  drawEyeBase(eyeX, eyeY, eyeSize, eyeColor, shadedEyeColor, dirX, dirY)
  drawBloodVeins(eyeX, eyeY, eyeSize, fadeValue)

  -- Calculate iris and pupil positions using current tracked position
  local irisX, irisY, pupilX, pupilY = calculatePupilPosition(
    eyeX, eyeY, eyeSize, fadeValue,
    eye.pupilCurrent.x, eye.pupilCurrent.y
  )

  drawIris(irisX, irisY, eyeSize, pupilColor)
  drawPupil(pupilX, pupilY, eyeSize, dilationFactor)
  drawReflection(pupilX, pupilY, eyeSize, reflectionIntensity, fadeValue)
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

---Calculate distance from a point to an eye
---@param pointX number X position of the point
---@param pointY number Y position of the point
---@param eyeX number X position of the eye
---@param eyeY number Y position of the eye
---@return number distance Distance from point to eye
function eyes.calculateDistanceToEye(pointX, pointY, eyeX, eyeY)
  return math.sqrt((pointX - eyeX)^2 + (pointY - eyeY)^2)
end

---Calculates intensity value based on distance and configuration
---@param distance number Distance to the eye
---@param config table Configuration with minDistance, maxDistance and (optionally) maxIntensity
---@param minIntensity number Minimum intensity to use when in range (defaults to 0)
---@param invert boolean If true, closer distance means lower intensity (defaults to false)
---@return number intensity The calculated intensity value (0-1 or 0-maxIntensity)
function eyes.calculateIntensityFromDistance(distance, config, minIntensity, invert)
  -- Default values
  minIntensity = minIntensity or 0
  local maxIntensity = config.maxIntensity or 1

  -- If outside range, no intensity
  if distance >= config.maxDistance then
    return 0
  end

  -- Calculate normalized distance factor (0-1)
  local distanceFactor = (distance - config.minDistance) / (config.maxDistance - config.minDistance)

  -- Clamp to 0-1 range
  distanceFactor = math.max(0, math.min(1, distanceFactor))

  -- Invert if needed (for dilation, closer = more effect)
  if invert then
    distanceFactor = 1 - distanceFactor
  else
    -- For normal case (reflection), closer = more intensity
    distanceFactor = 1 - distanceFactor
  end

  -- Calculate final intensity and clamp to range
  local intensity = distanceFactor * maxIntensity
  return math.max(minIntensity, math.min(maxIntensity, intensity))
end

---Calculate effects (reflection and dilation) for both eyes in a single pass
---@param mousePosition table {x=number, y=number} Mouse/cursor position
---@param leftEye Eye The left eye object
---@param rightEye Eye The right eye object
---@param reflectionConfig table Configuration for reflection effect
---@param dilationConfig table Configuration for pupil dilation effect
---@return table Effects calculated effects {leftReflection=number, rightReflection=number, leftDilation=number, rightDilation=number}
function eyes.calculateEyeEffects(mousePosition, leftEye, rightEye, reflectionConfig, dilationConfig)
  -- Get eye positions
  local leftEyeX, leftEyeY = leftEye:getPosition()
  local rightEyeX, rightEyeY = rightEye:getPosition()

  -- Calculate distances to eyes just once
  local distanceToLeft = eyes.calculateDistanceToEye(mousePosition.x, mousePosition.y, leftEyeX, leftEyeY)
  local distanceToRight = eyes.calculateDistanceToEye(mousePosition.x, mousePosition.y, rightEyeX, rightEyeY)

  -- Calculate reflection intensities
  local leftReflection = eyes.calculateIntensityFromDistance(distanceToLeft, reflectionConfig, 0.2)
  local rightReflection = eyes.calculateIntensityFromDistance(distanceToRight, reflectionConfig, 0.2)

  -- Calculate dilation factors (invert the distance relationship)
  local leftDilation = eyes.calculateIntensityFromDistance(distanceToLeft, dilationConfig, 0, true)
  local rightDilation = eyes.calculateIntensityFromDistance(distanceToRight, dilationConfig, 0, true)

  -- Return all calculated values in a single table
  return {
    leftReflection = leftReflection,
    rightReflection = rightReflection,
    leftDilation = leftDilation,
    rightDilation = rightDilation,
    leftX = leftEyeX,
    leftY = leftEyeY,
    rightX = rightEyeX,
    rightY = rightEyeY
  }
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
  -- Initialize resource manager and load all resources
  eyes.resources = ResourceManager.new():loadAll()

  -- Store references to commonly used resources for convenience
  eyes.bloodVeinsTexture = eyes.resources:getTexture("bloodVeins")
  eyes.irisTexture = eyes.resources:getTexture("iris")
  eyes.pupilTexture = eyes.resources:getTexture("pupil")
  eyes.eyeShader = eyes.resources:getShader("eye")

  -- Set the default font
  eyes.resources:setDefaultFont("default")

  -- Load other modules
  background:load()
  audio:load()
  fire:load()
  shadows.load()

  -- Store reference to fire module for state manager
  eyes.fireModule = fire

  -- Check online status
  eyes.isOnline = checkOnlineStatus()

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

  -- Initialize the state manager
  eyes.stateManager = StateManager.new(eyes)

  -- Hide the mouse cursor
  love.mouse.setVisible(false)
end

function eyes.update(dt)
  background:update(dt)

  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()

  -- Update shadow positions
  shadows.update(dt, windowHeight)

  -- Calculate base eye positions once per frame
  local leftEyeX, rightEyeX, centerY = calculateEyePositions(windowWidth, windowHeight, eyes.eyeSpacing)

  -- Update base positions for our eye objects
  eyes.eyes.left:setBasePosition(leftEyeX, centerY)
  eyes.eyes.right:setBasePosition(rightEyeX, centerY)

  -- Update all state through the centralized state manager
  eyes.stateManager:update(dt)

  -- Copy important state values for convenience/backward compatibility
  eyes.x = eyes.stateManager.mousePosition.x
  eyes.y = eyes.stateManager.mousePosition.y
  eyes.shakeX = eyes.stateManager.shake.x
  eyes.shakeY = eyes.stateManager.shake.y

  -- Update eye pupil tracking with inertia
  local leftEye = eyes.eyes.left
  local rightEye = eyes.eyes.right
  local leftEyeX, leftEyeY = leftEye:getPosition()
  local rightEyeX, rightEyeY = rightEye:getPosition()

  -- Calculate target positions for both eyes
  local function calculateTargetPosition(eyeX, eyeY, eyeSize)
    local mouseX, mouseY = love.mouse.getPosition()
    local distanceX = mouseX - eyeX
    local distanceY = mouseY - eyeY

    -- Limit how far the pupil can move from center
    local maxDistance = eyeSize * eyes.tracking.maxTrackingDistance
    local distance = math.sqrt(distanceX^2 + distanceY^2)

    if distance > maxDistance then
      local factor = maxDistance / distance
      distanceX = distanceX * factor
      distanceY = distanceY * factor
    end

    return eyeX + distanceX, eyeY + distanceY
  end

  -- Calculate tracking speed based on touch state
  local leftTrackingSpeed = eyes.tracking.speed
  local rightTrackingSpeed = eyes.tracking.speed

  if leftEye.isTouching then
    leftTrackingSpeed = leftTrackingSpeed * eyes.tracking.touchedSpeedFactor
  end

  if rightEye.isTouching then
    rightTrackingSpeed = rightTrackingSpeed * eyes.tracking.touchedSpeedFactor
  end

  -- Get target positions and update pupil tracking
  local leftTargetX, leftTargetY = calculateTargetPosition(leftEyeX, leftEyeY, leftEye.size)
  local rightTargetX, rightTargetY = calculateTargetPosition(rightEyeX, rightEyeY, rightEye.size)

  leftEye:updatePupilTracking(dt, leftTargetX, leftTargetY, leftTrackingSpeed)
  rightEye:updatePupilTracking(dt, rightTargetX, rightTargetY, rightTrackingSpeed)

  -- Update audio system with current state and cursor position
  audio:update(dt, {
    touching = eyes.stateManager.touching,
    touchingLeft = eyes.eyes.left.isTouching,
    touchingRight = eyes.eyes.right.isTouching
  }, eyes.x, eyes.y)

  -- Update fire module with current mouse position
  fire.update(dt, eyes.x, eyes.y)
end

function eyes.draw()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()

  -- Draw a solid black background first
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

  -- Get shake effect values from state manager
  local shakeX = eyes.stateManager.shake.x
  local shakeY = eyes.stateManager.shake.y

  love.graphics.push()
  love.graphics.translate(shakeX, shakeY)
  background:draw()

  -- Get actual eye positions for shadows
  local leftX, leftY = eyes.eyes.left:getPosition()
  local rightX, rightY = eyes.eyes.right:getPosition()

  -- Draw shadows first so they appear beneath the eyes
  shadows.draw(leftX, leftY, eyes.eyeSize)
  shadows.draw(rightX, rightY, eyes.eyeSize)

  -- Draw eyes with their respective fade values, reflection effects, pupil dilation, and online status
  drawEye(eyes.eyes.left, eyes.isOnline)
  drawEye(eyes.eyes.right, eyes.isOnline)

  -- Draw only the fire effect
  drawFireEffect(eyes.x, eyes.y)

  love.graphics.pop()
end

-- Add cleanup for audio when the scene is exited
function eyes.unload()
  audio:stop()
end

return eyes
