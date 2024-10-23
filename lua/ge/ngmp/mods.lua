
-- extension that manages mod mounting/unmounting
local M = {}
M.dependencies = {"ngmp_main"}

M.modsDir = "/temp/ngmp_mods/"
M.blackListedMods = {"ngmp", "translations", "kissmultiplayer", "beammp"}

local cache = {}
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
end

M.onExtensionLoaded = onExtensionLoaded
M.refreshCache = refreshCache
M.updateDownloadState = updateDownloadState

return M