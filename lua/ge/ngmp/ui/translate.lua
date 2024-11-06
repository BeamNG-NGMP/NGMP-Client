
local M = {}

local format = rerequire("ngmp/stringFormat")
local translation

local translationDirTemplate = "/art/ngmp/translations/%s/"
local translationDirDefault = "/art/ngmp/translations/en_US/"
local translations = {}

local translationCache = {}

local function translate(id, context)
  return translations[id] and
  (context and format(translations[id], context) or translations[id])
  or id
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

  -- update all translations
  for k,v in pairs(translationCache) do
    if v[1] then
      for i=1, #v[1] do
        v[1]:update()
      end
    else
      v:update()
    end
  end
end

local TranslationInstance = {}
function TranslationInstance:set(id, context)
  self.id = id
  self.context = context
  self.txt = translate(self.id, self.context)
end

function TranslationInstance:update(context)
  self.context = context and tableMerge(self.context, context) or self.context
  self.txt = translate(self.id, self.context)
end

local function createOrGetTranslationInstance(...)
  local o = {}
  setmetatable(o, TranslationInstance)
  TranslationInstance.__index = TranslationInstance
  o:set(...)
  return o
end

local function onExtensionLoaded()
  onSettingsChanged()
  setmetatable(M, {
    __call = function(self, id, context, force)
      if not force and translationCache[id] then
        return translationCache[id]
      else
        if translationCache[id] then
          if not translationCache[id][1] then
            translationCache[id] = {translationCache[id]}
          end
          translationCache[id][#translationCache[id]+1] = createOrGetTranslationInstance(id, context)
          return translationCache[id][#translationCache[id]]
        else
          translationCache[id] = createOrGetTranslationInstance(id, context)
          return translationCache[id]
        end
      end
    end
  })
end

M.onExtensionLoaded = onExtensionLoaded
M.onSettingsChanged = onSettingsChanged

return M
