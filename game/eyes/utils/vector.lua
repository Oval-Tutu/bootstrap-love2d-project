---@class Vector Small utility module for vector operations
local vector = {}

---Calculates the distance between two points
---@param x1 number First point x coordinate
---@param y1 number First point y coordinate
---@param x2 number Second point x coordinate
---@param y2 number Second point y coordinate
---@return number distance The distance between the points
function vector.distance(x1, y1, x2, y2)
  local dx, dy = x2 - x1, y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

---Normalizes a vector
---@param x number Vector x component
---@param y number Vector y component
---@return number nx Normalized x component
---@return number ny Normalized y component
function vector.normalize(x, y)
  local length = math.sqrt(x * x + y * y)
  if length > 0 then
    return x / length, y / length
  else
    return 0, 0
  end
end

---Scales a vector by a factor
---@param x number Vector x component
---@param y number Vector y component
---@param scale number Scale factor
---@return number sx Scaled x component
---@return number sy Scaled y component
function vector.scale(x, y, scale)
  return x * scale, y * scale
end

---Clamps a vector to a maximum length
---@param x number Vector x component
---@param y number Vector y component
---@param maxLength number Maximum length
---@return number cx Clamped x component
---@return number cy Clamped y component
function vector.clamp(x, y, maxLength)
  local length = math.sqrt(x * x + y * y)
  if length > maxLength and length > 0 then
    local factor = maxLength / length
    return x * factor, y * factor
  else
    return x, y
  end
end

---Gets the length of a vector
---@param x number Vector x component
---@param y number Vector y component
---@return number length The length of the vector
function vector.length(x, y)
  return math.sqrt(x * x + y * y)
end

return vector
