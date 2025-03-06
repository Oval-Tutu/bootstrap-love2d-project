---@class Loader
---A native library loader for LÖVE games
local M = {}

---Gets system architecture information
---@return table systemInfo Table containing OS and architecture details
---@return string systemInfo.os Operating system name in lowercase
---@return string systemInfo.arch Architecture name
---@return boolean systemInfo.is64bit Whether the system is 64-bit
---@return boolean systemInfo.isArm Whether the system uses ARM architecture
---@return boolean systemInfo.isX86 Whether the system uses x86 architecture
local function getSystemInfo()
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

---Determines platform-specific subdirectory for native libraries
---@param sysInfo table System information from getSystemInfo()
---@return string|nil platformSubdir Platform-specific subdirectory or nil if not supported
local function getPlatformSubdir(sysInfo)
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

---Loads a native library from the appropriate platform-specific directory
---@param libraryName string Name of the library to load without extension
---@return table|nil library Loaded library module or nil on failure
function M.loadNativeLibrary(libraryName)
  local sysInfo = getSystemInfo()
  local extension = sysInfo.os == "windows" and ".dll" or ".so"
  local libraryFile = libraryName .. extension
  local subdir = getPlatformSubdir(sysInfo)
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

---Loads the HTTPS library appropriate for the current LÖVE version and platform
---@return table|nil https HTTPS library module or nil if unavailable or on Web platform
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
