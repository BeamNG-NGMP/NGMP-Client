
local M = {}

local modulePath = "/lua/vehicle/ngmp/sync"
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

    --modules
    --for i=1, #modules do
    --  local moduleData = data[modules[i].abbreviation]
    --  if moduleData then
    --    modules[i].set(moduleData)
    --  end
    --end
    print(string.len(lpack.encode(data)))
  end
end

local function onExtensionLoaded()
  for _,v in ipairs(FS:findFiles(modulePath, "*.lua", 0)) do
    local extName = v:match("^.+vehicle/(.+)%.lua"):gsub("/", "_")
    extensions.reload(extName)
    local ext = extensions[extName]
    modules[#modules + 1] = ext
    if not ext.abbreviation then
      ext.abbreviation = ext.name
    end
  end

  if #modules > 1 then
    enablePhysicsStepHook()
  end
end

M.onPhysicsStep = onPhysicsStep
M.onExtensionLoaded = onExtensionLoaded

return M