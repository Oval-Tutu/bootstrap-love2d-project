---@class ResourceManager Handles loading and managing resources for the eyes module
local ResourceManager = {}
ResourceManager.__index = ResourceManager

-- Constants
local RESOURCE_PATHS = {
  textures = {
    bloodVeins = "eyes/gfx/blood_veins_100.png",
    iris = "eyes/gfx/iris.png",
    pupil = "eyes/gfx/pupil.png",
  },
  shaders = {
    eye = "eyes/shaders/eye.glsl",
  },
  fonts = {
    default = {size = 42},
  }
}

-- Fallback shader source for when loading fails
local FALLBACK_SHADER = [[
  vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    return color;
  }
]]

---Creates a new ResourceManager
---@return ResourceManager
function ResourceManager.new()
  local self = setmetatable({}, ResourceManager)
  self.resources = {
    textures = {},
    shaders = {},
    fonts = {},
  }
  self.loadErrors = {}
  return self
end

---Loads a texture from path with error handling
---@param name string Resource name
---@param path string Path to the texture file
---@return love.Image|nil texture The loaded texture or nil if loading failed
local function loadTexture(name, path)
  local success, result = pcall(function()
    return love.graphics.newImage(path)
  end)

  if success then
    return result
  else
    print("Error loading texture '" .. name .. "': " .. tostring(result))
    return nil
  end
end

---Loads a shader from path with error handling
---@param name string Resource name
---@param path string Path to the shader file
---@return love.Shader shader The loaded shader or fallback shader if loading failed
local function loadShader(name, path)
  local success, result = pcall(function()
    return love.graphics.newShader(path)
  end)

  if success then
    return result
  else
    print("Error loading shader '" .. name .. "': " .. tostring(result))
    -- Return a fallback shader
    return love.graphics.newShader(FALLBACK_SHADER)
  end
end

---Loads all textures defined in RESOURCE_PATHS.textures
---@return table<string, love.Image> The loaded textures
function ResourceManager:loadTextures()
  local textures = {}

  for name, path in pairs(RESOURCE_PATHS.textures) do
    textures[name] = loadTexture(name, path)
  end

  self.resources.textures = textures
  return textures
end

---Loads all shaders defined in RESOURCE_PATHS.shaders
---@return table<string, love.Shader> The loaded shaders
function ResourceManager:loadShaders()
  local shaders = {}

  for name, path in pairs(RESOURCE_PATHS.shaders) do
    shaders[name] = loadShader(name, path)
  end

  self.resources.shaders = shaders
  return shaders
end

---Loads all fonts defined in RESOURCE_PATHS.fonts
---@return table<string, love.Font> The loaded fonts
function ResourceManager:loadFonts()
  local fonts = {}

  for name, config in pairs(RESOURCE_PATHS.fonts) do
    local success, result = pcall(function()
      return love.graphics.newFont(config.size)
    end)

    if success then
      fonts[name] = result
    else
      print("Error loading font '" .. name .. "': " .. tostring(result))
      fonts[name] = love.graphics.getFont() -- Use default font as fallback
    end
  end

  self.resources.fonts = fonts
  return fonts
end

---Loads all resources
---@return ResourceManager self
function ResourceManager:loadAll()
  self:loadTextures()
  self:loadShaders()
  self:loadFonts()
  return self
end

---Gets a loaded texture resource by name
---@param name string Name of the texture
---@return love.Image|nil texture The requested texture or nil if not found
function ResourceManager:getTexture(name)
  return self.resources.textures[name]
end

---Gets a loaded shader resource by name
---@param name string Name of the shader
---@return love.Shader|nil shader The requested shader or nil if not found
function ResourceManager:getShader(name)
  return self.resources.shaders[name]
end

---Gets a loaded font resource by name
---@param name string Name of the font
---@return love.Font|nil font The requested font or nil if not found
function ResourceManager:getFont(name)
  return self.resources.fonts[name]
end

---Sets the default font to the specified font
---@param name string Name of the font to set as default
function ResourceManager:setDefaultFont(name)
  local font = self:getFont(name)
  if font then
    love.graphics.setFont(font)
  end
end

return ResourceManager
