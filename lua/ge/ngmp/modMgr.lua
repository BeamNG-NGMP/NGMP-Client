
-- extension that manages mod mounting/unmounting
local M = {}
M.dependencies = {"ngmp_main"}

M.modsDir = "/temp/ngmp_mods/"
-- genuinely why would you have 2 other mp mods installed
M.blackListedMods = {"ngmp", "translations", "kissmultiplayer", "beammp"}

local cache = {}
-- this is used to rescale the "clear mod cache" button in the settings tab
M.totalSize = 0
M.totalSizeGB = 0

M.modDownloads = {}
local downloadsFinished = 0

local function refreshCache()
  local cacheFiles = FS:findFiles(M.modsDir, "*.zip", 0)
  cache = {}

  local totalSize = 0
  for i=1, #cacheFiles do
    local stat = FS:stat(cacheFiles[i])
    if stat then
      totalSize = totalSize + stat.filesize
    end

    local dir, name, ext = path.splitWithoutExt(cacheFiles[i])
    cache[name] = cacheFiles[i]
  end
  M.totalSize = totalSize
  M.totalSizeGB = totalSize/1000000000
end

local function mount()
  refreshCache()
end

local function unmount()
end

local function updateDownloadState(modName, progress)
  M.modDownloads[modName].progress = progress
  if progress == 1 then
    downloadsFinished = downloadsFinished + 1
  end

  if #M.modDownloads == downloadsFinished then
    mount()
  end
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
  refreshCache()

  ngmp_network.registerPacketDecodeFunc("MP", function(data)
    modDownloads[data.mod_name] = data.progress
  end)

  --ngmp_network.sendPacket("MR", {data = {mod_name}})
  ngmp_network.registerPacketEncodeFunc("MR", function(mod_name)
    return mod_name
  end)
end

M.onExtensionLoaded = onExtensionLoaded
M.refreshCache = refreshCache
M.updateDownloadState = updateDownloadState

return M