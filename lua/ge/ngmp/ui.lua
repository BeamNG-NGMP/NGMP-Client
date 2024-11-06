
-- extension that dispatches ui calls and includes helper funcs
local M = {}

M.dependencies = {"ngmp_main", "ngmp_ui_translate", "ui_imgui"}
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
M.whiteCol = im.ImVec4(1,1,1,1)
M.whiteCol32 = im.GetColorU322(M.whiteCol)
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

-- custom ui widgets
local buttonStates = {}
local function playbuttonSound(prev, curr)
  if prev == curr then return end
  if prev == 0 and curr == 1 then
    ui_audio.playEventSound("bng_click_hover_generic", "focus")
  elseif prev == 1 and curr == 2 then
    ui_audio.playEventSound("bng_click_hover_generic", "click")
  end
end

function M.primaryButton(string_label, ImVec2_size)
  if ImVec2_size == nil then ImVec2_size = im.ImVec2(0,0) end
  if string_label == nil then log("E", "", "Parameter 'string_label' of function 'Button' cannot be nil, as the c type is 'const char *'") ; return end
  string_label = string_label.txt or string_label
  C.imgui_PushStyleVar2(im.StyleVar_FramePadding, im.ImVec2(6,2))
  C.imgui_PushStyleColor1(im.Col_Button, M.bngCol32)
  local retVal = C.imgui_Button(string_label, ImVec2_size)
  C.imgui_PopStyleColor(1)
  C.imgui_PopStyleVar(1)

  local buttonState = 0
  if C.imgui_IsItemHovered(0) then
    C.imgui_SetMouseCursor(im.MouseCursor_Hand)
    buttonState = 1
  end
  if retVal then buttonState = 2 end

  playbuttonSound(buttonStates[string_label], buttonState)
  buttonStates[string_label] = buttonState
  return retVal
end

function M.button(string_label, ImVec2_size)
  if ImVec2_size == nil then ImVec2_size = im.ImVec2(0,0) end
  if string_label == nil then log("E", "", "Parameter 'string_label' of function 'Button' cannot be nil, as the c type is 'const char *'") ; return end
  string_label = string_label.txt or string_label
  C.imgui_PushStyleVar2(im.StyleVar_FramePadding, im.ImVec2(6,2))
  local retVal = C.imgui_Button(string_label, ImVec2_size)
  C.imgui_PopStyleVar(1)

  local buttonState = 0
  if C.imgui_IsItemHovered(0) then
    C.imgui_SetMouseCursor(im.MouseCursor_Hand)
    buttonState = 1
  end
  if retVal then buttonState = 2 end

  playbuttonSound(buttonStates[string_label], buttonState)
  buttonStates[string_label] = buttonState
  return retVal
end

function M.checkbox(string_label, bool_v)
  if string_label == nil then log("E", "", "Parameter 'string_label' of function 'Checkbox' cannot be nil, as the c type is 'const char *'") ; return end
  if bool_v == nil then log("E", "", "Parameter 'bool_v' of function 'Checkbox' cannot be nil, as the c type is 'bool *'") ; return end
  string_label = string_label.txt or string_label

  local retVal = C.imgui_Checkbox(string_label, bool_v)
  if retVal then
    ui_audio.playEventSound("bng_checkbox_generic", "click")
  end
  return retVal
end

function M.Selectable1(string_label, bool_selected, ImGuiSelectableFlags_flags, ImVec2_size)
  if bool_selected == nil then bool_selected = false end
  if ImGuiSelectableFlags_flags == nil then ImGuiSelectableFlags_flags = 0 end
  if ImVec2_size == nil then ImVec2_size = im.ImVec2(0,0) end
  if string_label == nil then log("E", "", "Parameter 'string_label' of function 'Selectable1' cannot be nil, as the c type is 'const char *'") ; return end
  string_label = string_label.txt or string_label

  local retVal = C.imgui_Selectable1(string_label, bool_selected, ImGuiSelectableFlags_flags, ImVec2_size)
  if retVal then
    ui_audio.playEventSound("bng_click_generic_small", "click")
  end

  return retVal
end

function M.TextU(string_text, string_text_end)
  -- string_text_end is optional and can be nil
  if string_text == nil then log("E", "", "Parameter 'string_text' of function 'TextUnformatted' cannot be nil, as the c type is 'const char *'") ; return end
  C.imgui_TextUnformatted(string_text.txt or string_text, string_text_end and (string_text_end.txt or string_text_end))
end

function M.TextCentered(string_text, centerX)
  if string_text == nil then log("E", "", "Parameter 'string_text' of function 'TextUnformatted' cannot be nil, as the c type is 'const char *'") ; return end
  string_text = string_text.txt or string_text
  centerX = centerX or im.GetContentRegionAvailWidth()/2
  local fontWrapWidth = centerX*2

  local textWidth = 0
  repeat
    textWidth = im.CalcTextSize(string_text).x
    while textWidth > fontWrapWidth do
      --TODO
      break
    end

    im.SetCursorPosX(centerX-textWidth/2)
    -- string_text_end is optional and can be nil
    im.PushTextWrapPos(im.GetContentRegionAvailWidth())
    C.imgui_TextUnformatted(string_text.txt or string_text, string_text_end)
    im.PopTextWrapPos()
    textWidth = 0
  until textWidth == 0
end

local function ImRotate(v, cosA, sinA)
  v:set(v.x * cosA - v.y * sinA, v.x * sinA + v.y * cosA, 0)
  return v
end
M.ImRotate = ImRotate

local uv1D, uv2D, uv3D, uv4D = im.ImVec2(0, 0), im.ImVec2(1, 0), im.ImVec2(1, 1), im.ImVec2(0, 1)
M.uv1D, M.uv2D, M.uv3D, M.uv4D = uv1D, uv2D, uv3D, uv4D
function M.ImageRotated(drawlist, texId, size, angle, uv1, uv2, uv3, uv4, color)
  local center = vec3(im.GetCursorScreenPos().x+size.x/2, im.GetCursorScreenPos().y+size.y/2)
  im.Dummy(im.ImVec2(size.x, size.y))

  local cosA = math.cos(angle)
  local sinA = math.sin(angle)

  local pos = {
    center + ImRotate(vec3(-size.x * 0.5, -size.y * 0.5, 0), cosA, sinA),
    center + ImRotate(vec3( size.x * 0.5, -size.y * 0.5, 0), cosA, sinA),
    center + ImRotate(vec3( size.x * 0.5,  size.y * 0.5, 0), cosA, sinA),
    center + ImRotate(vec3(-size.x * 0.5,  size.y * 0.5, 0), cosA, sinA)
  }

  im.ImDrawList_AddImageQuad(drawlist, texId,
    im.ImVec2(pos[1].x, pos[1].y), im.ImVec2(pos[2].x, pos[2].y), im.ImVec2(pos[3].x, pos[3].y), im.ImVec2(pos[4].x, pos[4].y),
    uv1 or uv1D, uv2 or uv2D, uv3 or uv3D, uv4 or uv4D, color or M.whiteCol32)
end

local function calculateButtonSize(text)
  local textSize = im.CalcTextSize(text.txt or text or "")
  return im.ImVec2(textSize.x+6, textSize.y+2)
end
--

local function onUpdate(_, dtReal, dtSim, dtRaw)
  --timer:reset()
  local size = split(core_settings_graphic.selected_resolution, " ")
  mainSizePos[1] = im.ImVec2(tonumber(size[1]), tonumber(size[2]))
  mainSizePos[2] = im.GetMainViewport().Pos

  local prevUIScale = im.uiscale[0]
  M.uiscale = math.max(mainSizePos[1].x/1920, mainSizePos[1].y/1080) * im.GetWindowDpiScale()

  style.push()

  imguiUtils.changeUIScale(M.uiscale)
  im.PushFont3("segoeui_regular") -- update font size

  do
    local success, error = pcall(extensions.hook, "onNGMPUI", dtReal, dtSim, dtRaw, mainSizePos)
    if not success then
      log("E", "ngmp.ui.onNGMPUI.hook", error)
    end
  end

  imguiUtils.changeUIScale(prevUIScale)
  im.PopFont() -- reset font size

  style.pop()

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

-- need this for dynamic ui
M.getGlobalVec = getGlobalVec
M.getGlobalVecX = getGlobalVecX
M.getGlobalVecY = getGlobalVecY
M.getPercentVec = getPercentVec
M.getPercentVecX = getPercentVecX
M.getPercentVecY = getPercentVecY

-- helper stuff
M.calculateButtonSize = calculateButtonSize

-- mathematics
M.addVec2 = addVec2
M.subVec2 = subVec2
M.avgVec2 = avgVec2
M.dotVec2 = dotVec2
M.mulVec2Num = mulVec2Num
M.lengthSqrVec2 = lengthSqrVec2

return M
