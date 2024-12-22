function love.load()
  love.graphics.setFont(love.graphics.newFont(42))
  x, y = 0, 0
end

function love.draw()
  local message = "Mouse (" .. x .. "," .. y .. ")"

  -- Center the text on the screen
  local font = love.graphics.getFont()
  local textWidth = font:getWidth(message)
  local centerX = (love.graphics.getWidth() / 2) - (textWidth / 2)

  -- Draw a red circle at the mouse's position
  love.graphics.setColor(1, 0, 0)
  love.graphics.circle("fill", x, y, 10)
  -- Draw the message in the center of the screen
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(message, centerX, love.graphics.getHeight() / 2)
  -- Display FPS in the top left corner
  love.graphics.setColor(0, 1, 0)
  love.graphics.print(love.timer.getFPS(), 8, 8)
end

function love.update(dt)
  -- Gets the x- and y-position of the mouse.
  x, y = love.mouse.getPosition()
end
