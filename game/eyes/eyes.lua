---@class Eyes Module for drawing and managing interactive eyes
local overlayStats = require("lib.overlayStats")

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

  -- Blood veins texture
  bloodVeinsTexture = nil,

  -- Eye textures
  irisTexture = nil,
  pupilTexture = nil,

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
  }
}

-- Eye state
eyes.state = {
  leftEyeWinking = false,
  rightEyeWinking = false,
  bothBlinking = false,
  touching = false,
  touchingLeft = false, -- Track left eye touch specifically
  touchingRight = false -- Track right eye touch specifically
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
---@param isWinking boolean Whether the eye is winking
---@param eyeSize number The size of the eye
---@param colors table Color definitions
---@param fadeValue number The fade progress (0-1) from white to pink
local function drawEye(eyeX, eyeY, isWinking, eyeSize, colors, fadeValue)
  -- Interpolate between white and pink based on fade value
  local eyeColor = interpolateColor(colors.white, colors.lightPink, fadeValue)
  local pupilColor = interpolateColor(colors.blue, colors.darkRed, fadeValue)

  -- Draw the eye base with interpolated color
  love.graphics.setColor(eyeColor)
  love.graphics.circle("fill", eyeX, eyeY, eyeSize)

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

  -- Draw either the winking line or the pupil
  if isWinking then
    love.graphics.setColor(pupilColor)
    love.graphics.setLineWidth(8)
    love.graphics.line(eyeX - eyeSize, eyeY, eyeX + eyeSize, eyeY)
  else
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
      -- Pupil should be smaller than iris
      local pupilScale = (eyeSize * 0.7) / 512

      -- Draw pupil with original color
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(
        eyes.pupilTexture,
        pupilX, pupilY,
        0,                -- no rotation
        pupilScale, pupilScale,
        256, 256         -- center of 512x512 texture
      )
    end
  end
end

---Draws status messages based on eye state
---@param windowWidth number Width of the window
---@param windowHeight number Height of the window
---@param font love.Font The font to use for messages
---@param state table Current eye state
---@param colors table Color definitions
local function drawStatusMessages(windowWidth, windowHeight, font, state, colors)
  local padding = 128

  -- Draw blinking/winking messages
  if state.bothBlinking then
    love.graphics.setColor(colors.purple)
    local text = i18n("Blink")
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (windowWidth - textWidth) / 2, padding)
  else
    love.graphics.setColor(colors.yellow)
    if state.leftEyeWinking then
      local text = i18n("Left Eye") .. " " .. i18n("Wink")
      love.graphics.print(text, padding, padding)
    end
    if state.rightEyeWinking then
      local text = i18n("Right Eye") .. " " .. i18n("Wink")
      local textWidth = font:getWidth(text)
      love.graphics.print(text, windowWidth - textWidth - padding, padding)
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
  local leftButton = love.mouse.isDown(1)
  local rightButton = love.mouse.isDown(2)
  local middleButton = love.mouse.isDown(3)

  state.bothBlinking = middleButton or (leftButton and rightButton)
  state.leftEyeWinking = state.bothBlinking or (leftButton and not state.bothBlinking)
  state.rightEyeWinking = state.bothBlinking or (rightButton and not state.bothBlinking)

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

---Loads resources and initializes the eyes
function eyes.load()
  if checkOnlineStatus() then
    eyes.online_color = eyes.colors.green
    eyes.online_message = "Online"
  end

  -- Load blood veins texture
  eyes.bloodVeinsTexture = love.graphics.newImage("eyes/gfx/blood_veins_100.png")

  -- Load eye textures
  eyes.irisTexture = love.graphics.newImage("eyes/gfx/iris.png")
  eyes.pupilTexture = love.graphics.newImage("eyes/gfx/pupil.png")

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
end

function eyes.draw()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local font = love.graphics.getFont()

  -- Draw background
  love.graphics.setColor(eyes.colors.darkGrey)
  love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

  -- Calculate shake effect
  eyes.shakeX, eyes.shakeY = updateShakeEffect(eyes.eyePositions, eyes.eyeSize, eyes.shakeAmount)

  love.graphics.push()
  love.graphics.translate(eyes.shakeX, eyes.shakeY)

  -- Draw eyes with their respective fade values
  drawEye(eyes.eyePositions.left, eyes.eyePositions.centerY, eyes.state.leftEyeWinking,
          eyes.eyeSize, eyes.colors, eyes.eyeFadeLeft)
  drawEye(eyes.eyePositions.right, eyes.eyePositions.centerY, eyes.state.rightEyeWinking,
          eyes.eyeSize, eyes.colors, eyes.eyeFadeRight)

  drawStatusMessages(windowWidth, windowHeight, font, eyes.state, eyes.colors)
  drawMouseCursor(windowWidth, font, eyes.x, eyes.y, eyes.colors,
                  eyes.fireSystem, eyes.coreSystem, eyes.sparkSystem, eyes.smokeSystem)
  drawOnlineStatus(windowWidth, font, eyes.online_color, eyes.online_message)

  love.graphics.pop()
end

return eyes
