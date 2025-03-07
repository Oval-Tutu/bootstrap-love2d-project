---@class ParallaxBackground Module for handling parallax background layers with horizontal scrolling
local background = {
  layers = {},          -- Will hold all layer data
  width = 2048,         -- Original width of images
  height = 1546,        -- Original height of images
  offset = 0,           -- Current horizontal scroll position
  scrollSpeed = 100,    -- Base horizontal scroll speed in pixels per second
  scaleMode = "contain", -- "contain" fits the entire image, "cover" fills the screen
  maxScale = 1.0,        -- Maximum scaling factor (1.0 = 100% of original size)
}

-- Initialize, load images, set up layers
function background:load()
  -- Clear existing layers if any
  self.layers = {}

  -- Define parallax factors - furthest layer (7) moves slowest, nearest layer (1) moves fastest
  local parallaxFactors = {
    1.0,  -- layer_01 (closest) - moves at 100% speed
    1.0,  -- layer_02
    0.8,  -- layer_03
    0.6,  -- layer_04
    0.4,  -- layer_05
    0.2,  -- layer_06
    0.1   -- layer_07 (furthest) - moves at 10% speed
  }

  -- Define vertical offsets for specific layers (only layer 1 needs adjustment)
  local verticalOffsets = {
    -290, -- layer_01 needs to be elevated by 290px
    0,    -- layer_02
    0,    -- layer_03
    0,    -- layer_04
    0,    -- layer_05
    0,    -- layer_06
    0     -- layer_07
  }

  -- Load all 7 layers
  for i = 1, 7 do
    local layerNum = string.format("%02d", i)
    local layer = {
      image = love.graphics.newImage("eyes/bg/layer_" .. layerNum .. ".png"),
      parallaxFactor = parallaxFactors[i],
      verticalOffset = verticalOffsets[i],
      horizontalOffset = 0,
      -- For layer 7, we conceptually treat it as double width
      effectiveWidth = (i == 7) and (self.width * 2) or self.width
    }
    table.insert(self.layers, layer)
  end
end

---Update layer positions based on elapsed time
---@param dt number Delta time in seconds
function background:update(dt)
  -- Update the base horizontal offset
  self.offset = self.offset + self.scrollSpeed * dt

  -- Update each layer's horizontal position based on its parallax factor and effective width
  for _, layer in ipairs(self.layers) do
    layer.horizontalOffset = (self.offset * layer.parallaxFactor) % layer.effectiveWidth
  end
end

---Draw the background layers
function background:draw()
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()

  -- Calculate scale factors to fit the screen while maintaining aspect ratio
  local scaleX = screenWidth / self.width
  local scaleY = screenHeight / self.height

  -- Determine scale based on selected scaling mode
  local scale
  if self.scaleMode == "contain" then
    scale = math.min(scaleX, scaleY)  -- Ensure entire image fits
  else -- "cover" mode
    scale = math.max(scaleX, scaleY)  -- Ensure entire screen is covered
  end

  -- Apply maximum scale limitation
  scale = math.min(scale, self.maxScale)

  -- Calculate scaled dimensions
  local scaledWidth = self.width * scale
  local scaledHeight = self.height * scale

  -- Position for bottom-left alignment
  local alignX = 0
  local alignY = screenHeight - scaledHeight

  -- Draw layers from back to front (furthest to nearest)
  for i = #self.layers, 1, -1 do
    local layer = self.layers[i]
    -- Round positions to integer pixels to prevent shimmer
    local x = math.floor(alignX - layer.horizontalOffset * scale)
    local y = math.floor(alignY + (layer.verticalOffset * scale))

    -- Reset color for drawing
    love.graphics.setColor(1, 1, 1)

    if i == 7 then -- Special handling for layer 7 (furthest background)
      -- Calculate how many repetitions we need horizontally
      local repsX = math.ceil(screenWidth / scaledWidth) + 2 -- +2 to ensure smooth transitions

      for repX = 0, repsX do
        -- Calculate position for this repetition and round to integer
        local repX_pos = math.floor(x + (repX * scaledWidth * 2))

        -- Draw the image part (first half of the conceptual doubled width)
        love.graphics.draw(
          layer.image,
          repX_pos,
          y,
          0,
          scale,
          scale
        )

        -- Draw the colored rectangle part (second half of the conceptual doubled width)
        love.graphics.setColor(17/255, 13/255, 18/255) -- #110D12
        love.graphics.rectangle(
          "fill",
          repX_pos + scaledWidth,
          y,
          scaledWidth,
          scaledHeight
        )

        -- Reset color
        love.graphics.setColor(1, 1, 1)
      end
    else
      -- Regular layers - calculate how many repetitions we need horizontally
      local repsX = math.ceil(screenWidth / scaledWidth) + 1

      -- Draw the necessary repetitions horizontally for regular layers
      for repX = 0, repsX - 1 do
        -- Round each repetition position to integer pixels
        local repX_pos = math.floor(x + repX * scaledWidth)
        love.graphics.draw(
          layer.image,
          repX_pos,
          y,
          0,
          scale,
          scale
        )
      end
    end
  end
end

---Set horizontal scroll speed
---@param speed number New scroll speed in pixels per second
function background:setSpeed(speed)
  self.scrollSpeed = speed
end

---Set scaling mode and maximum scale
---@param mode string "contain" or "cover" scaling mode
---@param maxScale number Maximum scaling factor
function background:setScaling(mode, maxScale)
  self.scaleMode = mode or self.scaleMode
  self.maxScale = maxScale or self.maxScale
end

return background
