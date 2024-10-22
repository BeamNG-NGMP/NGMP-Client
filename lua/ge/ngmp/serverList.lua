
-- extension that stores the server list and applies filters to it

local M = {}

local serverList = {}
local filterFuncs = {
  searchQuery = function(server, query)
    local searchString = (server.name..server.level):gsub("%s",""):lower()
    return searchString:match(query:lower()) ~= nil
  end,
  empty = function(server)
    return server.pCount == 0
  end,
  notEmpty = function(server)
    return server.pCount > 0
  end,
  notFull = function(server)
    return server.pCount < server.pCapacity
  end,
  level = function(server, level)
    return server.level:match(level) ~= nil
  end
}

local function filter(filters)
  local filteredList = {}

  for i=1, #serverList do
    local server = serverList[i]
    local fitsFilter = true
    for filter, filterVal in pairs(filters or {}) do
      if filterVal and filterFuncs[filter] and not filterFuncs[filter](server, filterVal) then
        fitsFilter = false
        break
      end
    end

    if fitsFilter then
      filteredList[#filteredList+1] = server
    end
  end
end

local function set(newList)
  serverList = newList
  setExtensionUnloadMode(M, "manual")
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
end

M.set = set
M.filter = filter

M.onExtensionLoaded = onExtensionLoaded

return M