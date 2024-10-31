
local M = {
  name = "nodes",
  abbreviation = "n",
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
  local data = {}
  for _, node in pairs(v.data.nodes) do
    local tbl = obj:getNodePosition(node.cid)
    data[#data + 1] = {doubleToBytes(tbl.x),doubleToBytes(tbl.y),doubleToBytes(tbl.z)}
  end
  return next(data) and data or nil
end

local tempVec = vec3()
local function set(data)
  local i = 1
  for _, node in pairs(v.data.nodes) do
    tempVec.x, tempVec.y, tempVec.z = bytesToFloat(data[i][1]), bytesToFloat(data[i][2]), bytesToFloat(data[i][3])
    obj:setNodePosition(node.cid, tempVec)
    i = i + 1
  end
end

local function onExtensionLoaded()
end

M.set = set
M.get = get
M.onExtensionLoaded = onExtensionLoaded

return M