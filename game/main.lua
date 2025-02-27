https = nil
i18n = require('lib.smiti18n')
i18n.loadFile('locales/en.lua')
i18n.setLocale('en')
local runtimeLoader = require('runtime.loader')
local Benchmark = require('src.benchmark')
local benchmark

local eyes = require('game.eyes')

function love.load()
  https = runtimeLoader.loadHTTPS()
  eyes.load()
  benchmark = Benchmark:new()
end

function love.draw()
  eyes.draw()
  benchmark:draw()
end

function love.update(dt)
  eyes.update(dt)
  benchmark:handleController(player)
  benchmark:sample()
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  else
    benchmark:handleKeyboard(key)
  end
end
