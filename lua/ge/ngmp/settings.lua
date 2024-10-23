
local M = {}
M.dependencies = {"ngmp_main"}

local settings = {}
local defaultSettings = {}

local saveTime = 5
local saveTimer = 0

local function getValue(key, default)
  if settings[key] ~= nil then
    return settings[key]
  else
    return default
  end
end

local function getValueRaw(key, default)
  return settings[key]
end

local function setValue(key, value)
  if type(settings[key]) == type(value) then
    settings[key] = value

    saveTimer = saveTime
  end
end

local function onUpdate(dt)
  if saveTimer > 0 then
    saveTimer = saveTimer - dt
    if saveTimer <= 0 then
      jsonWriteFile(ngmp_main.savePath.."settings.json", settings, true)
    end
  end
end

local function onExtensionLoaded()
  defaultSettings = jsonReadFile("/ngmp/defaultSettings.json") or defaultSettings
  settings = jsonReadFile(ngmp_main.savePath.."settings.json") or settings

  for k,v in pairs(defaultSettings) do
    if not settings[k] then
      log("W", "settings", "Settings key not found, setting default: "..tostring(k))
      settings[k] = v
    end
  end
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.set = setValue
M.get = getValue
M.getRaw = getValueRaw

return M