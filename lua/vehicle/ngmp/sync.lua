
local M = {}

local modulePath = "/lua/vehicle/ngmp/sync"
M.vehFullId = ""
M.mode = "receive"
M.modules = {}
local modules = M.modules -- saves 1 table lookup

local step = 0
M.stepSize = 1/20

local function onPhysicsStep(dtPhys)
  if M.mode == "receive" then return end
  step = step + dtPhys
  if step > M.stepSize then
    step = 0

    local data = {}
    for i=1, #modules do
      data[modules[i].abbreviation] = modules[i].get()
    end

    obj:queueGameEngineLua(string.format("if ngmp_vehicleMgr then ngmp_vehicleMgr.sendVehicleData(%q, %q) end", M.vehFullId, lpack.encode(data)))
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

  enablePhysicsStepHook()
end

M.set = set
M.onPhysicsStep = onPhysicsStep
M.onExtensionLoaded = onExtensionLoaded

return M
