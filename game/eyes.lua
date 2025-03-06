---@class Eyes Module for drawing and managing interactive eyes
local overlayStats = require("lib.overlayStats")

-- Private functions defined as locals
---Checks if the mouse is over an eye
---@param eyeX number The x-coordinate of the eye
---@param eyeY number The y-coordinate of the eye
---@return boolean isOver True if mouse is over the eye
local function isMouseOverEye(eyeX, eyeY, eyeSize)
  local mouseX = love.mouse.getX()
  local mouseY = love.mouse.getY()
  local distance = math.sqrt((mouseX - eyeX) ^ 2 + (mouseY - eyeY) ^ 2)
  return distance < eyeSize
end

---Draws a single eye
---@param eyeX number The x-coordinate of the eye
---@param eyeY number The y-coordinate of the eye
---@param isWinking boolean Whether the eye is winking
---@param eyeSize number The size of the eye
---@param colors table Color definitions
---@param isTouching boolean Whether any eye is being touched
local function drawEye(eyeX, eyeY, isWinking, eyeSize, colors, isTouching)
  if isWinking then
    love.graphics.setColor(isTouching and colors.lightPink or colors.white)
    love.graphics.circle("fill", eyeX, eyeY, eyeSize)
    love.graphics.setColor(isTouching and colors.darkRed or colors.blue)
    love.graphics.setLineWidth(8)
    love.graphics.line(eyeX - eyeSize, eyeY, eyeX + eyeSize, eyeY)
  else
    local pupilX, pupilY

    if (isTouching) then
      -- Random oscillation around the center when any eye is being touched
      local oscillationRange = eyeSize / 16
      pupilX = eyeX + love.math.random(-oscillationRange, oscillationRange)
      pupilY = eyeY + love.math.random(-oscillationRange, oscillationRange)

      love.graphics.setColor(colors.lightPink)
    else
      -- Normal eye tracking behavior
      local distanceX = love.mouse.getX() - eyeX
      local distanceY = love.mouse.getY() - eyeY
      local distance = math.min(math.sqrt(distanceX ^ 2 + distanceY ^ 2), eyeSize / 2)
      local angle = math.atan2(distanceY, distanceX)

      pupilX = eyeX + (math.cos(angle) * distance)
      pupilY = eyeY + (math.sin(angle) * distance)

      love.graphics.setColor(colors.white)
    end

    love.graphics.circle("fill", eyeX, eyeY, eyeSize)

    love.graphics.setColor(isTouching and colors.darkRed or colors.blue)
    love.graphics.circle("fill", pupilX, pupilY, 16)
  end
end

---Draws status messages based on eye state
---@param windowWidth number Width of the window
---@param windowHeight number Height of the window
---@param font love.Font The font to use for messages
---@param state table Current eye state
---@param shakeX number Current X shake amount
---@param shakeY number Current Y shake amount
---@param colors table Color definitions
local function drawStatusMessages(windowWidth, windowHeight, font, state, shakeX, shakeY, colors)
  local padding = 128

  -- Draw "Ouch" message when eyes are shaking
  if (shakeX + shakeY) ~= 0 then
    love.graphics.setColor(colors.orange)
    local text = i18n("Ouch")
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (windowWidth - textWidth) / 2, windowHeight - 256)
  end

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
---@param leftEyeX number The x-coordinate of the left eye
---@param rightEyeX number The x-coordinate of the right eye
---@param centerY number The y-coordinate of both eyes
---@param eyeSize number The size of the eye
local function updateEyeState(state, leftEyeX, rightEyeX, centerY, eyeSize)
  local leftButton = love.mouse.isDown(1)
  local rightButton = love.mouse.isDown(2)
  local middleButton = love.mouse.isDown(3)

  state.bothBlinking = middleButton or (leftButton and rightButton)
  state.leftEyeWinking = state.bothBlinking or (leftButton and not state.bothBlinking)
  state.rightEyeWinking = state.bothBlinking or (rightButton and not state.bothBlinking)

  -- Check if either eye is being touched
  state.touching = isMouseOverEye(leftEyeX, centerY, eyeSize) or isMouseOverEye(rightEyeX, centerY, eyeSize)
end

---Updates the shake effect when mouse is over eyes
---@param leftEyeX number The x-coordinate of the left eye
---@param rightEyeX number The x-coordinate of the right eye
---@param centerY number The y-coordinate of both eyes
---@param eyeSize number The size of the eye
---@param shakeAmount number Maximum shake amount
---@return number shakeX Resulting X shake value
---@return number shakeY Resulting Y shake value
local function updateShakeEffect(leftEyeX, rightEyeX, centerY, eyeSize, shakeAmount)
  if isMouseOverEye(leftEyeX, centerY, eyeSize) or isMouseOverEye(rightEyeX, centerY, eyeSize) then
    return love.math.random(-shakeAmount, shakeAmount), love.math.random(-shakeAmount, shakeAmount)
  else
    return 0, 0
  end
end

-- The public module
local eyes = {
  -- Configuration
  eyeSize = 128,
  eyeSpacing = 320,
  shakeAmount = 5,

  -- State variables
  shakeX = 0,
  shakeY = 0,
  x = 0,
  y = 0,

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
}

-- Constants
eyes.colors = {
  white = { 1, 1, 1 },
  blue = { 0, 0, 0.4 },
  yellow = { 1, 1, 0 },
  orange = { 1, 0.5, 0 },
  red = { 1, 0, 0 },
  purple = { 1, 0, 1 },
  green = { 0, 1, 0 },
  darkGrey = { 0.1, 0.1, 0.1 },
  lightPink = { 1, 0.92, 0.92 },
  darkRed = { 0.6, 0, 0 },
  -- Enhanced fire colors with more color stops for smoother transitions
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
    { 0.8, 0.1, 0, 0 }    -- fade out
  },
  -- Spark colors (bright and short-lived)
  spark = {
    { 1, 1, 1, 1 },     -- white
    { 1, 1, 0.6, 0.8 }, -- bright yellow
    { 1, 0.8, 0.3, 0.6 }, -- yellow-orange
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
  touching = false
}

---Creates and initializes the particle systems for the cursor flame effect
---@return love.ParticleSystem The outer fire particle system
---@return love.ParticleSystem The core fire particle system
---@return love.ParticleSystem The spark particle system
---@return love.ParticleSystem The smoke particle system
local function initParticleSystem()
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
  fireSystem:setParticleLifetime(0.5, 1.2)
  fireSystem:setEmissionRate(70)
  fireSystem:setSizeVariation(0.6)  -- More variation for chaotic look

  -- More erratic movement at the tips
  fireSystem:setLinearAcceleration(-15, -80, 15, -100)
  -- Higher speed variation for flickering effect
  fireSystem:setSpeed(15, 60)

  -- Start small, grow, then shrink
  fireSystem:setSizes(0.2, 0.7, 0.5, 0.2)

  -- Wider spread for outer flames
  fireSystem:setDirection(-math.pi/2)  -- Upward
  fireSystem:setSpread(math.pi/3)      -- Wider spread

  -- More chaotic movement at the flame tips
  fireSystem:setRadialAcceleration(-10, 10)
  fireSystem:setTangentialAcceleration(-30, 30) -- Much more swirling

  -- Outer fire colors
  fireSystem:setColors(unpack(eyes.colors.fire))

  -- Add some slow rotation for swirling flames
  fireSystem:setSpin(-0.5, 0.5)
  fireSystem:setSpinVariation(1)

  fireSystem:start()

  -- 2. CORE FIRE SYSTEM - Stable inner core
  local coreSystem = love.graphics.newParticleSystem(particleImg, 50)
  coreSystem:setParticleLifetime(0.3, 0.8)  -- Shorter lifetime for core
  coreSystem:setEmissionRate(50)
  coreSystem:setSizeVariation(0.3)  -- Less variation for stability

  -- More focused upward movement
  coreSystem:setLinearAcceleration(-5, -100, 5, -130)
  coreSystem:setSpeed(20, 40)  -- Consistent speed

  -- Start a bit larger than outer flames
  coreSystem:setSizes(0.4, 0.6, 0.3, 0.1)

  -- Narrower spread for focused core
  coreSystem:setDirection(-math.pi/2)  -- Upward
  coreSystem:setSpread(math.pi/8)      -- Narrower spread

  -- Minimal chaos for stability
  coreSystem:setRadialAcceleration(-2, 2)
  coreSystem:setTangentialAcceleration(-5, 5) -- Minimal swirling

  -- Brighter core colors
  coreSystem:setColors(unpack(eyes.colors.corefire))

  coreSystem:start()

  -- 3. SPARK SYSTEM - Occasional bright particles shooting upward
  local sparkSystem = love.graphics.newParticleSystem(sparkImg, 30)
  sparkSystem:setParticleLifetime(0.5, 1.5)  -- Variable lifetime
  sparkSystem:setEmissionRate(0)  -- We'll control emission manually
  sparkSystem:setSizeVariation(0.5)

  -- Fast upward movement with wider spread
  sparkSystem:setLinearAcceleration(-20, -200, 20, -300)
  sparkSystem:setSpeed(50, 150)  -- Fast sparks

  -- Sparks shrink as they rise
  sparkSystem:setSizes(0.6, 0.4, 0.2, 0)

  -- Wide directional spread for sparks
  sparkSystem:setDirection(-math.pi/2)
  sparkSystem:setSpread(math.pi/2)  -- Full spread

  -- Random movement for sparks
  sparkSystem:setRadialAcceleration(-50, 50)  -- Can move away from center
  sparkSystem:setTangentialAcceleration(-20, 20)  -- Some swirl

  -- Bright spark colors
  sparkSystem:setColors(unpack(eyes.colors.spark))

  -- Sparks rotate as they move
  sparkSystem:setSpin(-2, 2)
  sparkSystem:setSpinVariation(1)

  -- 4. SMOKE SYSTEM - same as before with minor adjustments
  local smokeSystem = love.graphics.newParticleSystem(particleImg, 40)
  smokeSystem:setOffset(love.math.random(-5,5), love.math.random(60,90))
  smokeSystem:setParticleLifetime(1.0, 2.5)
  smokeSystem:setEmissionRate(15)
  smokeSystem:setSizeVariation(0.8)

  smokeSystem:setLinearAcceleration(-5, -20, 5, -40)
  smokeSystem:setSpeed(5, 15)

  smokeSystem:setSizes(0.1, 0.6, 1.0, 1.3)
  smokeSystem:setDirection(-math.pi/2)
  smokeSystem:setSpread(math.pi/2)
  smokeSystem:setRadialAcceleration(-10, 10)
  smokeSystem:setTangentialAcceleration(-20, 20)
  smokeSystem:setColors(unpack(eyes.colors.smoke))
  smokeSystem:setSpin(0.1, 0.8)
  smokeSystem:setSpinVariation(1.0)
  smokeSystem:start()

  return fireSystem, coreSystem, sparkSystem, smokeSystem
end

---Loads resources and initializes the eyes
function eyes.load()
  if checkOnlineStatus() then
    eyes.online_color = eyes.colors.green
    eyes.online_message = "Online"
  end

  -- Initialize the particle systems
  eyes.fireSystem, eyes.coreSystem, eyes.sparkSystem, eyes.smokeSystem = initParticleSystem()

  -- Register particle systems with overlayStats
  overlayStats.registerParticleSystem(eyes.fireSystem)
  overlayStats.registerParticleSystem(eyes.coreSystem)
  overlayStats.registerParticleSystem(eyes.sparkSystem)
  overlayStats.registerParticleSystem(eyes.smokeSystem)

  love.graphics.setFont(love.graphics.newFont(42))
  love.mouse.setVisible(false)
end

function eyes.update(dt)
  eyes.x, eyes.y = love.mouse.getPosition()
  eyes.x = math.floor(eyes.x)
  eyes.y = math.floor(eyes.y)

  -- Update standard particle systems
  eyes.fireSystem:update(dt)
  eyes.fireSystem:setPosition(eyes.x, eyes.y)

  eyes.coreSystem:update(dt)
  eyes.coreSystem:setPosition(eyes.x, eyes.y)

  eyes.smokeSystem:update(dt)
  eyes.smokeSystem:setPosition(eyes.x, eyes.y)

  -- Update spark system with random emission
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
end

function eyes.draw()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local font = love.graphics.getFont()
  local centerY = windowHeight / 2
  local leftEyeX = (windowWidth / 2) - (eyes.eyeSpacing / 2)
  local rightEyeX = (windowWidth / 2) + (eyes.eyeSpacing / 2)

  -- Draw background
  love.graphics.setColor(eyes.colors.darkGrey)
  love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

  eyes.shakeX, eyes.shakeY = updateShakeEffect(leftEyeX, rightEyeX, centerY, eyes.eyeSize, eyes.shakeAmount)

  love.graphics.push()
  love.graphics.translate(eyes.shakeX, eyes.shakeY)

  -- Update eye state with position information for touch detection
  updateEyeState(eyes.state, leftEyeX, rightEyeX, centerY, eyes.eyeSize)

  drawEye(leftEyeX, centerY, eyes.state.leftEyeWinking, eyes.eyeSize, eyes.colors, eyes.state.touching)
  drawEye(rightEyeX, centerY, eyes.state.rightEyeWinking, eyes.eyeSize, eyes.colors, eyes.state.touching)

  drawStatusMessages(windowWidth, windowHeight, font, eyes.state, eyes.shakeX, eyes.shakeY, eyes.colors)
  drawMouseCursor(windowWidth, font, eyes.x, eyes.y, eyes.colors,
                  eyes.fireSystem, eyes.coreSystem, eyes.sparkSystem, eyes.smokeSystem)
  drawOnlineStatus(windowWidth, font, eyes.online_color, eyes.online_message)

  love.graphics.pop()
end

return eyes
