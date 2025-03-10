---@class ColorUtils Utility functions for color manipulation and management
local colorUtils = {}

-- Color palettes for different parts of the application
colorUtils.palettes = {
  -- Eye orb colours
  main = {
    white = { 1.0, 1.0, 1.0 },
    shadedWhite = { 0.8, 0.8, 0.9 },
    lightPink = { 1.0, 0.92, 0.92 },
  },

  -- Iris colours
  eyes = {
    normal = { iris = { 0.0, 0.5, 0.95 } }, -- Blue
    online = { iris = { 0.0, 0.8, 0.2 } },  -- Green
    touched = { iris = { 0.6, 0.0, 0.0 } }    -- Dark red
  },

  -- Eye reflection colors
  reflections = {
    main = { 1.0, 0.95, 0.8 },     -- Warm yellow
    core = { 1.0, 1.0, 0.9 }         -- Bright yellow-white
  }
}

---Creates a new color object
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a? number Alpha component (0-1), defaults to 1
---@return table color Color object {r, g, b, a}
function colorUtils.rgb(r, g, b, a)
  return {r, g, b, a or 1}
end

---Converts a color to LÖVE format (array of values)
---@param color table Color table {r, g, b, a} or {r, g, b}
---@return table color LÖVE-compatible color format {r, g, b, a}
function colorUtils.toLoveColor(color)
  -- If the color already has the right format, return it directly
  if type(color[1]) == "number" then
    return {color[1], color[2], color[3], color[4] or 1}
  end

  return {color.r or color[1], color.g or color[2], color.b or color[3], color.a or color[4] or 1}
end

---Interpolates between two colors based on a factor (0 to 1)
---@param color1 table First color {r, g, b} or {r, g, b, a}
---@param color2 table Second color {r, g, b} or {r, g, b, a}
---@param factor number Interpolation factor (0 = color1, 1 = color2)
---@return table Interpolated color {r, g, b, a}
function colorUtils.lerp(color1, color2, factor)
  factor = math.max(0, math.min(1, factor)) -- Clamp factor between 0 and 1

  -- Convert to array format if needed
  color1 = colorUtils.toLoveColor(color1)
  color2 = colorUtils.toLoveColor(color2)

  local r = color1[1] + (color2[1] - color1[1]) * factor
  local g = color1[2] + (color2[2] - color1[2]) * factor
  local b = color1[3] + (color2[3] - color1[3]) * factor

  -- Handle alpha if present
  local a = 1
  if color1[4] and color2[4] then
    a = color1[4] + (color2[4] - color1[4]) * factor
  elseif color1[4] then
    a = color1[4]
  elseif color2[4] then
    a = color2[4]
  end

  return {r, g, b, a}
end

---Lightens a color by specified amount
---@param color table Color to lighten {r, g, b} or {r, g, b, a}
---@param amount number Amount to lighten (0-1)
---@return table Lightened color {r, g, b, a}
function colorUtils.lighten(color, amount)
  color = colorUtils.toLoveColor(color)
  local white = {1, 1, 1, color[4] or 1}
  return colorUtils.lerp(color, white, amount)
end

---Darkens a color by specified amount
---@param color table Color to darken {r, g, b} or {r, g, b, a}
---@param amount number Amount to darken (0-1)
---@return table Darkened color {r, g, b, a}
function colorUtils.darken(color, amount)
  color = colorUtils.toLoveColor(color)
  local black = {0, 0, 0, color[4] or 1}
  return colorUtils.lerp(color, black, amount)
end

---Adjusts color alpha
---@param color table Color to adjust {r, g, b} or {r, g, b, a}
---@param alpha number New alpha value (0-1)
---@return table Color with adjusted alpha {r, g, b, a}
function colorUtils.withAlpha(color, alpha)
  color = colorUtils.toLoveColor(color)
  return {color[1], color[2], color[3], alpha}
end

---Gets a color from a palette by name
---@param paletteName string The name of the palette
---@param colorName string The name of the color within the palette
---@return table|nil color The requested color or nil if not found
function colorUtils.getColor(paletteName, colorName)
  local palette = colorUtils.palettes[paletteName]
  if not palette then
    return nil
  end

  -- Handle nested palettes (e.g. "eyes.normal.iris")
  if colorName:find("%.") then
    local parts = {}
    for part in colorName:gmatch("[^%.]+") do
      table.insert(parts, part)
    end

    local current = palette
    for i = 1, #parts do
      if type(current) ~= "table" then
        return nil
      end
      current = current[parts[i]]
      if not current then
        return nil
      end
    end

    return colorUtils.toLoveColor(current)
  end

  local color = palette[colorName]
  if color then
    return colorUtils.toLoveColor(color)
  end

  return nil
end

---Gets a main color by name (shortcut for getColor("main", name))
---@param name string The name of the color within the main palette
---@return table|nil color The requested color or nil if not found
function colorUtils.getMainColor(name)
  return colorUtils.getColor("main", name)
end

return colorUtils
