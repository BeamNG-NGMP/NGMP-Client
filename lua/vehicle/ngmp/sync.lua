
local M = {}

local modulePath = "/lua/vehicle/ngmp/sync"
M.vehId = ""
M.modules = {}
local modules = M.modules -- saves 1 table lookup

local step = 0
local stepSize = 1/50

local function onPhysicsStep(dtPhys)
  step = step + dtPhys
  if step > stepSize then
    step = 0

    local data = {}
    for i=1, #modules do
      data[modules[i].abbreviation] = modules[i].get()
    end

    data.vehId = M.vehId
    obj:queueGameEngineLua(string.format("ngmp_vehicleMgr.sendVehicleData(%q, %q)", M.vehId, jsonEncode(data)))
  end
end

local function set(data)
  for i=1, #modules do
    local moduleData = data[modules[i].abbreviation]
    if moduleData then
      modules[i].set(moduleData)
    end
  end
end

local function onExtensionLoaded()
  enablePhysicsStepHook()

  extensions.reload("ngmp_transformSync")
  for _,v in ipairs(FS:findFiles(modulePath, "*.lua", 0)) do
    local extName = v:match("^.+vehicle/(.+)%.lua"):gsub("/", "_")
    extensions.reload(extName)
    local ext = extensions[extName]
    modules[#modules + 1] = ext
    if not ext.abbreviation then
      ext.abbreviation = ext.name
    end
  end
end

M.set = set
M.onPhysicsStep = onPhysicsStep
M.onExtensionLoaded = onExtensionLoaded

return M