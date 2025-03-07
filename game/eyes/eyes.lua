---@class Eyes Module for drawing and managing interactive eyes
local overlayStats = require("lib.overlayStats")
local background = require("eyes.background")

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

  -- Particle systems
  fireSystem = nil,    -- Outer erratic flames
  coreSystem = nil,    -- Stable inner core
  sparkSystem = nil,   -- Occasional bright sparks
  smokeSystem = nil,   -- Smoke effect

  -- Timer for spark emission control
  sparkTimer = 0,
  sparkInterval = 0.15,

  -- Sound effects
  sounds = {},

  -- Ambient sound
  ambientFireSound = nil,

  -- Sound state tracking
  soundState = {
    currentSound = nil,
    soundPlaying = false,
    soundJustFinished = false,
    lastTouchTime = 0,
    touchCooldown = 0.5,
    lastTouchingState = false
  }
}

-- Constants - Define colors before they're used in functions
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
  fire = {
    { 1, 0.7, 0, 0.8 },   -- golden orange
    { 1, 0.4, 0, 0.7 },   -- orange
    { 1, 0.2, 0, 0.5 },   -- red-orange
    { 0.7, 0.1, 0, 0.3 }, -- dark red
    { 0.4, 0, 0, 0 }      -- fade out to transparent
  },
  -- Core fire colors (brighter and more intense)
  corefire = {
    { 1, 1, 0.8, 0.9 },   -- bright yellow
    { 1, 0.8, 0.2, 0.7 }, -- yellow-orange
    { 1, 0.6, 0, 0.5 },   -- orange
    { 1, 0.3, 0, 0.3 },   -- reddish-orange
    { 0.8, 0.1, 0 }    -- fade out
  },
  -- Spark colors (bright and short-lived)
  spark = {
    { 1, 1, 1, 1 },     -- white
    { 1, 1, 0.6, 0.8 }, -- bright yellow
    { 1, 0.3, 0, 0.3 },   -- reddish-orange
    { 1, 0.6, 0.1, 0 }  -- fade to transparent
  },
  -- Smoke colors for the smoke particle system
  smoke = {
    { 0.5, 0.5, 0.5, 0 },   -- transparent to start
    { 0.4, 0.4, 0.4, 0.2 }, -- light gray with some transparency
    { 0.3, 0.3, 0.3, 0.1 }, -- mid gray, fading
    { 0.2, 0.2, 0.2, 0 }    -- dark gray, completely transparent
  },
  -- Fire reflection color in the eyes
  reflection = {
    { 1, 0.95, 0.8, 1.0 },  -- Bright white-yellow
    { 1, 0.8, 0.3, 0.7 }    -- Fading orange-yellow
  }
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

---Loads all available "aargh" sound effects
---@return table An array of sound sources
local function loadSoundEffects()
  local sounds = {}
  for i = 1, 7 do
    local soundPath = "eyes/sfx/aargh" .. i .. ".ogg"
    table.insert(sounds, love.audio.newSource(soundPath, "static"))
  end
  return sounds
end

---Loads the ambient fire sound effect as dual mono sources for true stereo mixing
---@return table Table containing left and right channel fire sounds
local function loadAmbientFireSound()
  local soundPath = "eyes/sfx/fire.ogg"
  -- Create two instances of the sound
  local leftChannel = love.audio.newSource(soundPath, "stream")
  local rightChannel = love.audio.newSource(soundPath, "stream")

  -- Configure both for looping
  leftChannel:setLooping(true)
  rightChannel:setLooping(true)

  -- Hard pan each source to its respective side
  leftChannel:setPosition(-1, 0, 0)
  rightChannel:setPosition(1, 0, 0)

  return {
    left = leftChannel,
    right = rightChannel
  }
end

---Plays a random "aargh" sound effect
---@param sounds table Array of sound sources
local function playRandomSound(sounds)
  -- Select a random sound
  local index = love.math.random(1, #sounds)
  local sound = sounds[index]

  -- Stop any previous instance that might be playing
  sound:stop()

  -- Set up finish properties
  sound:setLooping(false)

  -- Play the sound
  sound:play()

  return sound
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
      -- Save current blend mode
      local prevBlendMode = love.graphics.getBlendMode()

      -- Calculate the angle from pupil to cursor (fire source)
      local fireAngle = math.atan2(love.mouse.getY() - pupilY, love.mouse.getX() - pupilX)

      -- Calculate the opposite angle (pupil edge away from fire)
      local glintAngle = fireAngle + math.pi

      -- Calculate the pupil radius and position glint on its edge
      local pupilRadius = eyeSize * 0.2 -- Approximation of pupil radius
      local glintX = pupilX + math.cos(glintAngle) * pupilRadius
      local glintY = pupilY + math.sin(glintAngle) * pupilRadius

      -- Calculate glint size - significantly smaller than before
      local baseGlintSize = eyeSize * eyes.reflection.baseSize
      local glintSize = baseGlintSize * actualIntensity

      -- Use additive blending for glow effect
      love.graphics.setBlendMode("add")

      -- Draw the main glint
      love.graphics.setColor(1, 0.95, 0.8, 0.8 * actualIntensity)
      love.graphics.circle("fill", glintX, glintY, glintSize)

      -- Add a brighter core
      love.graphics.setColor(1, 1, 1, 0.9 * actualIntensity)
      love.graphics.circle("fill", glintX, glintY, glintSize * 0.6)

      -- Restore previous blend mode
      love.graphics.setBlendMode(prevBlendMode)
    end
  end
end

---Draws the mouse cursor position text and cursor dot
---@param windowWidth number Width of the window
---@param font love.Font The font to use for messages
---@param x number Mouse X position
---@param y number Mouse Y position
---@param colors table Color definitions
---@param fireSystem love.ParticleSystem The outer fire particle system
---@param coreSystem love.ParticleSystem The core fire particle system
---@param sparkSystem love.ParticleSystem The spark particle system
---@param smokeSystem love.ParticleSystem The smoke particle system
local function drawMouseCursor(windowWidth, font, x, y, colors, fireSystem, coreSystem, sparkSystem, smokeSystem)
  -- Save current blend mode
  local prevBlendMode = love.graphics.getBlendMode()

  -- Draw the layers in back-to-front order

  -- 1. Smoke behind everything (alpha blending)
  love.graphics.setBlendMode("alpha")
  love.graphics.draw(smokeSystem)

  -- 2. Core fire on top of outer fire (brighter)
  love.graphics.draw(coreSystem)

  -- 3. Outer fire with additive blending
  love.graphics.setBlendMode("add")
  love.graphics.draw(fireSystem)

  -- 4. Sparks on top of everything (brightest)
  love.graphics.draw(sparkSystem)

  -- Restore previous blend mode
  love.graphics.setBlendMode(prevBlendMode)

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
local function updateEyeState(state, eyePositions, eyeSize)
  -- Check touches for each eye individually
  state.touchingLeft = isMouseOverEye(eyePositions.left, eyePositions.centerY, eyeSize)
  state.touchingRight = isMouseOverEye(eyePositions.right, eyePositions.centerY, eyeSize)
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

---Configures a particle system with common properties
---@param particleSystem love.ParticleSystem The particle system to configure
---@param config table Configuration parameters
local function configureParticleSystem(particleSystem, config)
  particleSystem:setParticleLifetime(config.lifetime.min, config.lifetime.max)
  particleSystem:setEmissionRate(config.emissionRate)
  particleSystem:setSizeVariation(config.sizeVariation)
  particleSystem:setLinearAcceleration(config.acceleration.minX, config.acceleration.minY,
                                       config.acceleration.maxX, config.acceleration.maxY)
  particleSystem:setSpeed(config.speed.min, config.speed.max)
  particleSystem:setSizes(unpack(config.sizes))
  particleSystem:setDirection(config.direction)
  particleSystem:setSpread(config.spread)
  particleSystem:setRadialAcceleration(config.radial.min, config.radial.max)
  particleSystem:setTangentialAcceleration(config.tangential.min, config.tangential.max)
  particleSystem:setColors(unpack(config.colors))

  if config.spin then
    particleSystem:setSpin(config.spin.min, config.spin.max)
    particleSystem:setSpinVariation(config.spinVariation or 1)
  end

  if config.autostart then
    particleSystem:start()
  end

  return particleSystem
end

---Creates and initializes the particle systems for the cursor flame effect
---@param colors table The color definitions to use for particles
---@return love.ParticleSystem The outer fire particle system
---@return love.ParticleSystem The core fire particle system
---@return love.ParticleSystem The spark particle system
---@return love.ParticleSystem The smoke particle system
local function initParticleSystem(colors)
  -- Create flame particle image
  local particleImg = love.graphics.newCanvas(32, 32)
  love.graphics.setCanvas(particleImg)
  love.graphics.clear()

  -- Enable antialiasing and draw a teardrop/flame shape
  local prevLineStyle = love.graphics.getLineStyle()
  love.graphics.setLineStyle("smooth")
  love.graphics.setColor(1, 1, 1)

  -- Create a teardrop shape (narrow at top, wider at bottom)
  local points = {}
  local centerX, centerY = 16, 16
  for i = 0, 32 do
    local angle = (i / 32) * math.pi * 2
    -- Modify radius to create teardrop shape
    local radius = 14 * (1 - 0.3 * math.sin(angle)) -- Slightly narrower at top
    local x = centerX + radius * math.cos(angle)
    local y = centerY + radius * math.sin(angle) * 1.2 -- Stretch vertically
    table.insert(points, x)
    table.insert(points, y)
  end
  love.graphics.polygon("fill", unpack(points))

  -- Add glow effect
  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.circle("fill", 16, 16, 16)

  love.graphics.setLineStyle(prevLineStyle)
  love.graphics.setCanvas()

  -- Create spark particle image (smaller, brighter)
  local sparkImg = love.graphics.newCanvas(16, 16)
  love.graphics.setCanvas(sparkImg)
  love.graphics.clear()
  love.graphics.setLineStyle("smooth")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle("fill", 8, 8, 6)
  love.graphics.setColor(1, 1, 0.8, 0.6)
  love.graphics.circle("fill", 8, 8, 8)
  love.graphics.setLineStyle(prevLineStyle)
  love.graphics.setCanvas()

  -- 1. OUTER FIRE SYSTEM - More erratic, dancing flames
  local fireSystem = love.graphics.newParticleSystem(particleImg, 100)
  configureParticleSystem(fireSystem, {
    lifetime = { min = 0.5, max = 1.2 },
    emissionRate = 70,
    sizeVariation = 0.6,
    acceleration = { minX = -15, minY = -80, maxX = 15, maxY = -100 },
    speed = { min = 15, max = 60 },
    sizes = { 0.2, 0.7, 0.5, 0.2 },
    direction = -math.pi/2,
    spread = math.pi/3,
    radial = { min = -10, max = 10 },
    tangential = { min = -30, max = 30 },
    colors = colors.fire,
    spin = { min = -0.5, max = 0.5 },
    spinVariation = 1,
    autostart = true
  })

  -- 2. CORE FIRE SYSTEM - Stable inner core
  local coreSystem = love.graphics.newParticleSystem(particleImg, 50)
  configureParticleSystem(coreSystem, {
    lifetime = { min = 0.3, max = 0.8 },
    emissionRate = 50,
    sizeVariation = 0.3,
    acceleration = { minX = -5, minY = -100, maxX = 5, maxY = -130 },
    speed = { min = 20, max = 40 },
    sizes = { 0.4, 0.6, 0.3, 0.1 },
    direction = -math.pi/2,
    spread = math.pi/8,
    radial = { min = -2, max = 2 },
    tangential = { min = -5, max = 5 },
    colors = colors.corefire,
    autostart = true
  })

  -- 3. SPARK SYSTEM - Occasional bright particles shooting upward
  local sparkSystem = love.graphics.newParticleSystem(sparkImg, 30)
  configureParticleSystem(sparkSystem, {
    lifetime = { min = 0.5, max = 1.5 },
    emissionRate = 0, -- Controlled manually
    sizeVariation = 0.5,
    acceleration = { minX = -20, minY = -200, maxX = 20, maxY = -300 },
    speed = { min = 50, max = 150 },
    sizes = { 0.6, 0.4, 0.2, 0 },
    direction = -math.pi/2,
    spread = math.pi/2,
    radial = { min = -50, max = 50 },
    tangential = { min = -20, max = 20 },
    colors = colors.spark,
    spin = { min = -2, max = 2 },
    spinVariation = 1,
    autostart = false
  })

  -- 4. SMOKE SYSTEM
  local smokeSystem = love.graphics.newParticleSystem(particleImg, 40)
  smokeSystem:setOffset(love.math.random(-5,5), love.math.random(60,90))
  configureParticleSystem(smokeSystem, {
    lifetime = { min = 1.0, max = 2.5 },
    emissionRate = 15,
    sizeVariation = 0.8,
    acceleration = { minX = -5, minY = -20, maxX = 5, maxY = -40 },
    speed = { min = 5, max = 15 },
    sizes = { 0.1, 0.6, 1.0, 1.3 },
    direction = -math.pi/2,
    spread = math.pi/2,
    radial = { min = -10, max = 10 },
    tangential = { min = -20, max = 20 },
    colors = colors.smoke,
    spin = { min = 0.1, max = 0.8 },
    spinVariation = 1,
    autostart = true
  })

  return fireSystem, coreSystem, sparkSystem, smokeSystem
end

---Updates the sound state based on eye touching
---@param state table Current eye state
---@param sounds table Array of sound sources
---@param soundState table Sound state tracking
local function updateSoundState(state, sounds, soundState)
  local wasTouching = soundState.lastTouchingState
  local currentTime = love.timer.getTime()
  local cooldownElapsed = (currentTime - soundState.lastTouchTime) > soundState.touchCooldown

  -- Play a sound if:
  -- 1. We just started touching an eye, OR
  -- 2. A sound just finished and we're still touching an eye
  -- AND in both cases: No sound is playing and cooldown has elapsed
  if ((state.touching and not wasTouching) or
      (state.touching and soundState.soundJustFinished)) and
     not soundState.soundPlaying and cooldownElapsed then

    soundState.soundPlaying = true
    soundState.soundJustFinished = false -- Reset flag after using it
    soundState.lastTouchTime = currentTime

    -- Play a random sound and keep track of it
    soundState.currentSound = playRandomSound(sounds)
  end

  -- If we're not touching anymore, reset the finished sound flag
  if not state.touching then
    soundState.soundJustFinished = false
  end

  -- Save current touching state for next frame
  soundState.lastTouchingState = state.touching
end

---Updates the audio system's volume and position based on cursor position
---@param ambientFireSound table Table containing left and right channel fire sounds
---@param x number Current cursor X position
---@param y number Current cursor Y position
---@param windowWidth number Width of the window
---@param windowHeight number Height of the window
local function updateAudioSystem(ambientFireSound, x, y, windowWidth, windowHeight)
  if not ambientFireSound then return end

  -- Create a balanced stereo effect with smooth crossfade
  local normalizedX = x / windowWidth

  -- Calculate smooth volume levels for each channel
  -- Left channel is louder when cursor is left (normalizedX near 0)
  -- Right channel is louder when cursor is right (normalizedX near 1)
  -- Both channels maintain at least 30% volume for continuous stereo sound
  local leftVolume = math.max(0.3, 1.0 - (normalizedX * 0.7))
  local rightVolume = math.max(0.3, 0.3 + (normalizedX * 0.7))

  -- Calculate overall volume based on proximity to center
  local centerX = windowWidth / 2
  local centerY = windowHeight / 2
  local distanceFromCenterX = 1.0 - math.abs(x - centerX) / centerX
  local distanceFromCenterY = 1.0 - math.abs(y - centerY) / centerY
  local volumeMultiplier = distanceFromCenterX * distanceFromCenterY
  local baseVolume = 0.5 + (volumeMultiplier * 0.7)

  -- Apply volumes to both channels
  ambientFireSound.left:setVolume(leftVolume * baseVolume)
  ambientFireSound.right:setVolume(rightVolume * baseVolume)
end

---Calculates reflection properties for the eyes based on cursor position
---@param mouseX number Current mouse X position
---@param mouseY number Current mouse Y position
---@param leftEyeX number X position of left eye
---@param rightEyeX number X position of right eye
---@param eyeY number Y position of both eyes
---@param eyeSize number Size of eyes
---@param config table Reflection configuration parameters
---@return number leftIntensity Intensity for left eye reflection (0-1)
---@return number rightIntensity Intensity for right eye reflection (0-1)
---@return number leftX X position for left eye reflection
---@return number leftY Y position for left eye reflection
---@return number rightX X position for right eye reflection
---@return number rightY Y position for right eye reflection
local function calculateReflectionProperties(mouseX, mouseY, leftEyeX, rightEyeX, eyeY, eyeSize, config)
  -- Calculate distances to each eye
  local distanceToLeft = math.sqrt((mouseX - leftEyeX)^2 + (mouseY - eyeY)^2)
  local distanceToRight = math.sqrt((mouseX - rightEyeX)^2 + (mouseY - eyeY)^2)

  -- Calculate intensity based on distance (closer = more intense)
  local leftIntensity = 0
  local rightIntensity = 0

  if distanceToLeft < config.maxDistance then
    leftIntensity = math.max(0, math.min(config.maxIntensity,
      config.maxIntensity * (1 - (distanceToLeft - config.minDistance) /
      (config.maxDistance - config.minDistance))))

    -- Ensure minimum visibility when fire is present
    leftIntensity = math.max(leftIntensity, 0.2)
  end

  if distanceToRight < config.maxDistance then
    rightIntensity = math.max(0, math.min(config.maxIntensity,
      config.maxIntensity * (1 - (distanceToRight - config.minDistance) /
      (config.maxDistance - config.minDistance))))

    -- Ensure minimum visibility when fire is present
    rightIntensity = math.max(rightIntensity, 0.2)
  end

  -- Note: we're not using these positions directly anymore for drawing the glint
  -- but we still need to return something for the existing API
  local leftX = leftEyeX
  local leftY = eyeY
  local rightX = rightEyeX
  local rightY = eyeY

  return leftIntensity, rightIntensity, leftX, leftY, rightX, rightY
end

---Calculates pupil dilation based on fire proximity to each eye
---@param mouseX number Current mouse X position
---@param mouseY number Current mouse Y position
---@param leftEyeX number X position of left eye
---@param rightEyeX number X position of right eye
---@param eyeY number Y position of both eyes
---@param config table Pupil dilation configuration parameters
---@return number leftDilation Dilation factor for left eye (0-1)
---@return number rightDilation Dilation factor for right eye (0-1)
local function calculatePupilDilation(mouseX, mouseY, leftEyeX, rightEyeX, eyeY, config)
  -- Calculate distances to each eye
  local distanceToLeft = math.sqrt((mouseX - leftEyeX)^2 + (mouseY - eyeY)^2)
  local distanceToRight = math.sqrt((mouseX - rightEyeX)^2 + (mouseY - eyeY)^2)

  -- Calculate dilation factors based on distance (closer = more dilated)
  local leftDilation = 0
  local rightDilation = 0

  if distanceToLeft < config.maxDistance then
    leftDilation = math.max(0, math.min(1,
      1 - (distanceToLeft - config.minDistance) /
      (config.maxDistance - config.minDistance)))
  end

  if distanceToRight < config.maxDistance then
    rightDilation = math.max(0, math.min(1,
      1 - (distanceToRight - config.minDistance) /
      (config.maxDistance - config.minDistance)))
  end

  return leftDilation, rightDilation
end

---Loads resources and initializes the eyes
function eyes.load()
  -- Initialize the parallax background
  background:load()

  if checkOnlineStatus() then
    eyes.online_color = eyes.colors.green
    eyes.online_message = "Online"
  end

  -- Load blood veins texture
  eyes.bloodVeinsTexture = love.graphics.newImage("eyes/gfx/blood_veins_100.png")

  -- Load eye textures
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

  -- Initialize the particle systems - pass colors as parameter
  eyes.fireSystem, eyes.coreSystem, eyes.sparkSystem, eyes.smokeSystem = initParticleSystem(eyes.colors)

  -- Register particle systems with overlayStats
  overlayStats.registerParticleSystem(eyes.fireSystem)
  overlayStats.registerParticleSystem(eyes.coreSystem)
  overlayStats.registerParticleSystem(eyes.sparkSystem)
  overlayStats.registerParticleSystem(eyes.smokeSystem)

  -- Load sound effects
  eyes.sounds = loadSoundEffects()

  -- Load and start playing the ambient fire sounds (true stereo)
  eyes.ambientFireSound = loadAmbientFireSound()
  eyes.ambientFireSound.left:play()
  eyes.ambientFireSound.right:play()

  love.graphics.setFont(love.graphics.newFont(42))
  love.mouse.setVisible(false)
end

function eyes.update(dt)
  -- Update the parallax background
  background:update(dt)

  eyes.x, eyes.y = love.mouse.getPosition()
  eyes.x = math.floor(eyes.x)
  eyes.y = math.floor(eyes.y)
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()

  -- Calculate eye positions once per frame
  local leftEyeX, rightEyeX, centerY = calculateEyePositions(windowWidth, windowHeight, eyes.eyeSpacing)
  eyes.eyePositions = {
    left = leftEyeX,
    right = rightEyeX,
    centerY = centerY
  }

  -- Update eye state and process touch detection
  updateEyeState(eyes.state, eyes.eyePositions, eyes.eyeSize)

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

  updateAudioSystem(eyes.ambientFireSound, eyes.x, eyes.y, windowWidth, windowHeight)

  -- Update particle systems
  eyes.fireSystem:update(dt)
  eyes.fireSystem:setPosition(eyes.x, eyes.y)

  eyes.coreSystem:update(dt)
  eyes.coreSystem:setPosition(eyes.x, eyes.y)

  eyes.smokeSystem:update(dt)
  eyes.smokeSystem:setPosition(eyes.x, eyes.y)

  eyes.sparkSystem:update(dt)
  eyes.sparkSystem:setPosition(eyes.x, eyes.y)

  -- Spark emission control - randomly emit sparks
  eyes.sparkTimer = eyes.sparkTimer + dt
  if eyes.sparkTimer >= eyes.sparkInterval then
    -- Reset timer and set a random interval for next spark
    eyes.sparkTimer = 0
    eyes.sparkInterval = love.math.random(0.05, 0.3)

    -- Emit a random number of sparks in a burst
    eyes.sparkSystem:emit(love.math.random(1, 5))
  end

  -- Check sound state - if we have a current sound, check if it's still playing
  if eyes.soundState.currentSound then
    if not eyes.soundState.currentSound:isPlaying() then
      -- Sound finished playing
      eyes.soundState.currentSound = nil
      eyes.soundState.soundPlaying = false
      eyes.soundState.soundJustFinished = true -- Set flag when sound finishes
    end
  end

  -- Update sound based on eye state
  updateSoundState(eyes.state, eyes.sounds, eyes.soundState)

  -- Calculate target reflection properties
  local leftIntensityTarget, rightIntensityTarget, leftX, leftY, rightX, rightY =
    calculateReflectionProperties(
      eyes.x, eyes.y,
      leftEyeX, rightEyeX, centerY,
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

  -- Calculate target pupil dilation based on fire proximity
  local leftDilationTarget, rightDilationTarget =
    calculatePupilDilation(
      eyes.x, eyes.y,
      leftEyeX, rightEyeX, centerY,
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

  -- Draw the parallax background
  background:draw()

  -- Calculate shake effect
  eyes.shakeX, eyes.shakeY = updateShakeEffect(eyes.eyePositions, eyes.eyeSize, eyes.shakeAmount)

  love.graphics.push()
  love.graphics.translate(eyes.shakeX, eyes.shakeY)

  -- Draw eyes with their respective fade values, reflection effects, and pupil dilation
  drawEye(
    eyes.eyePositions.left, eyes.eyePositions.centerY,
    eyes.eyeSize, eyes.colors,
    eyes.eyeFadeLeft,
    eyes.reflection.leftX, eyes.reflection.leftY, eyes.reflection.leftIntensity,
    eyes.pupilDilation.left
  )

  drawEye(
    eyes.eyePositions.right, eyes.eyePositions.centerY,
    eyes.eyeSize, eyes.colors,
    eyes.eyeFadeRight,
    eyes.reflection.rightX, eyes.reflection.rightY, eyes.reflection.rightIntensity,
    eyes.pupilDilation.right
  )

  -- Draw cursor and online status
  drawMouseCursor(windowWidth, font, eyes.x, eyes.y, eyes.colors,
                  eyes.fireSystem, eyes.coreSystem, eyes.sparkSystem, eyes.smokeSystem)
  drawOnlineStatus(windowWidth, font, eyes.online_color, eyes.online_message)

  love.graphics.pop()
end

return eyes
