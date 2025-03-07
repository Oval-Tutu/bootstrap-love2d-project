local overlayStats = require("lib.overlayStats")

---@class Fire A class for fire effects and particle systems
local Fire = {}
Fire.__index = Fire

-- Fire-related colors (static shared data)
Fire.COLORS = {
  fire = {
    { 1, 0.7, 0, 0.8 },   -- golden orange
    { 1, 0.4, 0, 0.7 },   -- orange
    { 1, 0.2, 0, 0.5 },   -- red-orange
    { 0.7, 0.1, 0, 0.3 }, -- dark red
    { 0.4, 0, 0, 0 }      -- fade out to transparent
  },
  corefire = {
    { 1, 1, 0.8, 0.9 },   -- bright yellow
    { 1, 0.8, 0.2, 0.7 }, -- yellow-orange
    { 1, 0.6, 0, 0.5 },   -- orange
    { 1, 0.3, 0, 0.3 },   -- reddish-orange
    { 0.8, 0.1, 0 }    -- fade out
  },
  spark = {
    { 1, 1, 1, 1 },     -- white
    { 1, 1, 0.6, 0.8 }, -- bright yellow
    { 1, 0.3, 0, 0.3 },   -- reddish-orange
    { 1, 0.6, 0.1, 0 }  -- fade to transparent
  },
  smoke = {
    { 0.5, 0.5, 0.5, 0 },   -- transparent to start
    { 0.4, 0.4, 0.4, 0.2 }, -- light gray with some transparency
    { 0.3, 0.3, 0.3, 0.1 }, -- mid gray, fading
    { 0.2, 0.2, 0.2, 0 }    -- dark gray, completely transparent
  },
  reflection = {
    { 1, 0.95, 0.8, 1.0 },  -- Bright white-yellow
    { 1, 0.8, 0.3, 0.7 }    -- Fading orange-yellow
  }
}

-- Base configuration templates as class properties
Fire.BASE_PARTICLE_CONFIG = {
  direction = -math.pi/2,
  sizeVariation = 0.5,
  autostart = true
}

Fire.BASE_FIRE_CONFIG = {
  spread = math.pi/3,
  radial = { min = -10, max = 10 },
  tangential = { min = -20, max = 20 }
}

-- Shared resources across all instances
Fire.resources = {
  particleImage = nil,
  sparkImage = nil,
  initialized = false,
  refCount = 0
}

-- Initialize shared resources if needed
function Fire.initResources()
  if Fire.resources.initialized then
    Fire.resources.refCount = Fire.resources.refCount + 1
    return
  end

  -- Create flame particle image (only once)
  Fire.resources.particleImage = Fire.createFlameImage()
  Fire.resources.sparkImage = Fire.createSparkImage()
  Fire.resources.initialized = true
  Fire.resources.refCount = 1
end

-- Release shared resources when no longer needed
function Fire.releaseResources()
  Fire.resources.refCount = Fire.resources.refCount - 1
  if Fire.resources.refCount <= 0 then
    if Fire.resources.particleImage then
      Fire.resources.particleImage:release()
      Fire.resources.particleImage = nil
    end
    if Fire.resources.sparkImage then
      Fire.resources.sparkImage:release()
      Fire.resources.sparkImage = nil
    end
    Fire.resources.initialized = false
    Fire.resources.refCount = 0
  end
end

-- Move image creation functions to class-level static methods
function Fire.createFlameImage()
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

  return particleImg
end

function Fire.createSparkImage()
  local sparkImg = love.graphics.newCanvas(16, 16)
  love.graphics.setCanvas(sparkImg)
  love.graphics.clear()

  local prevLineStyle = love.graphics.getLineStyle()
  love.graphics.setLineStyle("smooth")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle("fill", 8, 8, 6)
  love.graphics.setColor(1, 1, 0.8, 0.6)
  love.graphics.circle("fill", 8, 8, 8)
  love.graphics.setLineStyle(prevLineStyle)
  love.graphics.setCanvas()

  return sparkImg
end

---Creates a new Fire instance
---@return Fire
function Fire.new()
  -- Initialize shared resources
  Fire.initResources()

  local self = setmetatable({}, Fire)

  -- Instance properties (formerly global state)
  self.fireSystem = nil    -- Outer erratic flames
  self.coreSystem = nil    -- Stable inner core
  self.sparkSystem = nil   -- Occasional bright sparks
  self.smokeSystem = nil   -- Smoke effect

  -- Timer for spark emission control
  self.sparkTimer = 0
  self.sparkInterval = 0.15

  -- Colors reference (can be customized per instance)
  self.colors = Fire.COLORS

  -- Initialize the particle systems
  self:initParticleSystem()

  return self
end

-- Add cleanup method
function Fire:destroy()
  -- Release particle systems
  if self.fireSystem then self.fireSystem:release() end
  if self.coreSystem then self.coreSystem:release() end
  if self.sparkSystem then self.sparkSystem:release() end
  if self.smokeSystem then self.smokeSystem:release() end

  -- Release reference to shared resources
  Fire.releaseResources()
end

---Creates the outer fire particle system
---@param image love.Canvas The flame image to use
---@return love.ParticleSystem The configured fire particle system
function Fire:createFireSystem(image)
  local system = love.graphics.newParticleSystem(image, 100)
  return self:configureParticleSystem(system, {
    lifetime = { min = 0.5, max = 1.2 },
    emissionRate = 70,
    sizeVariation = 0.6,
    acceleration = { minX = -15, minY = -80, maxX = 15, maxY = -100 },
    speed = { min = 15, max = 60 },
    sizes = { 0.2, 0.7, 0.5, 0.2 },
    direction = Fire.BASE_PARTICLE_CONFIG.direction,
    spread = Fire.BASE_FIRE_CONFIG.spread,
    radial = Fire.BASE_FIRE_CONFIG.radial,
    tangential = Fire.BASE_FIRE_CONFIG.tangential,
    colors = self.colors.fire,
    spin = { min = -0.5, max = 0.5 },
    spinVariation = 1,
    autostart = Fire.BASE_PARTICLE_CONFIG.autostart
  })
end

---Creates the core fire particle system
---@param image love.Canvas The flame image to use
---@return love.ParticleSystem The configured core fire particle system
function Fire:createCoreSystem(image)
  local system = love.graphics.newParticleSystem(image, 50)
  return self:configureParticleSystem(system, {
    lifetime = { min = 0.3, max = 0.8 },
    emissionRate = 50,
    sizeVariation = 0.3,
    acceleration = { minX = -5, minY = -100, maxX = 5, maxY = -130 },
    speed = { min = 20, max = 40 },
    sizes = { 0.4, 0.6, 0.3, 0.1 },
    direction = Fire.BASE_PARTICLE_CONFIG.direction,
    spread = math.pi/8,
    radial = { min = -2, max = 2 },
    tangential = { min = -5, max = 5 },
    colors = self.colors.corefire,
    autostart = Fire.BASE_PARTICLE_CONFIG.autostart
  })
end

---Creates the spark particle system
---@param image love.Canvas The spark image to use
---@return love.ParticleSystem The configured spark particle system
function Fire:createSparkSystem(image)
  local system = love.graphics.newParticleSystem(image, 30)
  return self:configureParticleSystem(system, {
    lifetime = { min = 0.5, max = 1.5 },
    emissionRate = 0, -- Controlled manually
    sizeVariation = Fire.BASE_PARTICLE_CONFIG.sizeVariation,
    acceleration = { minX = -20, minY = -200, maxX = 20, maxY = -300 },
    speed = { min = 50, max = 150 },
    sizes = { 0.6, 0.4, 0.2, 0 },
    direction = Fire.BASE_PARTICLE_CONFIG.direction,
    spread = math.pi/2,
    radial = { min = -50, max = 50 },
    tangential = { min = -20, max = 20 },
    colors = self.colors.spark,
    spin = { min = -2, max = 2 },
    spinVariation = 1,
    autostart = false
  })
end

---Creates the smoke particle system
---@param image love.Canvas The flame image to use
---@return love.ParticleSystem The configured smoke particle system
function Fire:createSmokeSystem(image)
  local system = love.graphics.newParticleSystem(image, 40)
  system:setOffset(love.math.random(-5,5), love.math.random(60,90))
  return self:configureParticleSystem(system, {
    lifetime = { min = 1.0, max = 2.5 },
    emissionRate = 15,
    sizeVariation = 0.8,
    acceleration = { minX = -5, minY = -20, maxX = 5, maxY = -40 },
    speed = { min = 5, max = 15 },
    sizes = { 0.1, 0.6, 1.0, 1.3 },
    direction = Fire.BASE_PARTICLE_CONFIG.direction,
    spread = math.pi/2,
    radial = { min = -10, max = 10 },
    tangential = { min = -20, max = 20 },
    colors = self.colors.smoke,
    spin = { min = 0.1, max = 0.8 },
    spinVariation = 1,
    autostart = Fire.BASE_PARTICLE_CONFIG.autostart
  })
end

---Configures a particle system with common properties
---@param particleSystem love.ParticleSystem The particle system to configure
---@param config table Configuration parameters
function Fire:configureParticleSystem(particleSystem, config)
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
function Fire:initParticleSystem()
  -- Use shared resources instead of creating new ones
  local fireSystem = self:createFireSystem(Fire.resources.particleImage)
  local coreSystem = self:createCoreSystem(Fire.resources.particleImage)
  local sparkSystem = self:createSparkSystem(Fire.resources.sparkImage)
  local smokeSystem = self:createSmokeSystem(Fire.resources.particleImage)

  -- Store the systems in instance properties
  self.fireSystem = fireSystem
  self.coreSystem = coreSystem
  self.sparkSystem = sparkSystem
  self.smokeSystem = smokeSystem

  return fireSystem, coreSystem, sparkSystem, smokeSystem
end

---Calculate distance from a point to an eye
---@param pointX number X position of the point
---@param pointY number Y position of the point
---@param eyeX number X position of the eye
---@param eyeY number Y position of the eye
---@return number distance Distance from point to eye
function Fire:calculateDistanceToEye(pointX, pointY, eyeX, eyeY)
  return math.sqrt((pointX - eyeX)^2 + (pointY - eyeY)^2)
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
function Fire:calculateReflectionProperties(mouseX, mouseY, leftEyeX, rightEyeX, eyeY, eyeSize, config)
  -- Calculate distances to each eye using the helper function
  local distanceToLeft = self:calculateDistanceToEye(mouseX, mouseY, leftEyeX, eyeY)
  local distanceToRight = self:calculateDistanceToEye(mouseX, mouseY, rightEyeX, eyeY)

  -- Calculate intensity based on distance (closer = more intense)
  local leftIntensity, rightIntensity = 0, 0

  if distanceToLeft < config.maxDistance then
    leftIntensity = math.max(0.2, math.min(config.maxIntensity,
      config.maxIntensity * (1 - (distanceToLeft - config.minDistance) /
      (config.maxDistance - config.minDistance))))
  end

  if distanceToRight < config.maxDistance then
    rightIntensity = math.max(0.2, math.min(config.maxIntensity,
      config.maxIntensity * (1 - (distanceToRight - config.minDistance) /
      (config.maxDistance - config.minDistance))))
  end

  -- Use simple position values for backward compatibility
  return leftIntensity, rightIntensity, leftEyeX, eyeY, rightEyeX, eyeY
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
function Fire:calculatePupilDilation(mouseX, mouseY, leftEyeX, rightEyeX, eyeY, config)
  -- Calculate distances to each eye using the helper function
  local distanceToLeft = self:calculateDistanceToEye(mouseX, mouseY, leftEyeX, eyeY)
  local distanceToRight = self:calculateDistanceToEye(mouseX, mouseY, rightEyeX, eyeY)

  -- Calculate dilation factors based on distance (closer = more dilated)
  local leftDilation, rightDilation = 0, 0

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

---Register particle systems with the stats overlay
---@param overlayStatsModule table Optional stats overlay module for registering particle systems
function Fire:registerWithStats(overlayStatsModule)
  if not overlayStatsModule then return end

  local systems = {self.fireSystem, self.coreSystem, self.sparkSystem, self.smokeSystem}
  for _, system in ipairs(systems) do
    overlayStatsModule.registerParticleSystem(system)
  end
end

---Updates a particle system position
---@param system love.ParticleSystem The particle system to update
---@param dt number Delta time
---@param x number X position
---@param y number Y position
local function updateSystem(system, dt, x, y)
  system:update(dt)
  system:setPosition(x, y)
end

---Update the fire particle systems
---@param dt number Delta time
---@param x number Current x position of the fire (mouse)
---@param y number Current y position of the fire (mouse)
function Fire:update(dt, x, y)
  -- Update all particle systems
  updateSystem(self.fireSystem, dt, x, y)
  updateSystem(self.coreSystem, dt, x, y)
  updateSystem(self.smokeSystem, dt, x, y)
  updateSystem(self.sparkSystem, dt, x, y)

  -- Spark emission control - randomly emit sparks
  self.sparkTimer = self.sparkTimer + dt
  if self.sparkTimer >= self.sparkInterval then
    self.sparkTimer = 0
    self.sparkInterval = love.math.random(0.05, 0.3)
    self.sparkSystem:emit(love.math.random(1, 5))
  end
end

---Draw the fire effect
function Fire:draw()
  -- FIXME: Set color to yellow to prevent the fire from being snuffed out while the mouse is moving
  love.graphics.setColor({ 1, 1, 0 })

  -- Save current blend mode
  local prevBlendMode = love.graphics.getBlendMode()

  -- Draw the layers in back-to-front order
  love.graphics.setBlendMode("alpha")
  love.graphics.draw(self.smokeSystem)
  love.graphics.draw(self.coreSystem)

  love.graphics.setBlendMode("add")
  love.graphics.draw(self.fireSystem)
  love.graphics.draw(self.sparkSystem)

  -- Restore previous blend mode
  love.graphics.setBlendMode(prevBlendMode)
end

-- For backward compatibility with old code - use metatable for automatic method forwarding
local globalInstance = Fire.new()

local fire = setmetatable({
  -- Explicitly defined properties
  Fire = Fire,
  colors = globalInstance.colors
}, {
  __index = function(_, key)
    local value = globalInstance[key]
    if type(value) == "function" then
      -- Automatically wrap instance methods for global access
      return function(...)
        return value(globalInstance, ...)
      end
    end
    return value
  end
})

-- Special case for load since it performs registration
fire.load = function() globalInstance:registerWithStats(overlayStats) end

return fire
