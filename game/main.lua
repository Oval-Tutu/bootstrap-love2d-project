https = nil
i18n = require("lib.smiti18n")
i18n.loadFile("locales/en.lua")
i18n.setLocale("en")

local overlayStats = require("lib.overlayStats")
local runtimeLoader = require("runtime.loader")
local eyes = require("eyes.eyes")

function love.load()
  https = runtimeLoader.loadHTTPS()
  eyes.load()
  overlayStats.load() -- Should always be called last
end

function love.draw()
  eyes.draw()
  overlayStats.draw() -- Should always be called last
end

function love.update(dt)
  eyes.update(dt)
  overlayStats.update(dt) -- Should always be called last
end

function love.keypressed(key)
  if key == "escape" and love.system.getOS() ~= "Web" then
    love.event.quit()
  else
    overlayStats.handleKeyboard(key) -- Should always be called last
  end
end
