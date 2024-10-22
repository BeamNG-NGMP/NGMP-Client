
-- extension that manages mod mounting/unmounting
local M = {}
M.dependencies = {"ngmp_main"}

M.modsDir = "/temp/ngmp_mods/"
M.blackListedMods = {"ngmp", "translations", "kissmultiplayer", "beammp"}

local cache = {}
M.totalSize = 0
M.totalSizeGB = 0

local downloadList = {}
local mountList = {}

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
    cache[name] = {
      fullpath = cacheFiles[i],
      hash = hashStringSHA256(cacheFiles[i])
    }
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

local function verifyInstalledMods(mods)
  refreshCache()

  for i=1, #mods do
    local mod = mods[i]
    local modName = mod[1]

    if arrayFindValueIndex(M.blackListedMods, modName) then
      goto next
    end

    local modCached = cache[modName]
    if modCached and modCached.hash == mod[2] then
      mountList[#mountList+1] = modCached.fullpath
      goto next
    end

    local dbEntry = core_modmanager.getModDB(modName)
    if dbEntry and dbEntry.filename ~= "" and hashStringSHA256(dbEntry.filename) == mod[2] then
      mountList[#mountList+1] = dbEntry.filename
      goto next
    end

    downloadList[#downloadList+1] = {mod[1], mod[2]}

    ::next::
  end

  local downloadListStr = ""
  for i=1, #downloadList do
    if i > 1 then
      downloadListStr = downloadListStr.."/"
    end
    downloadListStr = downloadListStr..table.concat(downloadList[i], ":")

    local dlModName = downloadList[i][1]
    M.modDownloads[dlModName] = {
      progress = 0,
      fullpath = M.modsDir..dlModName,
      targetHash = downloadList[i][2]
    }
  end

  ngmp_network.sendPacket("ML", downloadListStr)
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")

  refreshCache()
end

M.onExtensionLoaded = onExtensionLoaded
M.verifyInstalledMods = verifyInstalledMods
M.refreshCache = refreshCache
M.updateDownloadState = updateDownloadState

return M