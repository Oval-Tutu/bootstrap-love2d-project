local M = {}

-- Get system architecture information
function M.getSystemInfo()
  local os = love.system.getOS():lower():gsub("%s+", "")
  local ffi = require("ffi")
  local arch = ffi.arch
  local is64bit = ffi.abi("64bit")
  local isArm = arch:match("^arm")
  local isX86 = arch:match("^x86") or arch:match("^x64")

  return {
    os = os,
    arch = arch,
    is64bit = is64bit,
    isArm = isArm,
    isX86 = isX86,
  }
end

-- Determine platform-specific subdirectory
function M.getPlatformSubdir(sysInfo)
  if sysInfo.os == "android" then
    if sysInfo.isArm then
      return sysInfo.is64bit and sysInfo.os .. "/arm64-v8a" or sysInfo.os .. "/armeabi-v7a"
    end
  elseif sysInfo.os == "linux" then
    if sysInfo.isX86 and sysInfo.is64bit then
      return sysInfo.os .. "/x86_64"
    end
  elseif sysInfo.os == "osx" then
    return sysInfo.os
  elseif sysInfo.os == "windows" then
    if sysInfo.isX86 then
      return sysInfo.is64bit and sysInfo.os .. "/win64" or sysInfo.os .. "/win32"
    end
  end
  return nil
end

function M.loadNativeLibrary(libraryName)
  local sysInfo = M.getSystemInfo()
  local extension = sysInfo.os == "windows" and ".dll" or ".so"
  local libraryFile = libraryName .. extension
  local subdir = M.getPlatformSubdir(sysInfo)
  if not subdir then
    return nil
  end

  local assetFile = "runtime/" .. libraryName .. "/" .. subdir .. "/" .. libraryFile
  local saveFile = love.filesystem.getSaveDirectory() .. "/" .. libraryFile
  print("Asset File:", assetFile)
  print("Save File:", saveFile)

  -- Check if the library exists for this architecture in the game assets
  if not love.filesystem.getInfo(assetFile) then
    error("Missing: " .. assetFile)
  else
    print("Found: " .. assetFile)
  end

  -- Copy the library from game assets to the save directory
  local libraryData = love.filesystem.read(assetFile)
  if love.filesystem.write(libraryFile, libraryData) then
    print("Copied: " .. assetFile .. " -> " .. saveFile)
  else
    error("Failed: " .. assetFile .. " -> " .. saveFile)
  end
  libraryData = nil

  -- Add the save directory to package.cpath
  package.cpath = package.cpath .. ";" .. love.filesystem.getSaveDirectory() .. "/?." .. extension:sub(2)
  print("package.cpath: " .. package.cpath)

  -- Now try to load it as a regular Lua module
  local status, result = pcall(require, libraryName)
  if status then
    print(libraryFile .. ": loaded")
    return result
  else
    print(libraryFile .. ": failed to load")
    return nil
  end
end

function M.loadHTTPS()
  local major = love.getVersion()
  local os = love.system.getOS()

  if os == "Web" then
    return nil
  elseif major >= 12 then
    return require("https")
  else
    return M.loadNativeLibrary("https")
  end
end

return M
