local eyes = {
  eyeSize = 128,
  eyeSpacing = 320,
  online_color = { 1, 0, 0 },
  online_message = "Offline",
  shakeX = 0,
  shakeY = 0,
  shakeAmount = 5,
  x = 0,
  y = 0,
}

local function isMouseOverEye(eyeX, eyeY)
  local mouseX = love.mouse.getX()
  local mouseY = love.mouse.getY()
  local distance = math.sqrt((mouseX - eyeX) ^ 2 + (mouseY - eyeY) ^ 2)
  return distance < eyes.eyeSize
end

local function drawEye(eyeX, eyeY, isWinking)
  if isWinking then
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", eyeX, eyeY, eyes.eyeSize)
    love.graphics.setColor(0, 0, 0.4)
    love.graphics.setLineWidth(8)
    love.graphics.line(eyeX - eyes.eyeSize, eyeY, eyeX + eyes.eyeSize, eyeY)
  else
    local distanceX = love.mouse.getX() - eyeX
    local distanceY = love.mouse.getY() - eyeY
    local distance = math.min(math.sqrt(distanceX ^ 2 + distanceY ^ 2), eyes.eyeSize / 2)
    local angle = math.atan2(distanceY, distanceX)

    local pupilX = eyeX + (math.cos(angle) * distance)
    local pupilY = eyeY + (math.sin(angle) * distance)

    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", eyeX, eyeY, eyes.eyeSize)

    love.graphics.setColor(0, 0, 0.4)
    love.graphics.circle("fill", pupilX, pupilY, 16)
  end
end

function eyes.load()
  local code, body, headers = nil, nil, nil
  if https then
    code, body, headers = https.request("https://oval-tutu.com")
    if code < 400 then
      eyes.online_color = { 0, 1, 0 }
      eyes.online_message = "Online"
    end
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

  if isMouseOverEye(leftEyeX, centerY) or isMouseOverEye(rightEyeX, centerY) then
    eyes.shakeX = love.math.random(-eyes.shakeAmount, eyes.shakeAmount)
    eyes.shakeY = love.math.random(-eyes.shakeAmount, eyes.shakeAmount)
  else
    eyes.shakeX = 0
    eyes.shakeY = 0
  end

  love.graphics.push()
  love.graphics.translate(eyes.shakeX, eyes.shakeY)

  local leftButton = love.mouse.isDown(1)
  local rightButton = love.mouse.isDown(2)
  local middleButton = love.mouse.isDown(3)

  local bothBlinking = middleButton or (leftButton and rightButton)
  local leftEyeWinking = bothBlinking or (leftButton and not bothBlinking)
  local rightEyeWinking = bothBlinking or (rightButton and not bothBlinking)

  drawEye(leftEyeX, centerY, leftEyeWinking)
  drawEye(rightEyeX, centerY, rightEyeWinking)

  -- Draw status messages
  local padding = 128
  if (eyes.shakeX + eyes.shakeY) ~= 0 then
    love.graphics.setColor(1, 0.5, 0)
    local text = i18n("Ouch")
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (windowWidth - textWidth) / 2, windowHeight - 256)
  end

  if bothBlinking then
    love.graphics.setColor(1, 0, 1)
    local text = i18n("Blink")
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (windowWidth - textWidth) / 2, padding)
  else
    love.graphics.setColor(1, 1, 0)
    if leftEyeWinking then
      local text = i18n("Left Eye") .. " " .. i18n("Wink")
      love.graphics.print(text, padding, padding)
    end
    if rightEyeWinking then
      local text = i18n("Right Eye") .. " " .. i18n("Wink")
      local textWidth = font:getWidth(text)
      love.graphics.print(text, windowWidth - textWidth - padding, padding)
    end
  end

  -- Draw mouse position
  love.graphics.setColor(1, 1, 1)
  local message = i18n("Mouse") .. " (" .. eyes.x .. "," .. eyes.y .. ")"
  local textWidth = font:getWidth(message)
  local centerX = (windowWidth / 2) - (textWidth / 2)

  love.graphics.setColor(1, 0, 0)
  love.graphics.circle("fill", eyes.x, eyes.y, 10)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(message, centerX, 32)

  love.graphics.setColor(eyes.online_color)
  textWidth = font:getWidth(eyes.online_message)
  centerX = (windowWidth / 2) - (textWidth / 2)
  love.graphics.print(eyes.online_message, centerX, 76)

  love.graphics.pop()
end

return eyes
