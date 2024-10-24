
local M = {}
M.dependencies = {"ngmp_main"}

local settings = {}
local defaultSettings = {}

local saveTime = 5
local saveTimer = 0

local function getValue(key, default, cats)
  local writeTbl = settings
  for i = 1, #cats do
    if not writeTbl[cats[i]] then
      return default
    end
    writeTbl = writeTbl[cats[i]]
  end

  if writeTbl[key] ~= nil then
    return writeTbl[key]
  else
    return default
  end
end

local function setValue(key, value, cats)
  local writeTbl = settings
  for i = 1, #cats do
    if not writeTbl[cats[i]] then
      writeTbl = {}
    end
    writeTbl = writeTbl[cats[i]]
  end
  writeTbl[key] = value

  saveTimer = saveTime
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

  local function validateDefaultRec(tbl, settingsTbl)
    for k,v in pairs(tbl) do
      if settingsTbl[k] == nil then
        log("W", "settings", "Settings key not found, setting default: "..tostring(k))
        settingsTbl[k] = v
      end
      if type(v) == "table" then
        validateDefaultRec(v, settingsTbl[k])
      end
    end
  end

  validateDefaultRec(defaultSettings, settings)
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.set = setValue
M.get = getValue

return M