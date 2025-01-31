local name, version, vendor, device = love.graphics.getRendererInfo()
local Benchmark = {
  isActive = false,
  sampleSize = 60,
  vsyncEnabled = nil,
  lastControllerCheck = 0,
  CONTROLLER_COOLDOWN = 0.2,
  renderInfo = {
    name = name,
    version = version,
    vendor = vendor,
    device = device
  },
  metrics = {
    canvases = {},
    canvasSwitches = {},
    drawCalls = {},
    drawCallsBatched = {},
    frameTime = {},
    imageCount = {},
    memoryUsage = {},
    shaderSwitches = {},
    textureMemory = {}
  },
  currentSample = 0
}

function Benchmark:new()
  local bench = setmetatable({}, { __index = Benchmark })
  -- Initialize moving averages
  for k, _ in pairs(self.metrics) do
      bench.metrics[k] = {}
  end
  -- Get initial vsync state from LÖVE config
  bench.vsyncEnabled = love.window.getVSync() == 1
  return bench
end

function Benchmark:sample()
  if not self.isActive then return end

  self.currentSample = self.currentSample + 1
  if self.currentSample > self.sampleSize then
      self.currentSample = 1
  end

  -- Get draw call stats before any drawing occurs
  local stats = love.graphics.getStats()
  self.metrics.canvases[self.currentSample] = stats.canvasses
  self.metrics.canvasSwitches[self.currentSample] = stats.canvasswitches
  self.metrics.drawCalls[self.currentSample] = stats.drawcalls
  self.metrics.drawCallsBatched[self.currentSample] = stats.drawcallsbatched
  self.metrics.imageCount[self.currentSample] = stats.images
  self.metrics.shaderSwitches[self.currentSample] = stats.shaderswitches
  self.metrics.textureMemory[self.currentSample] = stats.texturememory / (1024 * 1024)
  self.metrics.memoryUsage[self.currentSample] = collectgarbage("count")
  self.metrics.frameTime[self.currentSample] = love.timer.getDelta()
end

function Benchmark:getAverages()
  if not self.isActive then return {} end

  local averages = {}
  for metric, samples in pairs(self.metrics) do
      local sum = 0
      local count = 0
      for _, value in ipairs(samples) do
          sum = sum + value
          count = count + 1
      end
      averages[metric] = count > 0 and sum / count or 0
  end
  return averages
end

function Benchmark:draw()
  if not self.isActive then return end

  local averages = self:getAverages()

  -- Set up overlay drawing
  love.graphics.push('all')
  love.graphics.setNewFont(16)
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle('fill', 10, 10, 280, 240)
  love.graphics.setColor(1, 1, 1, 1)

  -- Draw metrics with more detailed stats
  local y = 20
  love.graphics.print(string.format("Renderer: %s (%s)", self.renderInfo.name, self.renderInfo.vendor), 20, y)
  y = y + 20

  love.graphics.print(string.format("%s", self.renderInfo.version), 20, y)
  y = y + 25


  love.graphics.setColor(0, 1, 0, 1)
  love.graphics.print(string.format("FPS: %.1f (%.1fms)",
      1 / averages.frameTime,
      averages.frameTime * 1000), 20, y)
  y = y + 20

  -- Reset canvases each frame
  local currentCanvases = love.graphics.getStats().canvases
  love.graphics.print(string.format("Canvases: %d", currentCanvases), 20, y)
  y = y + 20

  -- Reset canvas switches each frame
  local currentCanvasSwitches = love.graphics.getStats().canvasswitches
  love.graphics.print(string.format("Canvas Switches: %d", currentCanvasSwitches), 20, y)
  y = y + 20

  -- Reset shader switches each frame
  local currentShaderSwitches = love.graphics.getStats().shaderswitches
  love.graphics.print(string.format("Shader Switches: %d", currentShaderSwitches), 20, y)
  y = y + 20

  -- Reset draw calls each frame
  local currentDrawCalls = love.graphics.getStats().drawcalls
  local currentDrawCallsBatched = love.graphics.getStats().drawcallsbatched
  love.graphics.print(string.format("Draw Calls: %d (%d batched)", currentDrawCalls, currentDrawCallsBatched), 20, y)
  y = y + 20

  love.graphics.print(string.format("RAM: %.1f MB", averages.memoryUsage / 1024), 20, y)
  y = y + 20

  -- Reset texture memory usage  each frame
  local currentTextureMemory = love.graphics.getStats().texturememory / (1024 * 1024)
  love.graphics.print(string.format("VRAM: %.1f MB", currentTextureMemory), 20, y)
  y = y + 20

  -- Reset images each frame
  local currentImages = love.graphics.getStats().images
  love.graphics.print(string.format("Images: %d", currentImages), 20, y)
  y = y + 20

  -- Add VSync status with color indication
  love.graphics.setColor(self.vsyncEnabled and {0, 1, 0, 1} or {1, 0, 0, 1})
  love.graphics.print(string.format("VSync: %s", self.vsyncEnabled and "ON" or "OFF"), 20, y)

  love.graphics.pop()
end

function Benchmark:toggle()
  self.isActive = not self.isActive
  -- Reset metrics when toggling
  for k, _ in pairs(self.metrics) do
      self.metrics[k] = {}
  end
  self.currentSample = 0
  print(string.format("Benchmark %s", self.isActive and "enabled" or "disabled"))
end

function Benchmark:toggleVSync()
  if not self.isActive then return end
  self.vsyncEnabled = not self.vsyncEnabled
  love.window.setVSync(self.vsyncEnabled and 1 or 0)
  print(string.format("VSync %s", self.vsyncEnabled and "enabled" or "disabled"))
end

function Benchmark:handleKeyboard(key)
  if key == 'f3' then
    self:toggle()
  elseif key == 'f5' then
    self:toggleVSync()
  end
end

function Benchmark:handleController()
  -- Controller input with cooldown
  local currentTime = love.timer.getTime()
  if currentTime - self.lastControllerCheck < self.CONTROLLER_COOLDOWN then
    return
  end

  local joysticks = love.joystick.getJoysticks()
  for _, joystick in ipairs(joysticks) do
    if joystick:isGamepadDown('back') then
      if joystick:isGamepadDown('a') then
        self:toggle()
        self.lastControllerCheck = currentTime
      elseif joystick:isGamepadDown('b') then
        self:toggleVSync()
        self.lastControllerCheck = currentTime
      end
    end
  end
end

return Benchmark
