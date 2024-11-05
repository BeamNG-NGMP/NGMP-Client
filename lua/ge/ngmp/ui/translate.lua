
local M = {}

local format = rerequire("ngmp/stringFormat")
local translation

local translationDirTemplate = "/art/ngmp/translations/%s/"
local translationDirDefault = "/art/ngmp/translations/en_US/"
local translations = {}

local function translate(id, context)
  return translations[id] and format(translations[id], context) or id
end

local function onSettingsChanged()
  translations = {}
  local userlang = settings.getValue("userLanguage")
  log("D", "ngmp.translate.load", string.format("Setting language: %s", userlang))
  local translationDir = string.format(translationDirTemplate, userlang)
  for _,translationFile in ipairs(FS:findFiles(translationDirDefault, "*", 0)) do
    local newTranslation = translationFile:gsub(translationDirDefault, translationDir)
    if FS:fileExists(newTranslation) then
      log("D", "ngmp.translate.load", "Loading file: "..newTranslation)
      translations = tableMerge(translations, jsonReadFile(newTranslation) or {})
    else
      log("D", "ngmp.translate.load", string.format("Translation not found for %s, attempting en-US fallback.", newTranslation))
      translations = tableMerge(translations, jsonReadFile(translationFile) or {})
    end
  end
end

local function onExtensionLoaded()
  onSettingsChanged()
  setmetatable(M, {
    __call = function(self, id, context)
      return translate(id, context)
    end
  })
end

M.onExtensionLoaded = onExtensionLoaded
M.onSettingsChanged = onSettingsChanged
rawset(_G, "ngmpTranslate", translate)

return M
