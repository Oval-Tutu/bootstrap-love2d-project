---@class EyesAudio Module for managing audio in the eyes scene
local audio = {
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
---@return love.Source The sound source that's playing
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

-- Public API
---Initializes the audio system
function audio:load()
  -- Load sound effects
  self.sounds = loadSoundEffects()

  -- Load and start playing the ambient fire sounds (true stereo)
  self.ambientFireSound = loadAmbientFireSound()
  self.ambientFireSound.left:play()
  self.ambientFireSound.right:play()
end

---Updates the audio system
---@param dt number Delta time since last frame
---@param state table Current eye state
---@param x number Current cursor X position
---@param y number Current cursor Y position
function audio:update(dt, state, x, y)
  -- Update sound based on eye state
  updateSoundState(state, self.sounds, self.soundState)

  -- Check if a sound has finished playing
  if self.soundState.currentSound and not self.soundState.currentSound:isPlaying() then
    -- Sound finished playing
    self.soundState.currentSound = nil
    self.soundState.soundPlaying = false
    self.soundState.soundJustFinished = true -- Set flag when sound finishes
  end

  -- Update audio position and volume
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  updateAudioSystem(self.ambientFireSound, x, y, windowWidth, windowHeight)
end

---Stops all audio and cleans up resources
function audio:stop()
  if self.ambientFireSound then
    if self.ambientFireSound.left then
      self.ambientFireSound.left:stop()
    end
    if self.ambientFireSound.right then
      self.ambientFireSound.right:stop()
    end
  end

  if self.soundState.currentSound then
    self.soundState.currentSound:stop()
  end
end

return audio
