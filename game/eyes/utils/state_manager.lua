---@class StateManager Handles centralized state management for the eyes module
local StateManager = {}
StateManager.__index = StateManager

---Creates a new state manager
---@param eyes table The main eyes module
---@return StateManager
function StateManager.new(eyes)
  local self = setmetatable({}, StateManager)
  self.eyes = eyes
  -- Core states
  self.isOnline = false
  self.mousePosition = {x = 0, y = 0}
  self.touching = false
  self.shake = {x = 0, y = 0}

  -- Create sub-managers for logical groupings
  self.motion = self:createMotionManager()
  self.interaction = self:createInteractionManager()
  self.effects = self:createEffectsManager()

  return self
end

---Creates the motion state manager
---@return table Motion state manager
function StateManager:createMotionManager()
  return {
    -- Floating state
    timeX = 0,
    timeY = 0,

    -- Update the floating time accumulators
    ---@param dt number Delta time
    ---@param config table Floating configuration
    updateTime = function(self, dt, config)
      self.timeX = (self.timeX + dt * config.speedX) % (2 * math.pi)
      self.timeY = (self.timeY + dt * config.speedY) % (2 * math.pi)
    end
  }
end

---Creates the interaction state manager
---@return table Interaction state manager
function StateManager:createInteractionManager()
  return {
    -- Update interaction state based on mouse position
    ---@param eyes table The eyes collection
    ---@param mouseX number Mouse X position
    ---@param mouseY number Mouse Y position
    ---@param dt number Delta time
    ---@param fadeSpeed number Speed at which fade changes
    updateTouchState = function(self, eyes, mouseX, mouseY, dt, fadeSpeed)
      local leftEye = eyes.left
      local rightEye = eyes.right

      -- Update individual eye touch state
      leftEye:updateTouchState(dt, leftEye:isPointOver(mouseX, mouseY), fadeSpeed)
      rightEye:updateTouchState(dt, rightEye:isPointOver(mouseX, mouseY), fadeSpeed)

      -- Update overall touch state
      return leftEye.isTouching or rightEye.isTouching
    end
  }
end

---Creates the effects state manager
---@return table Effects state manager
function StateManager:createEffectsManager()
  return {
    -- Update pupil dilation and reflection effects
    ---@param eyes table The eyes collection
    ---@param dt number Delta time
    ---@param mouseX number Mouse X position
    ---@param mouseY number Mouse Y position
    ---@param eyeSize number Size of an eye
    ---@param reflectionConfig table Reflection configuration
    ---@param dilationConfig table Dilation configuration
    ---@param fire table Fire module
    updateEffects = function(self, eyes, dt, mouseX, mouseY, eyeSize, reflectionConfig, dilationConfig, fire)
      local leftEye = eyes.left
      local rightEye = eyes.right

      -- Calculate all effects in a single pass
      local mousePosition = {x = mouseX, y = mouseY}
      local effects = self.parent.eyes.calculateEyeEffects(
        mousePosition,
        leftEye, rightEye,
        reflectionConfig, dilationConfig
      )

      -- Update reflections
      leftEye:updateReflection(
        effects.leftReflection, effects.leftX, effects.leftY,
        reflectionConfig.fadeSpeed, dt
      )

      rightEye:updateReflection(
        effects.rightReflection, effects.rightX, effects.rightY,
        reflectionConfig.fadeSpeed, dt
      )

      -- Update pupil dilations
      leftEye:updatePupilDilation(
        effects.leftDilation,
        dilationConfig.fadeSpeed,
        dt
      )

      rightEye:updatePupilDilation(
        effects.rightDilation,
        dilationConfig.fadeSpeed,
        dt
      )
    end,

    -- Calculate and update shake effect
    ---@param isTouching boolean Whether any eye is being touched
    ---@param shakeAmount number Maximum shake amount
    ---@return number shakeX X shake value
    ---@return number shakeY Y shake value
    updateShake = function(self, isTouching, shakeAmount)
      if isTouching then
        return love.math.random(-shakeAmount, shakeAmount), love.math.random(-shakeAmount, shakeAmount)
      else
        return 0, 0
      end
    end
  }
end

---Updates all state in a centralized manner
---@param dt number Delta time
function StateManager:update(dt)
  -- Update mouse position
  local x, y = love.mouse.getPosition()
  self.mousePosition.x = math.floor(x)
  self.mousePosition.y = math.floor(y)

  -- Update floating animation timing
  self.motion:updateTime(dt, self.eyes.floating)

  -- Update eye positions
  local mousePos = {x = self.mousePosition.x, y = self.mousePosition.y}
  self.eyes.eyes.left:updateFloating(dt, self.motion.timeX, self.motion.timeY, self.eyes.floating, mousePos)
  self.eyes.eyes.right:updateFloating(dt, self.motion.timeX, self.motion.timeY, self.eyes.floating, mousePos)

  -- Update touch interactions
  self.touching = self.interaction:updateTouchState(
    self.eyes.eyes,
    self.mousePosition.x,
    self.mousePosition.y,
    dt,
    self.eyes.fadeSpeed
  )

  -- Store parent reference in sub-managers
  self.effects.parent = self

  -- Update visual effects (reflection, dilation)
  self.effects:updateEffects(
    self.eyes.eyes,
    dt,
    self.mousePosition.x,
    self.mousePosition.y,
    self.eyes.eyeSize,
    self.eyes.reflection,
    self.eyes.pupilDilation,
    self.eyes.fireModule  -- This is no longer used for calculations
  )

  -- Update shake effect
  self.shake.x, self.shake.y = self.effects:updateShake(self.touching, self.eyes.shakeAmount)
end

return StateManager
