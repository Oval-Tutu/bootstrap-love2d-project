-- luacheck: globals love
local unpack = unpack or table.unpack -- lua 5.2 compat
local i18n = {}

local store = {} -- translations
local formatConfigs = {} -- format configurations
local locale
local customPluralizeFunction
local defaultLocale = 'en'
local fallbackLocale = defaultLocale

local currentFilePath = (...):gsub("%.init$","")

local format      = require(currentFilePath .. '.format')
local plural      = require(currentFilePath .. '.plural')
local interpolate = require(currentFilePath .. '.interpolate')
local variants    = require(currentFilePath .. '.variants')
local version     = require(currentFilePath .. '.version')

i18n.format = format
i18n.plural = plural
i18n.interpolate = interpolate
i18n.variants = variants
i18n.version = version
i18n._VERSION = version

-- private stuff

-- Pre-compile frequently used patterns
local DOTPLIT_PATTERN = "[^%.]+"
local function dotSplit(str)
  local fields, length = {}, 0
  for part in str:gmatch(DOTPLIT_PATTERN) do
    length = length + 1
    fields[length] = part
  end
  return fields, length
end

local function hasLove()
  local success, loveEngine = pcall(function() return love end)
  return success and type(loveEngine) == 'table' and type(loveEngine.filesystem) == 'table'
end

local function isPluralTable(t)
  return type(t) == 'table' and type(t.other) == 'string'
end

local function isPresent(str)
  return type(str) == 'string' and #str > 0
end

local function isArray(t)
  return type(t) == 'table' and (#t > 0 or next(t) == nil)
end

local function assertPresent(functionName, paramName, value)
  if isPresent(value) then return end

  local msg = "i18n.%s requires a non-empty string on its %s. Got %s (a %s value)."
  error(msg:format(functionName, paramName, tostring(value), type(value)))
end

local function assertPresentOrPlural(functionName, paramName, value)
  if isPresent(value) or isPluralTable(value) or isArray(value) then return end

  local msg = "i18n.%s requires a non-empty string or plural-form table on its %s. Got %s (a %s value)."
  error(msg:format(functionName, paramName, tostring(value), type(value)))
end

local function assertPresentOrTable(functionName, paramName, value)
  if isPresent(value) or type(value) == 'table' then return end

  local msg = "i18n.%s requires a non-empty string or table on its %s. Got %s (a %s value)."
  error(msg:format(functionName, paramName, tostring(value), type(value)))
end

local function assertFunctionOrNil(functionName, paramName, value)
  if value == nil or type(value) == 'function' then return end

  local msg = "i18n.%s requires a function (or nil) on param %s. Got %s (a %s value)."
  error(msg:format(functionName, paramName, tostring(value), type(value)))
end

local function defaultPluralizeFunction(loc, count)
  return plural.get(variants.root(loc), count)
end

local function pluralize(t, loc, data)
  assertPresentOrPlural('interpolatePluralTable', 't', t)
  data = data or {}
  local key
  for _, v in pairs(t) do
    key = interpolate.getInterpolationKey(v, data)
    if key then
      break
    end
  end
  local count = data[key or "count"] or 1
  local plural_form
  if customPluralizeFunction then
    plural_form = customPluralizeFunction(count)
  else
    plural_form = defaultPluralizeFunction(loc, count)
  end
  return t[plural_form]
end

local function treatNode(node, loc, data)
  if isArray(node) then
    local iter = {ipairs(node)}
    node = {}
    for k,v in unpack(iter) do
      node[k] = treatNode(v, loc, data)
    end
  elseif type(node) == 'string' then
    return interpolate(node, data)
  elseif isPluralTable(node) then
    -- Make sure that count has a default of 1
    local newdata = data
    if data.count == nil then
      newdata = {count = 1}  -- Simplified - no need to copy other values
    end
    return interpolate(pluralize(node, loc, newdata), newdata)
  end
  return node
end

local function recursiveLoad(currentContext, data)
  -- Extract _formats before processing translations
  if data._formats then
    if currentContext then
      formatConfigs[currentContext] = data._formats
      format.configure(data._formats)  -- Configure format module immediately
    end
    data._formats = nil
  end

  -- Process translations
  local composedKey
  for k,v in pairs(data) do
    composedKey = (currentContext and (currentContext .. '.') or "") .. tostring(k)
    assertPresent('load', composedKey, k)
    assertPresentOrTable('load', composedKey, v)
    if type(v) == 'string' or isArray(v) then
      i18n.set(composedKey, v)
    else
      recursiveLoad(composedKey, v)
    end
  end
end

local function localizedTranslate(key, loc, data)
  local path, length = dotSplit(loc .. "." .. key)
  local node = store

  for i=1, length do
    node = node[path[i]]
    if not node then return nil end
  end

  return treatNode(node, loc, data)
end

local function appendLocales(primaryLocales, fallbackLocales)
  local primaryLen = #primaryLocales
  local fallbackLen = #fallbackLocales
  -- If both tables are empty, return am empty table
  if primaryLen == 0 and fallbackLen == 0 then
    return {}
  end

  -- If primary is empty, return fallback
  if primaryLen == 0 then
    return fallbackLocales
  end

  -- If fallback is empty, return primary
  if fallbackLen == 0 then
    return primaryLocales
  end

  local result = {}

  for i = 1, primaryLen do
      result[i] = primaryLocales[i]
  end

  for i = 1, fallbackLen do
      result[primaryLen + i] = fallbackLocales[i]
  end

  return result
end

-- public interface

function i18n.set(key, value)
  assertPresent('set', 'key', key)
  assertPresentOrPlural('set', 'value', value)

  local path, length = dotSplit(key)
  local node = store

  for i=1, length-1 do
    key = path[i]
    node[key] = node[key] or {}
    node = node[key]
  end

  local lastKey = path[length]
  node[lastKey] = value
end

function i18n.translate(key, data)
  assertPresent('translate', 'key', key)

  data = data or {}
  local usedLocales
  local locales = locale
  if type(locale) == 'string' then
    locales = {locale}
  end
  if isPresent(data.locale) then
    usedLocales = appendLocales({data.locale}, locales)
  else
    usedLocales = appendLocales({}, locales)
  end

  table.insert(usedLocales, fallbackLocale)
  local fallbacks = variants.fallbacks(usedLocales)
  for i=1, #fallbacks do
    local value = localizedTranslate(key, fallbacks[i], data)
    if value then return value end
  end

  if data.default then
      return interpolate(data.default, data)
  end
end

function i18n.setLocale(newLocale, newPluralizeFunction)
  assertPresentOrTable('setLocale', 'newLocale', newLocale)
  assertFunctionOrNil('setLocale', 'newPluralizeFunction', newPluralizeFunction)
  locale = newLocale
  customPluralizeFunction = newPluralizeFunction

  -- Only use format config if it exists for exact locale
  local loc = type(newLocale) == 'table' and newLocale[1] or newLocale
  format.configure(formatConfigs[loc])  -- Will use ISO defaults if nil
end

function i18n.setFallbackLocale(newFallbackLocale)
  assertPresent('setFallbackLocale', 'newFallbackLocale', newFallbackLocale)
  fallbackLocale = newFallbackLocale
end

function i18n.getFallbackLocale()
  return fallbackLocale
end

function i18n.getLocale()
  return locale
end

function i18n.load(data)
  recursiveLoad(nil, data)
end

function i18n.loadFile(path)
  local data
  if hasLove() then
    -- LÖVE filesystem handling
    local loveEngine = love  -- store reference to avoid luacheck warning
    local contents, readErr = loveEngine.filesystem.read(path)
    if not contents then
      error("Could not load i18n file: " .. tostring(readErr))
    end
    -- Load string as Lua code - use loadstring for 5.1, load for 5.2+
    local chunk, parseErr = (loadstring or load)(contents, path)
    if not chunk then
      error("Could not parse i18n file: " .. tostring(parseErr))
    end
    data = chunk()
  else
    -- Standard Lua file handling
    local chunk, err = loadfile(path)
    if not chunk then
      error("Could not load i18n file: " .. tostring(err))
    end
    data = chunk()
  end

  if type(data) ~= 'table' then
    error("i18n file must return a table")
  end

  i18n.load(data)
end

-- format configuration setters
local function getFormatConfig()
  local loc = locale
  if type(loc) == 'table' then
    loc = loc[1]
  end

  -- Only return exact match, no fallback to other locales
  return formatConfigs[loc]
end

setmetatable(i18n, {__call = function(_, ...) return i18n.translate(...) end})

function i18n.reset()
  store = {}
  formatConfigs = {}
  plural.reset()
  format.configure(nil)  -- Reset to defaults
  i18n.setLocale(defaultLocale)
  i18n.setFallbackLocale(defaultLocale)
end

-- Format function delegations
function i18n.formatNumber(number)
  local cfg = getFormatConfig() or {}
  return format.number(number, cfg.number)
end

function i18n.formatPrice(amount)
  local cfg = getFormatConfig() or {}
  return format.price(amount, cfg.currency)
end

function i18n.formatDate(pattern, date)
  local cfg = getFormatConfig() or {}
  return format.dateTime(pattern, date, cfg.date_time)
end

function i18n.configure(formats)
  format.configure(formats)
end

function i18n.getConfig()
  return format.get_config()
end

return i18n
