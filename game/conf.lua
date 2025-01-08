local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
  require("lldebugger").start()

  function love.errorhandler(msg)
    error(msg, 2)
  end
end

-- Read product configuration
-- Shared between the game and CI
product_config = {}
for line in love.filesystem.lines("product.env") do
  -- Skip comment lines and blank lines
  if not (line:match("^%s*#") or line:match("^%s*$")) then
    local key, value = line:match("([^=]+)=(.*)")
    if key then
      product_config[key] = value:match('^"?(.-)"?$')
    end
  end
end

-- https://love2d.org/wiki/Config_Files
function love.conf(t)
  t.identity              = product_config["PRODUCT_ID"]
  t.appendidentity        = false
  t.version               = product_config["LOVE_VERSION"]

  -- If t.console is set to true, then the debugger won't work.
  t.console               = false
  t.accelerometerjoystick = false
  t.externalstorage       = false
  t.gammacorrect          = false

  t.audio.mic             = product_config["AUDIO_MIC"]
  t.audio.mixwithsystem   = false

  t.window.title          = product_config["PRODUCT_NAME"]
  t.window.icon           = nil
  t.window.width          = 1920
  t.window.height         = 1080
  t.window.borderless     = false
  t.window.resizable      = false
  t.window.minwidth       = 1
  t.window.minheight      = 1
  t.window.fullscreen     = false
  t.window.fullscreentype = "desktop"
  t.window.vsync          = 1
  t.window.msaa           = 0
  t.window.depth          = nil
  t.window.stencil        = nil
  t.window.display        = 1
  t.window.highdpi        = true
  t.window.usedpiscale    = true
  t.window.x              = nil
  t.window.y              = nil

  t.modules.audio         = true
  t.modules.data          = true
  t.modules.event         = true
  t.modules.font          = true
  t.modules.graphics      = true
  t.modules.image         = true
  t.modules.joystick      = true
  t.modules.keyboard      = true
  t.modules.math          = true
  t.modules.mouse         = true
  t.modules.physics       = true
  t.modules.sound         = true
  t.modules.system        = true
  t.modules.thread        = true
  t.modules.timer         = true
  t.modules.touch         = true
  t.modules.video         = true
  t.modules.window        = true
end
