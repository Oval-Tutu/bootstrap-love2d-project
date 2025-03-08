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

-- Particle system configuration templates
Fire.PARTICLE_CONFIGS = {
  fire = {
    count = 100,
    lifetime = { min = 0.5, max = 1.2 },
    emissionRate = 70,
    sizeVariation = 0.6,
    acceleration = { minX = -15, minY = -80, maxX = 15, maxY = -100 },
    speed = { min = 15, max = 60 },
    sizes = { 0.2, 0.7, 0.5, 0.2 },
    spread = Fire.BASE_FIRE_CONFIG.spread,
    radial = Fire.BASE_FIRE_CONFIG.radial,
    tangential = Fire.BASE_FIRE_CONFIG.tangential,
    spin = { min = -0.5, max = 0.5 },
    spinVariation = 1,
    -- Use default base properties for the rest
  },

  core = {
    count = 50,
    lifetime = { min = 0.3, max = 0.8 },
    emissionRate = 50,
    sizeVariation = 0.3,
    acceleration = { minX = -5, minY = -100, maxX = 5, maxY = -130 },
    speed = { min = 20, max = 40 },
    sizes = { 0.4, 0.6, 0.3, 0.1 },
    spread = math.pi/8,
    radial = { min = -2, max = 2 },
    tangential = { min = -5, max = 5 },
    -- Use default base properties for the rest
  },

  spark = {
    count = 30,
    lifetime = { min = 0.5, max = 1.5 },
    emissionRate = 0, -- Controlled manually
    acceleration = { minX = -20, minY = -200, maxX = 20, maxY = -300 },
    speed = { min = 50, max = 150 },
    sizes = { 0.6, 0.4, 0.2, 0 },
    spread = math.pi/2,
    radial = { min = -50, max = 50 },
    tangential = { min = -20, max = 20 },
    spin = { min = -2, max = 2 },
    spinVariation = 1,
    autostart = false,
    -- Use default base properties for the rest
  },

  smoke = {
    count = 40,
    lifetime = { min = 1.0, max = 2.5 },
    emissionRate = 15,
    sizeVariation = 0.8,
    acceleration = { minX = -5, minY = -20, maxX = 5, maxY = -40 },
    speed = { min = 5, max = 15 },
    sizes = { 0.1, 0.6, 1.0, 1.3 },
    spread = math.pi/2,
    radial = { min = -10, max = 10 },
    tangential = { min = -20, max = 20 },
    spin = { min = 0.1, max = 0.8 },
    spinVariation = 1,
    offset = function() return love.math.random(-5,5), love.math.random(60,90) end,
    -- Use default base properties for the rest
  }
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

---Creates a particle system based on a predefined configuration type
---@param type string The particle system type ('fire', 'core', 'spark', 'smoke')
---@param image love.Canvas The image to use for the particles
---@return love.ParticleSystem The configured particle system
function Fire:createParticleSystem(type, image)
  -- Get the configuration for this type
  local config = Fire.PARTICLE_CONFIGS[type]
  if not config then
    error("Unknown particle system type: " .. tostring(type))
  end

  -- Create the system with the specified particle count
  local system = love.graphics.newParticleSystem(image, config.count)

  -- Apply any special configuration before standard configuration
  if type == "smoke" and config.offset then
    local offsetX, offsetY = config.offset()
    system:setOffset(offsetX, offsetY)
  end

  -- Prepare the configuration by merging with base config
  local fullConfig = {
    -- Apply base defaults
    direction = Fire.BASE_PARTICLE_CONFIG.direction,
    sizeVariation = Fire.BASE_PARTICLE_CONFIG.sizeVariation,
    autostart = Fire.BASE_PARTICLE_CONFIG.autostart,

    -- Then apply type-specific config
    lifetime = config.lifetime,
    emissionRate = config.emissionRate,
    sizeVariation = config.sizeVariation or Fire.BASE_PARTICLE_CONFIG.sizeVariation,
    acceleration = config.acceleration,
    speed = config.speed,
    sizes = config.sizes,
    spread = config.spread,
    radial = config.radial,
    tangential = config.tangential,
    colors = self.colors[type == "core" and "corefire" or type], -- Map 'core' to 'corefire'
    spin = config.spin,
    spinVariation = config.spinVariation,
    autostart = config.autostart ~= nil and config.autostart or Fire.BASE_PARTICLE_CONFIG.autostart
  }

  -- Configure and return the particle system
  return self:configureParticleSystem(system, fullConfig)
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
  -- Use shared resources and unified creation function
  local fireSystem = self:createParticleSystem("fire", Fire.resources.particleImage)
  local coreSystem = self:createParticleSystem("core", Fire.resources.particleImage)
  local sparkSystem = self:createParticleSystem("spark", Fire.resources.sparkImage)
  local smokeSystem = self:createParticleSystem("smoke", Fire.resources.particleImage)

  -- Store the systems in instance properties
  self.fireSystem = fireSystem
  self.coreSystem = coreSystem
  self.sparkSystem = sparkSystem
  self.smokeSystem = smokeSystem

  return fireSystem, coreSystem, sparkSystem, smokeSystem
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
