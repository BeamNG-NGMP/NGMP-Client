
local M = {}

local im = ui_imgui
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

M.playerData = {}
M.cacheDir = "/temp/ngmp_playercache/"
local texObjs = {}
local placeHolderTexObj = {}
local downloadedAvatarThisFrame = false

-- suffix is either nothing or "", "medium", or "full"
local function getAvatar(avatarHash, suffix)
  if avatarHash == "" then return end
  suffix = suffix or ""
  if suffix:len() > 0 then
    suffix = "_"..suffix
  end

  local tblIndex = avatarHash..suffix
  local targetFilePath = M.cacheDir..tblIndex..".jpg"
  if texObjs[tblIndex] then
    return texObjs[tblIndex]
  else
    local tex = im.ImTextureHandler(targetFilePath)
    local successfulLoad = tex:getSize().x > 0
    if successfulLoad then
      texObjs[tblIndex] = {
        id = tex:getID(),
        size = tex:getSize(),
        format = tex:getFormat(),
        tex = tex
      }
    elseif not downloadedAvatarThisFrame then
      local rawData = ngmp_network.httpGet(string.format("https://avatars.steamstatic.com/%s%s.jpg", avatarHash, suffix))
      writeFile(targetFilePath, rawData)
      downloadedAvatarThisFrame = true
    end
  end

  return placeHolderTexObj[suffix == "" and "_" or suffix]
end

local function onUpdate(dt)
  downloadedAvatarThisFrame = false
end

local function set(rawData)
  local newData = {}
  M.playerData = {}

  for _,v in ipairs(rawData) do
    newData[#newData+1] = {
      name = v.name,
      steamId = v.steam_id,
      avatarHash = v.avatar_hash
    }
  end

  table.sort(newData, function(a,b)
    if a.name == b.name then
      return a.steamId < b.steamId
    else
      return a.name < b.name
    end
  end)
end

local function onExtensionLoaded()
  for _,v in ipairs(FS:findFiles("/art/ngmp/defaultplayer/", "*.jpg\t*.png", 0, true, false)) do
    local tex = im.ImTextureHandler(v)
    local successfulLoad = tex:getSize().x > 0
    if successfulLoad then
      placeHolderTexObj[v:match("^.+/(.+)%.(.+)$")] = {
        id = tex:getID(),
        size = tex:getSize(),
        format = tex:getFormat(),
        tex = tex
      }
    end
  end
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded

M.set = set
M.getAvatar = getAvatar

return M