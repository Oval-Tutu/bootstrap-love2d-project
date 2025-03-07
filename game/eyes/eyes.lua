---@class Eyes Module for drawing and managing interactive eyes
local background = require("eyes.background")
local audio = require("eyes.audio")
local fire = require("eyes.fire")
local shadows = require("eyes.shadows")

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
  eyePositions = { left = 0, right = 0, centerY = 0 },

  -- Floating effect configuration
  floating = {
    -- Base floating speed (radians per second)
    speedX = 0.9,
    speedY = 0.9,
    -- Maximum float distance from origin
    amplitudeX = 15,
    amplitudeY = 10,
    -- Phase offset for horizontal and vertical oscillations
    phaseLeftX = 0,
    phaseLeftY = math.pi * 0.5, -- Added phase difference between X and Y
    phaseRightX = math.pi * 0.7, -- Independent right eye phase
    phaseRightY = math.pi * 0.3, -- Independent right eye phase
    -- Time accumulator for animation
    timeX = 0,
    timeY = 0,
    -- Fire attraction parameters
    attractionStrength = 0.08,   -- Reduced from 0.15 for more gradual movement
    attractionRange = 400,       -- Maximum distance at which attraction has an effect
    maxAttractionForce = 0.4,    -- Maximum force of attraction per second
    dampingFactor = 0.85,        -- How quickly attraction velocity decays

    -- Current attraction velocities for each eye
    velocityLeftX = 0,
    velocityLeftY = 0,
    velocityRightX = 0,
    velocityRightY = 0,

    -- Attraction offset (separate from oscillation)
    attractOffsetLeftX = 0,
    attractOffsetLeftY = 0,
    attractOffsetRightX = 0,
    attractOffsetRightY = 0
  },

  -- Current floating offsets for each eye
  floatOffset = {
    leftX = 0,
    leftY = 0,
    rightX = 0,
    rightY = 0
  },

  -- Fade state (0 = normal, 1 = fully touched)
  eyeFadeLeft = 0,
  eyeFadeRight = 0,

  -- Reflection state for fire effects
  reflection = {
    leftIntensity = 0,
    rightIntensity = 0,
    leftX = 0,
    leftY = 0,
    rightX = 0,
    rightY = 0,
    fadeSpeed = 3,      -- How quickly reflection fades in/out
    maxIntensity = 0.9, -- Maximum reflection intensity (increased for visibility)
    minDistance = 80,   -- Minimum distance for reflection to appear
    maxDistance = 350,  -- Distance at which reflection is at minimum intensity
    baseSize = 0.07     -- Base size of reflection as fraction of eye size (smaller)
  },

  -- Pupil dilation state (responds to fire proximity)
  pupilDilation = {
    left = 0,
    right = 0,
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
  online_color = { 1, 0, 0 },
  online_message = "Offline",
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
  green = { 0, 1, 0 },
  darkGrey = { 0.1, 0.1, 0.1 },
  lightPink = { 1, 0.92, 0.92 },
  darkRed = { 0.6, 0, 0 },
  -- Fire-related colors are now in fire module
}

-- Eye state
eyes.state = {
  touching = false,
  touchingLeft = false,
  touchingRight = false
}

-- Private functions defined as locals
---Checks if the mouse is over an eye
---@param eyeX number The x-coordinate of the eye
---@param eyeY number The y-coordinate of the eye
---@param eyeSize number The size of the eye
---@return boolean isOver True if mouse is over the eye
local function isMouseOverEye(eyeX, eyeY, eyeSize)
  local mouseX = love.mouse.getX()
  local mouseY = love.mouse.getY()
  local distance = math.sqrt((mouseX - eyeX) ^ 2 + (mouseY - eyeY) ^ 2)
  return distance < eyeSize
end

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

---Calculates the floating offset for an eye
---@param timeX number Current time accumulator for X axis
---@param timeY number Current time accumulator for Y axis
---@param phaseX number Phase offset for X axis
---@param phaseY number Phase offset for Y axis
---@param amplitudeX number Max amplitude for X axis
---@param amplitudeY number Max amplitude for Y axis
---@param attractionFactor number Factor of attraction towards fire (0-1)
---@param attractionVector table {x, y} normalized vector towards fire
---@return number offsetX Resulting X offset
---@return number offsetY Resulting Y offset
local function calculateFloatingOffset(timeX, timeY, phaseX, phaseY, amplitudeX, amplitudeY, attractionFactor, attractionVector)
  -- Calculate basic floating motion with independent X and Y oscillation
  local floatX = math.sin(timeX + phaseX) * amplitudeX
  local floatY = math.sin(timeY + phaseY) * amplitudeY

  -- Add attraction component
  local attractX = attractionVector.x * attractionFactor * amplitudeX * 1.5
  local attractY = attractionVector.y * attractionFactor * amplitudeY * 1.5

  -- Fixed: attractY now properly uses attractY instead of attractX
  return floatX + attractX, floatY + attractY
end

---Updates the floating effect timing and offsets
---@param dt number Delta time since last frame
---@param eyePositions table Eye positions {left, right, centerY}
---@param floating table Floating configuration and state
---@param mouseX number Current mouse X position
---@param mouseY number Current mouse Y position
---@return table offsets Table with calculated offsets for both eyes
local function updateFloatingEffect(dt, eyePositions, floating, mouseX, mouseY)
  -- Update time accumulators for continuous animation
  floating.timeX = (floating.timeX + dt * floating.speedX) % (2 * math.pi)
  floating.timeY = (floating.timeY + dt * floating.speedY) % (2 * math.pi)

  local offsets = {}

  -- Calculate attraction vectors for both eyes
  local leftAttractionVector = {x = 0, y = 0}
  local rightAttractionVector = {x = 0, y = 0}

  -- Calculate distance to cursor/fire for each eye
  local leftDx = mouseX - (eyePositions.left + floating.attractOffsetLeftX)
  local leftDy = mouseY - (eyePositions.centerY + floating.attractOffsetLeftY)
  local leftDistance = math.sqrt(leftDx * leftDx + leftDy * leftDy)

  local rightDx = mouseX - (eyePositions.right + floating.attractOffsetRightX)
  local rightDy = mouseY - (eyePositions.centerY + floating.attractOffsetRightY)
  local rightDistance = math.sqrt(rightDx * rightDx + rightDy * rightDy)

  -- Apply damping to current velocities
  floating.velocityLeftX = floating.velocityLeftX * floating.dampingFactor
  floating.velocityLeftY = floating.velocityLeftY * floating.dampingFactor
  floating.velocityRightX = floating.velocityRightX * floating.dampingFactor
  floating.velocityRightY = floating.velocityRightY * floating.dampingFactor

  -- Gradually calculate attraction force
  if leftDistance < floating.attractionRange then
    -- Normalize direction vector
    local normalizedLeftX = leftDx / leftDistance
    local normalizedLeftY = leftDy / leftDistance

    -- Calculate attraction strength based on distance (stronger when closer)
    local strengthFactor = 1.0 - (leftDistance / floating.attractionRange)
    local attractForce = strengthFactor * floating.attractionStrength

    -- Apply acceleration to velocity (limited by maxAttractionForce)
    local accelerationX = normalizedLeftX * attractForce
    local accelerationY = normalizedLeftY * attractForce

    floating.velocityLeftX = floating.velocityLeftX + accelerationX * dt
    floating.velocityLeftY = floating.velocityLeftY + accelerationY * dt

    -- Clamp maximum velocity
    local maxVel = floating.maxAttractionForce * dt
    local velLength = math.sqrt(floating.velocityLeftX^2 + floating.velocityLeftY^2)
    if velLength > maxVel then
      local factor = maxVel / velLength
      floating.velocityLeftX = floating.velocityLeftX * factor
      floating.velocityLeftY = floating.velocityLeftY * factor
    end
  end

  -- Apply same velocity-based attraction for right eye
  if rightDistance < floating.attractionRange then
    local normalizedRightX = rightDx / rightDistance
    local normalizedRightY = rightDy / rightDistance

    local strengthFactor = 1.0 - (rightDistance / floating.attractionRange)
    local attractForce = strengthFactor * floating.attractionStrength

    floating.velocityRightX = floating.velocityRightX + normalizedRightX * attractForce * dt
    floating.velocityRightY = floating.velocityRightY + normalizedRightY * attractForce * dt

    -- Clamp maximum velocity
    local maxVel = floating.maxAttractionForce * dt
    local velLength = math.sqrt(floating.velocityRightX^2 + floating.velocityRightY^2)
    if velLength > maxVel then
      local factor = maxVel / velLength
      floating.velocityRightX = floating.velocityRightX * factor
      floating.velocityRightY = floating.velocityRightY * factor
    end
  end

  -- Update attraction offsets using velocities
  floating.attractOffsetLeftX = floating.attractOffsetLeftX + floating.velocityLeftX
  floating.attractOffsetLeftY = floating.attractOffsetLeftY + floating.velocityLeftY
  floating.attractOffsetRightX = floating.attractOffsetRightX + floating.velocityRightX
  floating.attractOffsetRightY = floating.attractOffsetRightY + floating.velocityRightY

  -- Calculate oscillation component
  local leftOscX = math.sin(floating.timeX + floating.phaseLeftX) * floating.amplitudeX
  local leftOscY = math.sin(floating.timeY + floating.phaseLeftY) * floating.amplitudeY
  local rightOscX = math.sin(floating.timeX + floating.phaseRightX) * floating.amplitudeX
  local rightOscY = math.sin(floating.timeY + floating.phaseRightY) * floating.amplitudeY

  -- Combine oscillation with attraction offset
  offsets.leftX = leftOscX + floating.attractOffsetLeftX
  offsets.leftY = leftOscY + floating.attractOffsetLeftY
  offsets.rightX = rightOscX + floating.attractOffsetRightX
  offsets.rightY = rightOscY + floating.attractOffsetRightY

  return offsets
end

---Draws a single eye
---@param eyeX number The x-coordinate of the eye
---@param eyeY number The y-coordinate of the eye
---@param eyeSize number The size of the eye
---@param colors table Color definitions
---@param fadeValue number The fade progress (0-1) from white to pink
---@param reflectionX number X position of the fire reflection
---@param reflectionY number Y position of the fire reflection
---@param reflectionIntensity number Intensity of the fire reflection (0-1)
---@param dilationFactor number Pupil dilation factor (0-1, with 1 being most dilated)
local function drawEye(eyeX, eyeY, eyeSize, colors, fadeValue,
                       reflectionX, reflectionY, reflectionIntensity, dilationFactor)
  -- Interpolate between white and pink based on fade value
  local eyeColor = interpolateColor(colors.white, colors.lightPink, fadeValue)
  local shadedEyeColor = interpolateColor(colors.shadedWhite, colors.lightPink, fadeValue)
  local pupilColor = interpolateColor(colors.blue, colors.darkRed, fadeValue)

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

---Draws the mouse cursor position text and cursor dot
---@param windowWidth number Width of the window
---@param font love.Font The font to use for messages
---@param x number Mouse X position
---@param y number Mouse Y position
---@param colors table Color definitions
local function drawMouseCursor(windowWidth, font, x, y, colors)
  -- Draw fire effect using the fire module
  fire.draw()

  love.graphics.setColor(colors.white)
  local message = i18n("Mouse") .. " (" .. x .. "," .. y .. ")"
  local textWidth = font:getWidth(message)
  local centerX = (windowWidth / 2) - (textWidth / 2)
  love.graphics.print(message, centerX, 32)
end

---Draws the online status message
---@param windowWidth number Width of the window
---@param font love.Font The font to use for messages
---@param online_color table Color for online status
---@param online_message string Online status message
local function drawOnlineStatus(windowWidth, font, online_color, online_message)
  love.graphics.setColor(online_color)
  local textWidth = font:getWidth(online_message)
  local centerX = (windowWidth / 2) - (textWidth / 2)
  love.graphics.print(online_message, centerX, 76)
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

---Updates the eye state based on input and cursor position
---@param state table Current eye state reference
---@param eyePositions table Table with eye position data
---@param eyeSize number The size of the eye
---@param floatOffset table Floating offsets for each eye
local function updateEyeState(state, eyePositions, eyeSize, floatOffset)
  -- Check touches for each eye individually, using floating positions
  state.touchingLeft = isMouseOverEye(
    eyePositions.left + floatOffset.leftX,
    eyePositions.centerY + floatOffset.leftY,
    eyeSize
  )
  state.touchingRight = isMouseOverEye(
    eyePositions.right + floatOffset.rightX,
    eyePositions.centerY + floatOffset.rightY,
    eyeSize
  )
  state.touching = state.touchingLeft or state.touchingRight
end

---Updates the shake effect when mouse is over eyes
---@param eyePositions table Table with eye position data
---@param eyeSize number The size of the eye
---@param shakeAmount number Maximum shake amount
---@return number shakeX Resulting X shake value
---@return number shakeY Resulting Y shake value
local function updateShakeEffect(eyePositions, eyeSize, shakeAmount)
  if isMouseOverEye(eyePositions.left, eyePositions.centerY, eyeSize) or
     isMouseOverEye(eyePositions.right, eyePositions.centerY, eyeSize) then
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

  if checkOnlineStatus() then
    eyes.online_color = eyes.colors.green
    eyes.online_message = "Online"
  end

  -- Load textures
  eyes.bloodVeinsTexture = love.graphics.newImage("eyes/gfx/blood_veins_100.png")
  eyes.irisTexture = love.graphics.newImage("eyes/gfx/iris.png")
  eyes.pupilTexture = love.graphics.newImage("eyes/gfx/pupil.png")

  -- Create eye shader for spherical gradient effect
  local shaderCode = [[
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
  ]]
  eyes.eyeShader = love.graphics.newShader(shaderCode)

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
  eyes.eyePositions = {
    left = leftEyeX,
    right = rightEyeX,
    centerY = centerY
  }

  -- Update floating effect before eye state check
  local floatOffsets = updateFloatingEffect(dt, eyes.eyePositions, eyes.floating, eyes.x, eyes.y)
  eyes.floatOffset.leftX = floatOffsets.leftX
  eyes.floatOffset.leftY = floatOffsets.leftY
  eyes.floatOffset.rightX = floatOffsets.rightX
  eyes.floatOffset.rightY = floatOffsets.rightY

  -- Update eye state and process touch detection with floating positions
  updateEyeState(eyes.state, eyes.eyePositions, eyes.eyeSize, eyes.floatOffset)

  -- Update fade values based on touch state with smooth transitions
  if eyes.state.touchingLeft then
    eyes.eyeFadeLeft = math.min(1, eyes.eyeFadeLeft + dt * eyes.fadeSpeed)
  else
    eyes.eyeFadeLeft = math.max(0, eyes.eyeFadeLeft - dt * eyes.fadeSpeed)
  end

  if eyes.state.touchingRight then
    eyes.eyeFadeRight = math.min(1, eyes.eyeFadeRight + dt * eyes.fadeSpeed)
  else
    eyes.eyeFadeRight = math.max(0, eyes.eyeFadeRight - dt * eyes.fadeSpeed)
  end

  -- Update audio system with current state and cursor position
  audio:update(dt, eyes.state, eyes.x, eyes.y)

  -- Update fire module with current mouse position
  fire.update(dt, eyes.x, eyes.y)

  -- Calculate target reflection properties using the fire module
  -- Use the actual floating eye positions for reflection calculations
  local leftIntensityTarget, rightIntensityTarget, leftX, leftY, rightX, rightY =
    fire.calculateReflectionProperties(
      eyes.x, eyes.y,
      leftEyeX + eyes.floatOffset.leftX,
      rightEyeX + eyes.floatOffset.rightX,
      centerY + eyes.floatOffset.leftY, -- Using left Y offset for the left eye
      eyes.eyeSize, eyes.reflection
    )

  -- Smoothly transition reflection intensity
  eyes.reflection.leftIntensity = eyes.reflection.leftIntensity +
    (leftIntensityTarget - eyes.reflection.leftIntensity) * dt * eyes.reflection.fadeSpeed

  eyes.reflection.rightIntensity = eyes.reflection.rightIntensity +
    (rightIntensityTarget - eyes.reflection.rightIntensity) * dt * eyes.reflection.fadeSpeed

  -- Update reflection positions
  eyes.reflection.leftX = leftX
  eyes.reflection.leftY = leftY
  eyes.reflection.rightX = rightX
  eyes.reflection.rightY = rightY

  -- Calculate target pupil dilation based on fire proximity using the fire module
  -- Use the actual floating eye positions for dilation calculations
  local leftDilationTarget, rightDilationTarget =
    fire.calculatePupilDilation(
      eyes.x, eyes.y,
      leftEyeX + eyes.floatOffset.leftX,
      rightEyeX + eyes.floatOffset.rightX,
      centerY + eyes.floatOffset.leftY, -- Using left Y offset for the left eye
      eyes.pupilDilation
    )

  -- Smoothly transition pupil dilation
  eyes.pupilDilation.left = eyes.pupilDilation.left +
    (leftDilationTarget - eyes.pupilDilation.left) * dt * eyes.pupilDilation.fadeSpeed

  eyes.pupilDilation.right = eyes.pupilDilation.right +
    (rightDilationTarget - eyes.pupilDilation.right) * dt * eyes.pupilDilation.fadeSpeed
end

function eyes.draw()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local font = love.graphics.getFont()

  -- Draw a solid black background first
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

  -- Calculate shake effect
  eyes.shakeX, eyes.shakeY = updateShakeEffect(eyes.eyePositions, eyes.eyeSize, eyes.shakeAmount)

  love.graphics.push()
  love.graphics.translate(eyes.shakeX, eyes.shakeY)
  background:draw()

  -- Draw shadows first so they appear beneath the eyes
  shadows.draw(
    eyes.eyePositions.left + eyes.floatOffset.leftX,
    eyes.eyePositions.centerY + eyes.floatOffset.leftY,
    eyes.eyeSize
  )

  shadows.draw(
    eyes.eyePositions.right + eyes.floatOffset.rightX,
    eyes.eyePositions.centerY + eyes.floatOffset.rightY,
    eyes.eyeSize
  )

  -- Draw eyes with their respective fade values, reflection effects, and pupil dilation
  drawEye(
    eyes.eyePositions.left + eyes.floatOffset.leftX, eyes.eyePositions.centerY + eyes.floatOffset.leftY,
    eyes.eyeSize, eyes.colors,
    eyes.eyeFadeLeft,
    eyes.reflection.leftX, eyes.reflection.leftY, eyes.reflection.leftIntensity,
    eyes.pupilDilation.left
  )

  drawEye(
    eyes.eyePositions.right + eyes.floatOffset.rightX, eyes.eyePositions.centerY + eyes.floatOffset.rightY,
    eyes.eyeSize, eyes.colors,
    eyes.eyeFadeRight,
    eyes.reflection.rightX, eyes.reflection.rightY, eyes.reflection.rightIntensity,
    eyes.pupilDilation.right
  )

  -- Draw cursor and online status
  drawMouseCursor(windowWidth, font, eyes.x, eyes.y, eyes.colors)
  drawOnlineStatus(windowWidth, font, eyes.online_color, eyes.online_message)

  love.graphics.pop()
end

-- Add cleanup for audio when the scene is exited
function eyes.unload()
  audio:stop()
end

return eyes
