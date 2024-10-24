
local M = {
  name = "input",
  abbreviation = "i",
  author = "DaddelZeit (NGMP Official)"
}

local function doubleToBytes(num)
  if not num then return end
  return ffi.string(ffi.new("float[1]", num), 4)
end

local tmpFloat = ffi.new("float[1]")
local function bytesToFloat(str)
  ffi.copy(tmpFloat, str, 4)
  return tmpFloat[0]
end

local function get()
  -- use the post-everything-else values
  local data = {
    doubleToBytes(electrics.values.throttle),
    doubleToBytes(electrics.values.brake),
    doubleToBytes(electrics.values.clutch),
    doubleToBytes(electrics.values.parkingbrake),
    doubleToBytes(electrics.values.steering)
  }

  return data
end

local function set(data)
  input.event("throttle", bytesToFloat(data[1]), 1)
  input.event("brake", bytesToFloat(data[2]), 2)
  input.event("parkingbrake", bytesToFloat(data[3]), 2)
  input.event("clutch", bytesToFloat(data[4]), 1)
  input.event("steering", bytesToFloat(data[5]), 2, 0, 0)
end

local function onExtensionLoaded()
end

M.set = set
M.get = get
M.onExtensionLoaded = onExtensionLoaded

return M