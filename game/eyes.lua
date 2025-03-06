---@class Eyes Module for drawing and managing interactive eyes
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
}

-- Constants
eyes.colors = {
  white = { 1, 1, 1 },
  blue = { 0, 0, 0.4 },
  yellow = { 1, 1, 0 },
  orange = { 1, 0.5, 0 },
  red = { 1, 0, 0 },
  purple = { 1, 0, 1 },
  green = { 0, 1, 0 }
}

-- Eye state
eyes.state = {
  leftEyeWinking = false,
  rightEyeWinking = false,
  bothBlinking = false
}

---Checks if the mouse is over an eye
---@param eyeX number The x-coordinate of the eye
---@param eyeY number The y-coordinate of the eye
---@return boolean isOver True if mouse is over the eye
function eyes.isMouseOverEye(eyeX, eyeY)
  local mouseX = love.mouse.getX()
  local mouseY = love.mouse.getY()
  local distance = math.sqrt((mouseX - eyeX) ^ 2 + (mouseY - eyeY) ^ 2)
  return distance < eyes.eyeSize
end

---Draws a single eye
---@param eyeX number The x-coordinate of the eye
---@param eyeY number The y-coordinate of the eye
---@param isWinking boolean Whether the eye is winking
function eyes.drawEye(eyeX, eyeY, isWinking)
  if isWinking then
    love.graphics.setColor(eyes.colors.white)
    love.graphics.circle("fill", eyeX, eyeY, eyes.eyeSize)
    love.graphics.setColor(eyes.colors.blue)
    love.graphics.setLineWidth(8)
    love.graphics.line(eyeX - eyes.eyeSize, eyeY, eyeX + eyes.eyeSize, eyeY)
  else
    local distanceX = love.mouse.getX() - eyeX
    local distanceY = love.mouse.getY() - eyeY
    local distance = math.min(math.sqrt(distanceX ^ 2 + distanceY ^ 2), eyes.eyeSize / 2)
    local angle = math.atan2(distanceY, distanceX)

    local pupilX = eyeX + (math.cos(angle) * distance)
    local pupilY = eyeY + (math.sin(angle) * distance)

    love.graphics.setColor(eyes.colors.white)
    love.graphics.circle("fill", eyeX, eyeY, eyes.eyeSize)

    love.graphics.setColor(eyes.colors.blue)
    love.graphics.circle("fill", pupilX, pupilY, 16)
  end
end

---Draws status messages based on eye state
---@param windowWidth number Width of the window
---@param windowHeight number Height of the window
---@param font love.Font The font to use for messages
function eyes.drawStatusMessages(windowWidth, windowHeight, font)
  local padding = 128

  -- Draw "Ouch" message when eyes are shaking
  if (eyes.shakeX + eyes.shakeY) ~= 0 then
    love.graphics.setColor(eyes.colors.orange)
    local text = i18n("Ouch")
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (windowWidth - textWidth) / 2, windowHeight - 256)
  end

  -- Draw blinking/winking messages
  if eyes.state.bothBlinking then
    love.graphics.setColor(eyes.colors.purple)
    local text = i18n("Blink")
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (windowWidth - textWidth) / 2, padding)
  else
    love.graphics.setColor(eyes.colors.yellow)
    if eyes.state.leftEyeWinking then
      local text = i18n("Left Eye") .. " " .. i18n("Wink")
      love.graphics.print(text, padding, padding)
    end
    if eyes.state.rightEyeWinking then
      local text = i18n("Right Eye") .. " " .. i18n("Wink")
      local textWidth = font:getWidth(text)
      love.graphics.print(text, windowWidth - textWidth - padding, padding)
    end
  end
end

---Draws the mouse cursor position text and cursor dot
---@param windowWidth number Width of the window
---@param font love.Font The font to use for messages
function eyes.drawMouseCursor(windowWidth, font)
  love.graphics.setColor(eyes.colors.red)
  love.graphics.circle("fill", eyes.x, eyes.y, 10)

  love.graphics.setColor(eyes.colors.white)
  local message = i18n("Mouse") .. " (" .. eyes.x .. "," .. eyes.y .. ")"
  local textWidth = font:getWidth(message)
  local centerX = (windowWidth / 2) - (textWidth / 2)
  love.graphics.print(message, centerX, 32)
end

---Draws the online status message
---@param windowWidth number Width of the window
---@param font love.Font The font to use for messages
function eyes.drawOnlineStatus(windowWidth, font)
  love.graphics.setColor(eyes.online_color)
  local textWidth = font:getWidth(eyes.online_message)
  local centerX = (windowWidth / 2) - (textWidth / 2)
  love.graphics.print(eyes.online_message, centerX, 76)
end

---Updates the online status by performing a network request
---@return boolean isOnline True if the site is online
function eyes.checkOnlineStatus()
  if not https then return false end

  local success, result = pcall(function()
    local code, body, headers = https.request("https://oval-tutu.com")
    return { code = code, body = body, headers = headers }
  end)

  return success and result and result.code and result.code < 400
end

---Updates the eye state based on input
function eyes.updateEyeState()
  local leftButton = love.mouse.isDown(1)
  local rightButton = love.mouse.isDown(2)
  local middleButton = love.mouse.isDown(3)

  eyes.state.bothBlinking = middleButton or (leftButton and rightButton)
  eyes.state.leftEyeWinking = eyes.state.bothBlinking or (leftButton and not eyes.state.bothBlinking)
  eyes.state.rightEyeWinking = eyes.state.bothBlinking or (rightButton and not eyes.state.bothBlinking)
end

---Updates the shake effect when mouse is over eyes
---@param leftEyeX number The x-coordinate of the left eye
---@param rightEyeX number The x-coordinate of the right eye
---@param centerY number The y-coordinate of both eyes
function eyes.updateShakeEffect(leftEyeX, rightEyeX, centerY)
  if eyes.isMouseOverEye(leftEyeX, centerY) or eyes.isMouseOverEye(rightEyeX, centerY) then
    eyes.shakeX = love.math.random(-eyes.shakeAmount, eyes.shakeAmount)
    eyes.shakeY = love.math.random(-eyes.shakeAmount, eyes.shakeAmount)
  else
    eyes.shakeX = 0
    eyes.shakeY = 0
  end
end

---Loads resources and initializes the eyes
function eyes.load()
  if eyes.checkOnlineStatus() then
    eyes.online_color = eyes.colors.green
    eyes.online_message = "Online"
  end

  love.graphics.setFont(love.graphics.newFont(42))
  love.mouse.setVisible(false)
end

function eyes.update(dt)
  eyes.x, eyes.y = love.mouse.getPosition()
  eyes.x = math.floor(eyes.x)
  eyes.y = math.floor(eyes.y)
end

function eyes.draw()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local font = love.graphics.getFont()
  local centerY = windowHeight / 2
  local leftEyeX = (windowWidth / 2) - (eyes.eyeSpacing / 2)
  local rightEyeX = (windowWidth / 2) + (eyes.eyeSpacing / 2)

  eyes.updateShakeEffect(leftEyeX, rightEyeX, centerY)

  love.graphics.push()
  love.graphics.translate(eyes.shakeX, eyes.shakeY)

  eyes.updateEyeState()

  eyes.drawEye(leftEyeX, centerY, eyes.state.leftEyeWinking)
  eyes.drawEye(rightEyeX, centerY, eyes.state.rightEyeWinking)

  eyes.drawStatusMessages(windowWidth, windowHeight, font)
  eyes.drawMouseCursor(windowWidth, font)
  eyes.drawOnlineStatus(windowWidth, font)

  love.graphics.pop()
end

return eyes
