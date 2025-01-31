local format = {}

local DEFAULT_NAMES = {
  short_month_names = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  },
  long_month_names = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  },
  short_day_names = {
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
  },
  long_day_names = {
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday"
  }
}

-- Private variables
local config = {}
local default_config = {
  currency = {
    symbol = "XXX",
    name = "Currency",
    short_name = "XXX",
    decimal_symbol = ".",         -- ISO standard decimal point
    thousand_separator = " ",     -- ISO standard space
    fract_digits = 2,
    positive_symbol = "",
    negative_symbol = "-",
    positive_format = "%c %p%q",
    negative_format = "%c %p%q"
  },
  number = {
    decimal_symbol = ".",         -- ISO standard decimal point
    thousand_separator = " ",     -- ISO standard space
    fract_digits = 2,
    positive_symbol = "",
    negative_symbol = "-"
  },
  date_time = {
    long_time = "%H:%M:%S",
    short_time = "%H:%M",
    long_date = "%B %d, %Y",
    short_date = "%m/%d/%Y",
    long_date_time = "%B %d, %Y %H:%M:%S",
    short_date_time = "%m/%d/%Y %H:%M"
  },
  short_month_names = DEFAULT_NAMES.short_month_names,
  long_month_names = DEFAULT_NAMES.long_month_names,
  short_day_names = DEFAULT_NAMES.short_day_names,
  long_day_names = DEFAULT_NAMES.long_day_names
}

-- Helper functions
local function separateThousand(amount, separator)
  local formatted = amount
  while true do
    local k
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1' .. separator .. '%2')
    if k == 0 then break end
  end
  return formatted
end

local function round(val, decimal)
  return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
end

local function formatNum(amount, digits, separator, decimal)
  digits = tonumber(digits) or 0  -- Ensure digits is a number
  local famount = math.floor(math.abs(round(amount, digits)))
  local remain = round(math.abs(amount) - famount, digits)
  local formatted = separateThousand(famount, separator)

  if digits > 0 then
    remain = string.sub(tostring(remain), 3)
    formatted = formatted .. decimal .. remain .. string.rep("0", digits - #remain)
  end

  return formatted
end

-- Configuration functions
function format.configure(formats)
  -- Always start with default config
  config = {}
  -- Since we know all default_config entries are tables
  for k,v in pairs(default_config) do
    config[k] = {}
    for k2,v2 in pairs(v) do
      config[k][k2] = v2
    end
  end

  -- Override with provided formats
  if formats then
    for k,v in pairs(formats) do
      if type(v) == 'table' then
        config[k] = config[k] or {}
        for k2,v2 in pairs(v) do
          config[k][k2] = v2
        end
      end
    end
  end
end

function format.get_config()
  return config
end

-- Main formatting functions
local function getConfigSection(section, cfg)
  return cfg or (config[section] or default_config[section])
end

function format.number(number, cfg)
  local config_section = getConfigSection('number', cfg)
  local digits = config_section.fract_digits
  if digits == nil then digits = 2 end  -- Default to 2 for ISO standard
  local separator = config_section.thousand_separator or " "
  local decimal = config_section.decimal_symbol or "."
  local polarity = number < 0 and (config_section.negative_symbol or "-") or (config_section.positive_symbol or "")

  return polarity .. formatNum(math.abs(number), digits, separator, decimal)
end

function format.price(amount, cfg)
  local cfg_section = getConfigSection('currency', cfg)
  local digits = cfg_section.fract_digits or 2
  local separator = cfg_section.thousand_separator or " "
  local decimal = cfg_section.decimal_symbol or "."
  local symbol = cfg_section.symbol or "XXX"
  local polarity = amount < 0 and
    (cfg_section.negative_symbol or "-") or (cfg_section.positive_symbol or "")
  local pattern = amount < 0 and
    (cfg_section.negative_format or "%c %p%q") or (cfg_section.positive_format or "%c %p%q")

  -- Validate pattern has required components
  if not pattern:match("%%c") or not pattern:match("%%q") then
    -- If pattern is invalid, fall back to default pattern
    pattern = amount < 0 and default_config.currency.negative_format or default_config.currency.positive_format
  end

  -- Format the number first
  local formatted_number = formatNum(math.abs(amount), digits, separator, decimal)

  -- Apply the pattern substitutions in correct order
  return pattern:gsub("%%p", polarity)
                :gsub("%%q", formatted_number)
                :gsub("%%c", symbol)
end

local function getNameArray(arrayType)
  -- Either use configured values or fall back to English defaults
  -- No explicit nil handling - simple fallback
  return config[arrayType] or DEFAULT_NAMES[arrayType]
end

function format.dateTime(pattern, date, cfg)
  local date_time = date or os.date("*t")
  local config_section = getConfigSection('date_time', cfg)

  -- Get pattern from config or use default ISO format
  if not pattern then
    pattern = "%Y-%m-%dT%H:%M:%S"  -- ISO 8601
  elseif config_section[pattern] then
    pattern = config_section[pattern]
  end

  -- Guard against nil values in date_time
  local hour = tonumber(date_time.hour) or 0
  local min = tonumber(date_time.min) or 0
  local sec = tonumber(date_time.sec) or 0
  local day = tonumber(date_time.day) or 1
  local month = tonumber(date_time.month) or 1
  local year = tonumber(date_time.year) or 1970
  local wday = tonumber(date_time.wday) or 1

  -- Get name arrays with fallbacks
  local long_days = getNameArray('long_day_names')
  local long_months = getNameArray('long_month_names')
  local short_days = getNameArray('short_day_names')
  local short_months = getNameArray('short_month_names')

  -- Format with custom substitutions (remove redundant result variable)
  return pattern:gsub("%%H", string.format("%02d", hour))
                :gsub("%%M", string.format("%02d", min))
                :gsub("%%i", string.format("%02d", min))
                :gsub("%%S", string.format("%02d", sec))
                :gsub("%%s", string.format("%02d", sec))
                :gsub("%%d", string.format("%02d", day))
                :gsub("%%m", string.format("%02d", month))
                :gsub("%%Y", tostring(year))
                :gsub("%%l", long_days[wday] or DEFAULT_NAMES.long_day_names[wday] or "")
                :gsub("%%F", long_months[month] or DEFAULT_NAMES.long_month_names[month] or "")
                :gsub("%%a", short_days[wday] or DEFAULT_NAMES.short_day_names[wday] or "")
                :gsub("%%b", short_months[month] or DEFAULT_NAMES.short_month_names[month] or "")
end

return format
