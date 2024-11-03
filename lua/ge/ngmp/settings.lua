
local M = {}
M.dependencies = {"ngmp_main"}

local categoryIndex = {}
local settings = {}
local defaultSettings = {}

local saveTime = 5
local saveTimer = 0

local function validateDefaultRec(tbl, settingsTbl)
  for k,v in pairs(tbl) do
    if settingsTbl[k] == nil then
      log("W", "ngmp.settings.validate", "Settings key not found, setting default: "..tostring(k))
      settingsTbl[k] = v
    end
    if type(v) == "table" then
      validateDefaultRec(v, settingsTbl[k])
    end
  end
end

local function indexCategoriesRec(parentKey, tbl)
  for k,v in pairs(tbl) do
    if type(v) == "table" then
      local nextParentKey = parentKey.."/"..k
      categoryIndex[nextParentKey] = v
      indexCategoriesRec(nextParentKey, v)
    end
  end
end

local function addCategory(categoryPath)
  local writeTbl = settings
  for i = 1, #categoryPath do
    local cat = categoryPath[i]
    if not writeTbl[cat] then
      writeTbl[cat] = {}
    end
    writeTbl = writeTbl[cat]
  end
  indexCategoriesRec("", settings)
  return writeTbl
end

local function getValue(key, cats, default)
  local readTbl = categoryIndex["/"..(cats and table.concat(cats, "/") or "")]
  if readTbl[key] ~= nil then
    return readTbl[key]
  else
    return default
  end
end

local function setValue(key, value, cats)
  local writeTbl = categoryIndex["/"..(cats and table.concat(cats, "/") or "")]

  -- we probably need to add the category
  if not writeTbl then
    writeTbl = addCategory(cats)
  end

  writeTbl[key] = value
  saveTimer = saveTime
  extensions.hook("onNGMPSettingsChanged")
end

local function save()
  jsonWriteFile(ngmp_main.savePath.."settings.json", settings, true)
end

local function onUpdate(dt)
  if saveTimer > 0 then
    saveTimer = saveTimer - dt
    if saveTimer <= 0 then
      save()
    end
  end
end

local function onExtensionLoaded()
  defaultSettings = jsonReadFile("/ngmp/defaultSettings.json") or defaultSettings
  settings = jsonReadFile(ngmp_main.savePath.."settings.json") or settings

  validateDefaultRec(defaultSettings, settings)

  -- create an index
  -- table lookups are faster than iterations
  categoryIndex["/"] = settings
  indexCategoriesRec("", settings)
end

local function onExtensionUnloaded()
  save()
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.set = setValue
M.get = getValue
M.save = save

return M
