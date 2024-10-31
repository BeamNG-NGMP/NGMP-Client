
local M = {
  name = "input",
  abbreviation = "i",
  author = "DaddelZeit (NGMP Official)"
}

local function get()
  -- use the post-everything-else values
  local data = {
    electrics.values.throttle,
    electrics.values.brake,
    electrics.values.clutch,
    round(electrics.values.parkingbrake),
    electrics.values.steering_input
  }
  return data
end

local function set(data)
  input.event("throttle", data[1], 1)
  input.event("brake", data[2], 2)
  input.event("clutch", data[3], 1)
  input.event("parkingbrake", data[4], 2)
  input.event("steering", data[5], 2, 0, 0)
end

local function onExtensionLoaded()
end

M.set = set
M.get = get
M.onExtensionLoaded = onExtensionLoaded

return M
