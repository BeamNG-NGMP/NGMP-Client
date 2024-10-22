
-- extension that dispatches ui calls and includes helper funcs
local M = {}

M.dependencies = {"ngmp_main", "ui_imgui"}
local C = ffi.C

local style = rerequire("ngmp/ui/style")
local im = ui_imgui
local imguiUtils = require('ui/imguiUtils')

-- IMVEC2 MATH
local function addVec2(a,b)
  return im.ImVec2(a.x+b.x,a.y+b.y)
end

local function subVec2(a,b)
  return im.ImVec2(a.x-b.x,a.y-b.y)
end

local function lengthSqrVec2(a)
  local ax, ay = a.x, a.y
  return ax*ax + ay*ay
end

local function avgVec2(a,b)
  return im.ImVec2((a.x+b.x)/2,(a.y+b.y)/2)
end

local function dotVec2(a, b)
  return a.x * b.x + a.y * b.y
end

local function mulVec2Num(vec2, num)
  return im.ImVec2(vec2.x*num,vec2.y*num)
end
--

-- SHORTCUTS
M.bngCol = im.ImVec4(1,0.4,0,1)
M.bngCol32 = im.GetColorU322(M.bngCol)
local mainSizePos = {}

local function getMainSizePos()
  return mainSizePos[1], mainSizePos[2]
end

local function getGlobalVec(inputX, inputY)
  local _, pos = getMainSizePos()
  if inputY then
    return im.ImVec2(inputX+pos.x, inputY+pos.y)
  else
    return im.ImVec2(inputX.x+pos.x, inputX.y+pos.y)
  end
end

local function getGlobalVecX(inputX)
  local _, pos = getMainSizePos()
  return inputX+pos.x
end

local function getGlobalVecY(inputY)
  local _, pos = getMainSizePos()
  return inputY+pos.y
end

local function getPercentVec(inputX, inputY, useWindow, addPos)
  local size, pos = getMainSizePos()
  if useWindow then size = im.GetWindowSize() else size = size end
  if addPos then pos = im.ImVec2(0,0) end
  return im.ImVec2((inputX/100*size.x)+pos.x, (inputY/100*size.y)+pos.y)
end

local function getPercentVecX(input, useWindow, addPos)
  local size, pos = getMainSizePos()
  if useWindow then size = im.GetWindowSize() else size = size end
  if addPos then pos = im.ImVec2(0,0) end
  return (input/100*size.x)+pos.x
end

local function getPercentVecY(input, useWindow, addPos)
  local size, pos = getMainSizePos()
  if useWindow then size = im.GetWindowSize() else size = size end
  if addPos then pos = im.ImVec2(0,0) end
  return (input/100*size.y)+pos.y
end

local function primaryButton(string_label, ImVec2_size)
  if ImVec2_size == nil then ImVec2_size = im.ImVec2(0,0) end
  if string_label == nil then log("E", "", "Parameter 'string_label' of function 'Button' cannot be nil, as the c type is 'const char *'") ; return end
  C.imgui_PushStyleVar2(im.StyleVar_FramePadding, im.ImVec2(6,2))
  C.imgui_PushStyleColor1(im.Col_Button, M.bngCol32)
  local retVal = C.imgui_Button(string_label, ImVec2_size)
  C.imgui_PopStyleColor(1)
  C.imgui_PopStyleVar(1)
  if C.imgui_IsItemHovered(0) then
    C.imgui_SetMouseCursor(im.MouseCursor_Hand)
  end
  return retVal
end

local function button(string_label, ImVec2_size)
  if ImVec2_size == nil then ImVec2_size = im.ImVec2(0,0) end
  if string_label == nil then log("E", "", "Parameter 'string_label' of function 'Button' cannot be nil, as the c type is 'const char *'") ; return end
  C.imgui_PushStyleVar2(im.StyleVar_FramePadding, im.ImVec2(6,2))
  local retVal = C.imgui_Button(string_label, ImVec2_size)
  C.imgui_PopStyleVar(1)
  if C.imgui_IsItemHovered(0) then
    C.imgui_SetMouseCursor(im.MouseCursor_Hand)
  end
  return retVal
end

local function calculateButtonSize(text)
  local textSize = im.CalcTextSize(text or "")
  return im.ImVec2(textSize.x+6, textSize.y+2)
end
--

local function onUpdate(dtReal, dtSim, dtRaw)
  --timer:reset()
  local size = split(core_settings_graphic.selected_resolution, " ")
  mainSizePos[1] = im.ImVec2(tonumber(size[1]), tonumber(size[2]))
  mainSizePos[2] = im.GetMainViewport().Pos
  M.uiscale = math.max(mainSizePos[1].x/1920, mainSizePos[1].y/1080) * im.GetWindowDpiScale()

  imguiUtils.changeUIScale(M.uiscale)

  style.push()
  local success, error = pcall(extensions.hook, "onNGMPUI", dtReal, dtSim, dtRaw, mainSizePos)
  if not success then
    log("E", "", error)
  end
  style.pop()

  imguiUtils.changeUIScale(1)

  --local time = timer:stop()
  --dump("Render took: "..time.." ms / "..(time*0.001).." s")
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
  local size = split(core_settings_graphic.selected_resolution, " ")
  mainSizePos[1] = im.ImVec2(tonumber(size[1]), tonumber(size[2]))
  mainSizePos[2] = im.GetMainViewport().Pos
  M.uiscale = mainSizePos[1].y/1080
end

M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate
M.getMainSizePos = getMainSizePos

-- DYNAMIC UI
M.getGlobalVec = getGlobalVec
M.getGlobalVecX = getGlobalVecX
M.getGlobalVecY = getGlobalVecY
M.getPercentVec = getPercentVec
M.getPercentVecX = getPercentVecX
M.getPercentVecY = getPercentVecY

-- UI WIDGETS
M.primaryButton = primaryButton
M.button = button

-- WIDGET HELPERS
M.calculateButtonSize = calculateButtonSize

-- IMVEC2 MATH
M.addVec2 = addVec2
M.subVec2 = subVec2
M.avgVec2 = avgVec2
M.dotVec2 = dotVec2
M.mulVec2Num = mulVec2Num
M.lengthSqrVec2 = lengthSqrVec2

return M