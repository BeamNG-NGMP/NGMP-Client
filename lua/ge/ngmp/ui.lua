
local M = {}

M.dependencies = {"ui_imgui"}
M.loggedIn = false

local im = ui_imgui
local C = ffi.C

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
--

local function SetWindowFontScale(float_scale)
  C.imgui_SetWindowFontScale(M.uiscale*float_scale)
end

local function onUpdate(dtReal, dtSim, dtRaw)
  --timer:reset()
  local size = split(core_settings_graphic.selected_resolution, " ")
  mainSizePos[1] = im.ImVec2(tonumber(size[1]), tonumber(size[2]))
  mainSizePos[2] = im.GetMainViewport().Pos
  M.uiscale = mainSizePos[1].y/1080

  local origFontScale = ui_imgui.SetWindowFontScale
  ui_imgui.SetWindowFontScale = SetWindowFontScale

  extensions.hook("NGMPUI", dtReal, dtSim, dtRaw, mainSizePos)

  ui_imgui.SetWindowFontScale = origFontScale

  --local time = timer:stop()
  --dump("Render took: "..time.." ms / "..(time*0.001).." s")
end

local function onExtensionLoaded()
  local size = split(core_settings_graphic.selected_resolution, " ")
  mainSizePos[1] = im.ImVec2(tonumber(size[1]), tonumber(size[2]))
  mainSizePos[2] = im.GetMainViewport().Pos
  M.uiscale = mainSizePos[1].y/1080
end

M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate
M.getMainSizePos = getMainSizePos
M.getGlobalVec = getGlobalVec
M.getGlobalVecX = getGlobalVecX
M.getGlobalVecY = getGlobalVecY
M.getPercentVec = getPercentVec
M.getPercentVecX = getPercentVecX
M.getPercentVecY = getPercentVecY
-- IMVEC2 MATH
M.addVec2 = addVec2
M.subVec2 = subVec2
M.avgVec2 = avgVec2
M.dotVec2 = dotVec2
M.mulVec2Num = mulVec2Num
M.lengthSqrVec2 = lengthSqrVec2

return M