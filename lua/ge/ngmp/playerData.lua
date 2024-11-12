
local M = {}

local im = ui_imgui
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

local ownData
M.steamId = ""
M.playerDataById = {}
M.playerData = {}
M.cacheDir = "/temp/ngmp_playercache/"
M.convertCacheDir = "/temp/ngmp_playercache/convert/"
local convertQueue = {}
local texObjs = {}
local placeHolderTexObj = {}
local downloadedAvatarThisFrame = false

local settingAlwaysSteamIDonHover = false
local settingTransparency = 1

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
    local resFormat = ffi.string(tex:getFormat())
    if resFormat ~= "no_format" then
      texObjs[tblIndex] = {
        texId = tex:getID(),
        size = tex:getSize(),
        format = resFormat,
        tint = im.ImVec4(1, 1, 1, 1),
        tex = tex
      }
    elseif not downloadedAvatarThisFrame then
      local convertTargetFilePath = M.convertCacheDir..tblIndex..".jpg"
      local rawData = ngmp_network.httpGet(string.format("https://avatars.steamstatic.com/%s%s.jpg", avatarHash, suffix))
      if rawData then
        writeFile(convertTargetFilePath, rawData)
        convertQueue[#convertQueue+1] = {convertTargetFilePath, targetFilePath}
        downloadedAvatarThisFrame = true
      end
    end
  end

  return placeHolderTexObj[suffix == "" and "_" or suffix]
end

-- Grayscale images are red?? wtf???
-- we need to fix this. its kind of ass that theres no gpu convert function but oh well
-- having a pfx shader would be proper overkill
local function fixFormat(filepath, resFilepath)
  local bitmap = GBitmap()
  local resBitmap = GBitmap()
  bitmap:loadFile(filepath)
  local x, y = bitmap:getWidth(), bitmap:getHeight()

  resBitmap:init(x,y)
  local tempColor = ColorI(0,0,0,255)
  for row=0, x-1 do
    for col=0, y-1 do
      bitmap:getColor(row,col,tempColor)
      resBitmap:setColor(row,col,tempColor)
    end
  end
  -- this literally doesn't do anything
  --resBitmap:copyRect(bitmap, 1, 1, x, y, 1, 1, x, y)

  FS:removeFile(filepath)
  resBitmap:saveFile(resFilepath)
end

local function renderData(playerData)
  local style = im.GetStyle()
  local avatar = ngmp_playerData.getAvatar(playerData.avatarHash, "medium")
  local sizeFac = ngmp_ui.getPercentVecX(1.25, false, true)/avatar.size.x
  local size = ngmp_ui.mulVec2Num(avatar.size, sizeFac)

  im.BeginGroup()
  im.Image(avatar.texId, size)
  im.SameLine()
  im.SetCursorPosX(im.GetCursorPosX()+style.WindowPadding.x)
  im.PushFont3("cairo_bold")
  im.Text(playerData.name)
  im.PopFont()
  im.EndGroup()

  if settingAlwaysSteamIDonHover then
    im.PushFont3("cairo_regular")
    im.SetWindowFontScale(0.8)
    im.Text(playerData.steamId)
    im.SetWindowFontScale(1)
    im.PopFont()
  end
end

local function renderTooltip(steamId)
  local playerData = M.playerDataById[steamId] or ((ownData and ownData.steamId == steamId) and ownData)
  if playerData then
    im.BeginTooltip()
    renderData(playerData)
    im.EndTooltip()
  end
end

local function getOwnData()
  return ownData
end

local function onUpdate(dt)
  if downloadedAvatarThisFrame then
    for i=1, #convertQueue do
      fixFormat(convertQueue[i][1], convertQueue[i][2])
    end
    convertQueue = {}
    downloadedAvatarThisFrame = false
  end
end

local function stringDiff(str1,str2)
  for i = #str1, 0, -1 do
    if str1:sub(i,i) ~= str2:sub(i,i) then
      return i
    end
  end
  return #str1+1
end

local function set(rawData)
  rawData = rawData or {}
  local newData = {}
  M.playerData = newData
  M.playerDataById = {}

  local names = {}

  local textColor = ColorF(1,1,1,1)
  local bgColor = ColorI(0,0,0,255)
  for _,v in ipairs(rawData.players) do
    local existingPlayer = names[v.name]
    if existingPlayer then
      names[v.name] = nil
      local existingId = existingPlayer.steamId
      local newSteamId = (v.steamId or v.steam_id)
      local diff = stringDiff(existingId, newSteamId)

      existingPlayer.name = existingPlayer.name.." [."..existingPlayer.steamId:sub(diff, #existingPlayer.steamId).."]"
      names[existingPlayer.name] = existingPlayer
      v.name = v.name.." [."..(v.steamId or v.steam_id):sub(diff, #(v.steamId or v.steam_id)).."]"
    end

    --settingTransparency
    newData[#newData+1] = {
      name = v.name,
      steamId = v.steamId or v.steam_id,
      avatarHash = v.avatarHash or v.avatar_hash,

      -- these two are for debugDrawer::drawTextAdvanced(), in which:
      -- - Foreground is ColorF
      -- - Background is ColorI
      -- what the fuck? ...oh well, its beam
      -- defaults are defined above
      nameColor = v.nameColor or (v.textColor and ColorF(v.textColor[1]/255, v.textColor[2]/255, v.textColor[3]/255) or textColor),
      backgroundColor = v.backgroundColor or (v.bgColor and ColorI(v.bgColor[1], v.bgColor[2], v.bgColor[3]) or bgColor)
    }

    names[v.name] = newData[#newData]
    M.playerDataById[v.steam_id or v.steamId] = newData[#newData]
  end

  table.sort(newData, function(a,b)
    return a.name < b.name
  end)
end

local function onNGMPLogin(isLoggedIn, playerName, steamId, avatarHash)
  ownData = {
    name = playerName,
    steamId = steamId,
    avatarHash = avatarHash
  }
  M.steamId = steamId

  ngmp_network.registerPacketDecodeFunc("PD", set)
end

local function onNGMPSettingsChanged()
  settingAlwaysSteamIDonHover = ngmp_settings.get("alwaysSteamIDonHover", {"ui", "generic"})
  settingTransparency = ngmp_settings.get("transparency", {"ui", "vehicleTooltip"})

  for i=1, #M.playerData do
    M.playerData[i].backgroundColor.a = settingTransparency*255
  end
end

local function onExtensionLoaded()
  -- load the default and placeholder avatar images
  -- this is returned by getAvatar when the download/import isnt finished
  for _,v in ipairs(FS:findFiles("/art/ngmp/defaultplayer/", "*.jpg\t*.png", 0, true, false)) do
    local tex = im.ImTextureHandler(v)
    local resFormat = ffi.string(tex:getFormat())
    if resFormat ~= "no_format" then
      placeHolderTexObj[v:match("^.+/(.+)%.(.+)$")] = {
        texId = tex:getID(),
        size = tex:getSize(),
        format = resFormat,
        tint = im.ImVec4(1, 1, 1, 1),
        tex = tex
      }
    end
  end

  onNGMPSettingsChanged()
  setExtensionUnloadMode(M, "manual")
end

M.onNGMPLogin = onNGMPLogin

M.onUpdate = onUpdate
M.onNGMPSettingsChanged = onNGMPSettingsChanged
M.onExtensionLoaded = onExtensionLoaded

M.renderTooltip = renderTooltip
M.renderData = renderData

M.set = set
M.getAvatar = getAvatar
M.getOwnData = getOwnData

return M
