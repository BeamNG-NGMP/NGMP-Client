

local M = {}
M.dependencies = {"ui_imgui", "ngmp_ui"}

local im = ui_imgui

local uiModules = {}
local tabs = {}
local currentTab = 0

local fadeSmoother = newTemporalSmoothing(4, 2, nil, 4)
local extensionYSmoother = newTemporalSigmoidSmoothing(20, 10)
local extensionXSmoother = newTemporalSigmoidSmoothing(20, 10)
local state = "closed"

local windowTargetWidthPercent = 15
local extensionY = 0
local extensionX = 0
local arrowMovementTimer = 0
local cursorVisibility = true
local cursorVisible = true
local cursorLocked = false


local function drawArrow(drawlist, centerPos, sizeX, sizeY)
  im.ImDrawList_PathClear(drawlist)
  im.ImDrawList_PathLineTo(drawlist, ngmp_ui.addVec2(centerPos, im.ImVec2(sizeX/2,-sizeY)))
  im.ImDrawList_PathLineTo(drawlist, im.ImVec2(centerPos.x-sizeX/2, centerPos.y))
  im.ImDrawList_PathLineTo(drawlist, ngmp_ui.addVec2(centerPos, im.ImVec2(sizeX/2, sizeY)))
  im.ImDrawList_PathStroke(drawlist, im.GetColorU322(im.ImVec4(0.5,0.5,0.5,extensionYSmoother.state)), false, ngmp_ui.uiscale*2)
end

local function renderTabHeader(drawlist, pos3, pos4, windowWidth)
  -- A good bit of this code was written while drunk.
  -- It might not be very comprehensive, but it works.
  if #tabs > 0 then
    local width = windowWidth/#tabs
    if im.BeginTable("Sidebar Tabs##NGMPUI", #tabs, im.TableFlags_SizingStretchSame, im.ImVec2(windowWidth, 0), float_inner_width) then
      for i=1, #tabs do
        im.TableNextColumn()
        local name = tabs[i].name
        local nameWidth = im.CalcTextSize(name).x
        im.SetCursorPosX(im.GetCursorPosX()+width/2-nameWidth/2)
        if currentTab == i then
          im.Text(name)
        else
          im.TextColored(im.ImVec4(1,1,1,0.5), name)
        end

        if im.IsItemHovered() then
          im.SetMouseCursor(im.MouseCursor_Hand)
          if im.IsMouseClicked(0) then
            currentTab = i
          end
        end
      end
      im.EndTable()
    end
    im.ImDrawList_AddLine(drawlist, im.ImVec2(pos3.x, pos3.y+im.GetCursorPosY()), im.ImVec2(pos4.x, pos3.y+im.GetCursorPosY()), im.GetColorU321(im.Col_Text, 0.75), ngmp_ui.uiscale*1)
    im.Dummy(im.ImVec2(1,ngmp_ui.uiscale*2))
  end
end

local function NGMPUI(dt)
  local windowPos1 = ngmp_ui.getPercentVec(99-extensionX, 5)
  local windowPos2 = ngmp_ui.getPercentVec(100, 95)
  local windowSize = ngmp_ui.subVec2(windowPos2, windowPos1)

  im.StyleColorsClassic()
  local style = im.GetStyle()
  im.PushStyleVar2(im.StyleVar_WindowPadding, im.ImVec2(0, 0))

  im.SetNextWindowPos(windowPos1)
  im.SetNextWindowSize(windowSize)
  im.Begin("Sidebar##NGMPUI", nil,
    im.WindowFlags_AlwaysAutoResize+
    im.WindowFlags_NoResize+
    im.WindowFlags_NoMove+
    im.WindowFlags_NoCollapse+
    im.WindowFlags_NoDocking+
    im.WindowFlags_NoBackground+
    im.WindowFlags_NoTitleBar+
    im.WindowFlags_NoScrollbar+
    im.WindowFlags_NoBringToFrontOnFocus)
  im.SetWindowFontScale(1)

  local drawlist = im.GetBackgroundDrawList1()
  local pos = ngmp_ui.getPercentVec(99-extensionX, 45-extensionY)
  local pos2 = ngmp_ui.getPercentVec(100-extensionX, 55+extensionY)
  pos2.x = math.ceil(pos2.x)

  local windowWidth = ngmp_ui.getPercentVecX(100)-ngmp_ui.getPercentVecX(99-windowTargetWidthPercent)
  local windowHeight = ngmp_ui.getPercentVecY(100)-ngmp_ui.getPercentVecY(10)

  -- Hide this during gameplay to avoid obstructing the viewport.
  -- Obviously it should still show up when the mouse is somewhere near it.
  local mouseNearArea = cursorVisible and im.GetMousePos().x > ngmp_ui.getPercentVecX(99-windowTargetWidthPercent)
  im.PushStyleVar1(im.StyleVar_Alpha, math.min(fadeSmoother:get((worldReadyState ~= 2 or state == "opening" or state == "open" or state == "closing" or (state == "closed" and mouseNearArea)) and 1 or 0, dt), 1))
  im.ImDrawList_AddRectFilled(drawlist, pos, pos2, im.GetColorU321(im.Col_WindowBg), 10, im.ImDrawFlags_RoundCornersTopLeft+im.ImDrawFlags_RoundCornersBottomLeft)

  if state ~= "closed" then
    local pos3 = ngmp_ui.getPercentVec(100-extensionX, 5)
    pos3.x = math.ceil(pos3.x)
    local pos4 = ngmp_ui.getPercentVec(100, 95)
    im.ImDrawList_AddRectFilled(drawlist, pos3, pos4, im.GetColorU321(im.Col_WindowBg), 15, im.ImDrawFlags_RoundCornersTopLeft+im.ImDrawFlags_RoundCornersBottomLeft)

    im.SetCursorPosY(im.GetCursorPosY()+style.WindowPadding.y+style.ItemSpacing.y)
    local indentX = pos2.x-pos.x+style.WindowPadding.x+style.ItemSpacing.x
    im.Indent(indentX)
    windowWidth = windowWidth - indentX

    renderTabHeader(drawlist, pos3, pos4, windowWidth)

    if tabs[currentTab] then
      tabs[currentTab].render(dt, windowWidth, windowHeight, indentX)
    end
  end

  local onClickArea = im.IsMouseHoveringRect(pos, pos2)
  extensionYSmoother:get((state == "opening" or state == "open" or onClickArea) and 1 or 0, dt)
  extensionY = 20*extensionYSmoother.state

  if onClickArea then
    im.SetMouseCursor(im.MouseCursor_Hand)
    if im.IsMouseClicked(0) then
      state = state == "closed" and "opening" or "closing"
    end
  end

  arrowMovementTimer = (arrowMovementTimer + dt*3)%(math.pi*2)
  if onClickArea or extensionXSmoother.state~=0 then
    local centerPos = ngmp_ui.getPercentVec(99.5-extensionX, 50)
    local animState = (extensionXSmoother.state-0.5)*-2

    drawArrow(drawlist, ngmp_ui.addVec2(centerPos, im.ImVec2(math.sin(arrowMovementTimer)*ngmp_ui.uiscale+ngmp_ui.uiscale*3, 0)), animState*ngmp_ui.getPercentVecX(0.25, false, true), ngmp_ui.getPercentVecY(0.6, false, true))
    drawArrow(drawlist, ngmp_ui.addVec2(centerPos, im.ImVec2(math.sin(arrowMovementTimer)*ngmp_ui.uiscale-ngmp_ui.uiscale*3, 0)), animState*ngmp_ui.getPercentVecX(0.25, false, true), ngmp_ui.getPercentVecY(0.6, false, true))
  end

  extensionXSmoother:get((state == "opening" or state == "open" or state == "fading") and 1 or 0, dt)
  extensionX = windowTargetWidthPercent*extensionXSmoother.state

  if state == "opening" and extensionXSmoother.state == 1 then
    state = "open"
  elseif state == "closing" and extensionXSmoother.state == 0 then
    state = "closed"
  end

  im.End()
  im.PopStyleVar()
  im.PopStyleVar()

  Engine.imgui.enableBeamNGStyle()
end

local function openTab(modulePath, openOnSpawn)
  if not FS:fileExists(modulePath) then
    error("NGMPUI: Sidebar attempted to load not existing extension module. If you are a mod developer, verify the path.")
    return
  end

  local moduleName = modulePath:match("^(.+)%.")
  local moduleKey = moduleName:match("^.+/(.+)")
  if not uiModules[moduleKey] then
    local module = rerequire(moduleName)
    module.init()
    uiModules[moduleKey] = module

    tabs[#tabs+1] = module
    if openOnSpawn then
      currentTab = #tabs
    end
    return true
  end
  return false
end

local function closeTab(modulePath)
  local index = arrayFindValueIndex(tabs, uiModules[modulePath:match("^.+/(.+)%.")])
  if index then
    table.remove(tabs, index)
    currentTab = math.min(currentTab, #tabs)
    return true
  end
  return false
end

local function onNGMPLogin()
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
  openTab("/lua/ge/ngmp/ui/sidebar/login.lua", true)
end

local function onCursorVisibilityChanged(val)
  cursorVisibility = val
  cursorVisible = cursorVisibility and not cursorLocked
end

local function onMouseLocked(val)
  cursorLocked = val
  cursorVisible = cursorVisibility and not cursorLocked
end

M.onMouseLocked = onMouseLocked
M.onCursorVisibilityChanged = onCursorVisibilityChanged

M.onExtensionLoaded = onExtensionLoaded
M.NGMPUI = NGMPUI
M.onNGMPLogin = onNGMPLogin

-- outside functions
M.openTab = openTab
M.closeTab = closeTab

return M