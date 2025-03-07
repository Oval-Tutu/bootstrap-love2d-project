local overlayStats = require("lib.overlayStats")
---@class Fire Module for fire effects and particle systems
local fire = {}

-- Fire-related colors
fire.colors = {
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

-- Particle systems
fire.fireSystem = nil    -- Outer erratic flames
fire.coreSystem = nil    -- Stable inner core
fire.sparkSystem = nil   -- Occasional bright sparks
fire.smokeSystem = nil   -- Smoke effect

-- Timer for spark emission control
fire.sparkTimer = 0
fire.sparkInterval = 0.15

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
---@return love.ParticleSystem The outer fire particle system
---@return love.ParticleSystem The core fire particle system
---@return love.ParticleSystem The spark particle system
---@return love.ParticleSystem The smoke particle system
function fire.initParticleSystem()
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
    colors = fire.colors.fire,
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
    colors = fire.colors.corefire,
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
    colors = fire.colors.spark,
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
    colors = fire.colors.smoke,
    spin = { min = 0.1, max = 0.8 },
    spinVariation = 1,
    autostart = true
  })

  -- Store the systems in the fire module
  fire.fireSystem = fireSystem
  fire.coreSystem = coreSystem
  fire.sparkSystem = sparkSystem
  fire.smokeSystem = smokeSystem

  return fireSystem, coreSystem, sparkSystem, smokeSystem
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
function fire.calculateReflectionProperties(mouseX, mouseY, leftEyeX, rightEyeX, eyeY, eyeSize, config)
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
function fire.calculatePupilDilation(mouseX, mouseY, leftEyeX, rightEyeX, eyeY, config)
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

---Load and initialize the fire particle systems
---@param overlayStats table Optional stats overlay module for registering particle systems
function fire.load()
  fire.initParticleSystem()
  -- Register particle systems with overlayStats if provided
  if overlayStats then
    overlayStats.registerParticleSystem(fire.fireSystem)
    overlayStats.registerParticleSystem(fire.coreSystem)
    overlayStats.registerParticleSystem(fire.sparkSystem)
    overlayStats.registerParticleSystem(fire.smokeSystem)
  end
end

---Update the fire particle systems
---@param dt number Delta time
---@param x number Current x position of the fire (mouse)
---@param y number Current y position of the fire (mouse)
function fire.update(dt, x, y)
  -- Update particle systems
  fire.fireSystem:update(dt)
  fire.fireSystem:setPosition(x, y)

  fire.coreSystem:update(dt)
  fire.coreSystem:setPosition(x, y)

  fire.smokeSystem:update(dt)
  fire.smokeSystem:setPosition(x, y)

  fire.sparkSystem:update(dt)
  fire.sparkSystem:setPosition(x, y)

  -- Spark emission control - randomly emit sparks
  fire.sparkTimer = fire.sparkTimer + dt
  if fire.sparkTimer >= fire.sparkInterval then
    -- Reset timer and set a random interval for next spark
    fire.sparkTimer = 0
    fire.sparkInterval = love.math.random(0.05, 0.3)

    -- Emit a random number of sparks in a burst
    fire.sparkSystem:emit(love.math.random(1, 5))
  end
end

---Draw the fire effect
---@param x number Current x position for the fire (mouse)
---@param y number Current y position for the fire (mouse)
function fire.draw()
  -- Save current blend mode
  local prevBlendMode = love.graphics.getBlendMode()

  -- Draw the layers in back-to-front order

  -- 1. Smoke behind everything (alpha blending)
  love.graphics.setBlendMode("alpha")
  love.graphics.draw(fire.smokeSystem)

  -- 2. Core fire on top of outer fire (brighter)
  love.graphics.draw(fire.coreSystem)

  -- 3. Outer fire with additive blending
  love.graphics.setBlendMode("add")
  love.graphics.draw(fire.fireSystem)

  -- 4. Sparks on top of everything (brightest)
  love.graphics.draw(fire.sparkSystem)

  -- Restore previous blend mode
  love.graphics.setBlendMode(prevBlendMode)
end

return fire
