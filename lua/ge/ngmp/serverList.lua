
-- extension that stores the server list and applies filters to it

local M = {}

M.favorites = {}
M.recents = {}
M.availableLevels = {}
local serverList = {}

local filterFuncs = {
  searchQuery = function(server, ip, query)
    local searchString = (server.name..server.level):gsub("%s",""):lower()
    return searchString:match(query:lower()) ~= nil
  end,
  empty = function(server)
    return #server.players == 0
  end,
  notEmpty = function(server)
    return #server.players > 0
  end,
  notFull = function(server)
    return #server.players < server.max_players
  end,
  level = function(server, ip, level)
    return server.level:match(level) ~= nil
  end,
  favorite = function(server, ip)
    return M.favorites[ip]
  end,
}

local sortFuncs = {
  alphabetical = function(a,b)
    return serverList[a].name < serverList[b].name
  end,
  time = function(a,b)
    return (M.recents[a] or 0) > (M.recents[b] or 0)
  end
}

local function filter(filters, sortBy)
  local filteredList = {}

  for ip, server in pairs(serverList) do
    local fitsFilter = true
    for filterKey, filterVal in pairs(filters or {}) do
      if filterVal then
        if (type(filterVal) == "function" and not filterVal(server)) or (filterFuncs[filterKey] and not filterFuncs[filterKey](server, ip, filterVal)) then
          fitsFilter = false
          break
        end
      end
    end

    if fitsFilter then
      filteredList[ip] = server
    end
  end

  local keys = tableKeys(filteredList)
  if sortBy == "time" then
    local _keys = {}
    for i=1, #keys do
      if M.recents[keys[i]] then
        _keys[#_keys+1] = keys[i]
      end
    end
    keys = _keys
  end

  table.sort(keys, sortFuncs[sortBy or "alphabetical"])
  return filteredList, keys
end

local function onNGMPJoinServer(ip)
  M.recents[ip] = os.time()
  jsonWriteFile(ngmp_main.savePath.."recents.json", M.recents, true)
end

local function setFavorite(ip, bool)
  M.favorites[ip] = bool
  jsonWriteFile(ngmp_main.savePath.."favorites.json", M.favorites, true)
end

local function set(newList)
  newList = newList or {}

  local _levels = {}
  local availableLevels = {}
  for k,v in pairs(newList) do
    if not _levels[v.level] then
      availableLevels[#availableLevels + 1] = {v.level:match("/levels/(.*)/"), v.level}
    end
    _levels[v.level] = true
  end
  M.availableLevels = availableLevels

  serverList = newList
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")

  M.favorites = jsonReadFile(ngmp_main.savePath.."favorites.json") or {}
  M.recents = jsonReadFile(ngmp_main.savePath.."recents.json") or {}

  set(jsonReadFile("/ngmp/serverlist.json"))
end

M.set = set
M.setFavorite = setFavorite
M.filter = filter
M.onNGMPJoinServer = onNGMPJoinServer
M.onExtensionLoaded = onExtensionLoaded

return M
