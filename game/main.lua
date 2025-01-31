local i18n = require 'lib.smiti18n'
local Benchmark = require('src.benchmark')
local benchmark


i18n.loadFile('locales/en.lua')
i18n.setLocale('en')

-- Add at top of file after require
local shakeX, shakeY = 0, 0
local shakeAmount = 5
local eyeSize = 128

-- Add helper function before love.draw
function isMouseOverEye(eyeX, eyeY)
  local mouseX = love.mouse.getX()
  local mouseY = love.mouse.getY()
  local distance = math.sqrt((mouseX - eyeX)^2 + (mouseY - eyeY)^2)
  return distance < eyeSize
end

function love.load()
  -- Initialize benchmark system
  benchmark = Benchmark:new()
  love.graphics.setFont(love.graphics.newFont(42))
  love.mouse.setVisible(false)
  x, y = 0, 0
end

function drawButtons(windowWidth, windowHeight, font)
  -- Button settings
  local buttonWidth = 200
  local buttonHeight = 60
  local buttonSpacing = 20
  local bottomPadding = 50
  local textPadding = 10

  -- Calculate positions
  local spanishX = (windowWidth / 2) - buttonWidth - (buttonSpacing / 2)
  local englishX = (windowWidth / 2) + (buttonSpacing / 2)
  local buttonY = windowHeight - bottomPadding - buttonHeight

  -- Draw Spanish button
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', spanishX, buttonY, buttonWidth, buttonHeight)
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle('line', spanishX, buttonY, buttonWidth, buttonHeight)
  local spanishText = "Spanish"
  local textWidth = font:getWidth(spanishText)
  love.graphics.print(spanishText,
    spanishX + (buttonWidth - textWidth)/2,
    buttonY + textPadding)

  -- Draw English button
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', englishX, buttonY, buttonWidth, buttonHeight)
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle('line', englishX, buttonY, buttonWidth, buttonHeight)
  local englishText = "English"
  textWidth = font:getWidth(englishText)
  love.graphics.print(englishText,
    englishX + (buttonWidth - textWidth)/2,
    buttonY + textPadding)
end

function love.draw()
  function drawEye(eyeX, eyeY, isWinking)
    local eyeSize = 128
    if isWinking then
      love.graphics.setColor(1, 1, 1)
      love.graphics.circle('fill', eyeX, eyeY, eyeSize)
      -- Draw line through center of circle
      love.graphics.setColor(0, 0, .4)
      love.graphics.setLineWidth(8)
      love.graphics.line(
        eyeX - eyeSize,
        eyeY,
        eyeX + eyeSize,
        eyeY
      )
    else
      -- Normal eye drawing logic
      local distanceX = love.mouse.getX() - eyeX
      local distanceY = love.mouse.getY() - eyeY
      local distance = math.min(math.sqrt(distanceX^2 + distanceY^2), eyeSize / 2)
      local angle = math.atan2(distanceY, distanceX)

      local pupilX = eyeX + (math.cos(angle) * distance)
      local pupilY = eyeY + (math.sin(angle) * distance)

      love.graphics.setColor(1, 1, 1)
      love.graphics.circle('fill', eyeX, eyeY, eyeSize)

      love.graphics.setColor(0, 0, .4)
      love.graphics.circle('fill', pupilX, pupilY, 16)
    end
  end

  -- Get window dimensions
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()

  local font = love.graphics.getFont()

  -- Calculate center positions
  local centerY = windowHeight / 2
  local eyeSpacing = 320  -- Distance between eyes
  -- Calculate shake effect
  local leftEyeX = (windowWidth / 2) - (eyeSpacing / 2)
  local rightEyeX = (windowWidth / 2) + (eyeSpacing / 2)
  local centerY = windowHeight / 2

  if isMouseOverEye(leftEyeX, centerY) or isMouseOverEye(rightEyeX, centerY) then
    shakeX = love.math.random(-shakeAmount, shakeAmount)
    shakeY = love.math.random(-shakeAmount, shakeAmount)
  else
    shakeX = 0
    shakeY = 0
  end

  -- Apply shake offset to all drawing
  love.graphics.push()
  love.graphics.translate(shakeX, shakeY)

  local leftButton = love.mouse.isDown(1)
  local rightButton = love.mouse.isDown(2)
  local middleButton = love.mouse.isDown(3)

  -- Determine if both eyes should blink
  local bothBlinking = middleButton or (leftButton and rightButton)

  -- Set individual eye states
  local leftEyeWinking = bothBlinking or (leftButton and not bothBlinking)
  local rightEyeWinking = bothBlinking or (rightButton and not bothBlinking)

  -- Draw eyes
  drawEye(leftEyeX, centerY, leftEyeWinking)
  drawEye(rightEyeX, centerY, rightEyeWinking)
  --drawButtons(windowWidth, windowHeight, font)

  if (shakeX + shakeY) ~= 0 then
    love.graphics.setColor(1, 0.5, 0) -- Orange color
    local text = i18n('Ouch')
    local textWidth = font:getWidth(text)
    local bottomPadding = 256 -- Distance from bottom of screen
    love.graphics.print(
      text,
      (windowWidth - textWidth) / 2,  -- Center horizontally
      windowHeight - bottomPadding    -- Position near bottom
    )
  end

  local padding = 128  -- Padding from screen edges
  if bothBlinking then
    love.graphics.setColor(1, 0, 1)
    -- Show centered "Both Eyes Blinking" text
    local text = i18n('Blink')
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (windowWidth - textWidth) / 2, padding)
  else
    love.graphics.setColor(1, 1, 0)  -- Yellow for individual winks
    -- Left eye status
    if leftEyeWinking then
      local text = i18n('Left Eye') .. " " .. i18n('Wink')
      love.graphics.print(text, padding, padding)
    end

    -- Right eye status
    if rightEyeWinking then
      local text = i18n('Right Eye') .. " " .. i18n('Wink')
      local textWidth = font:getWidth(text)
      love.graphics.print(text, windowWidth - textWidth - padding, padding)
    end
  end

  love.graphics.setColor(1, 1, 1)  -- Reset color for other drawing
  local message = i18n('Mouse') .. " (" .. x .. "," .. y .. ")"

  -- Center the text on the screen
  local textWidth = font:getWidth(message)
  local centerX = (windowWidth / 2) - (textWidth / 2)

  -- Draw a red circle at the mouse's position
  love.graphics.setColor(1, 0, 0)
  love.graphics.circle("fill", x, y, 10)
  -- Draw the message in the center of the screen
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(message, centerX, 32)

  love.graphics.pop() -- Remove shake translation
  -- Draw benchmark overlay last
  benchmark:draw()
end

function love.update(dt)
  benchmark:handleController(player)
  benchmark:sample()
  -- Gets the x- and y-position of the mouse.
  x, y = love.mouse.getPosition()
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  else
    benchmark:handleKeyboard(key)
  end
end
