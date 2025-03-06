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
---@param particleSystem love.ParticleSystem The fire particle system
local function drawMouseCursor(windowWidth, font, x, y, colors, particleSystem)
  love.graphics.draw(particleSystem)
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

  -- Particle system
  particleSystem = nil,
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
  -- Fire colors for particle system
  fire = {
    { 1, 1, 0, 1 },     -- bright yellow
    { 1, 0.5, 0, 1 },   -- orange
    { 1, 0.2, 0, 0.8 }, -- red-orange
    { 0.7, 0, 0, 0 }    -- fade out to transparent dark red
  }
}

-- Eye state
eyes.state = {
  leftEyeWinking = false,
  rightEyeWinking = false,
  bothBlinking = false,
  touching = false  -- New state to track if either eye is being touched
}

---Creates and initializes the particle system for the cursor
---@return love.ParticleSystem The initialized particle system
local function initParticleSystem()
  local particleImg = love.graphics.newCanvas(8, 8)
  love.graphics.setCanvas(particleImg)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", 4, 4, 4)
  love.graphics.setCanvas()

  local particleSystem = love.graphics.newParticleSystem(particleImg, 100)

  -- Configure particle system to look like fire
  particleSystem:setParticleLifetime(0.5, 1.2)
  particleSystem:setEmissionRate(60)
  particleSystem:setSizeVariation(0.5)
  particleSystem:setLinearAcceleration(0, -30, 0, -60)
  particleSystem:setSpeed(20, 40)

  -- Apply fire colors from constants
  particleSystem:setColors(unpack(eyes.colors.fire))

  particleSystem:setDirection(-math.pi/2)
  particleSystem:setSpread(math.pi/4)
  particleSystem:setSizes(1.0, 1.5, 0.8)

  -- Start the particle system
  particleSystem:start()

  return particleSystem
end

---Loads resources and initializes the eyes
function eyes.load()
  if checkOnlineStatus() then
    eyes.online_color = eyes.colors.green
    eyes.online_message = "Online"
  end

  -- Initialize the particle system
  eyes.particleSystem = initParticleSystem()

  -- Register particle system with overlayStats
  overlayStats.registerParticleSystem(eyes.particleSystem)

  love.graphics.setFont(love.graphics.newFont(42))
  love.mouse.setVisible(false)
end

function eyes.update(dt)
  eyes.x, eyes.y = love.mouse.getPosition()
  eyes.x = math.floor(eyes.x)
  eyes.y = math.floor(eyes.y)

  -- Update particle system
  eyes.particleSystem:update(dt)
  eyes.particleSystem:setPosition(eyes.x, eyes.y)
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
  drawMouseCursor(windowWidth, font, eyes.x, eyes.y, eyes.colors, eyes.particleSystem)
  drawOnlineStatus(windowWidth, font, eyes.online_color, eyes.online_message)

  love.graphics.pop()
end

return eyes
