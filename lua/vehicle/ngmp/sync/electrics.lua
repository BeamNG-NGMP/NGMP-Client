
local M = {
  name = "electrics",
  abbreviation = "e",
  author = "DaddelZeit (NGMP Official)"
}

-- this shit is actually in doubles but floats are close enough and half as big
local function doubleToBytes(num)
  if not num then return end
  return ffi.string(ffi.new("float[1]", num), 4)
end

local tmpFloat = ffi.new("float[1]")
local function bytesToFloat(str)
  ffi.copy(tmpFloat, str, 4)
  return tmpFloat[0]
end

local electricsIgnoreTbl = {
  -- this is entirely irrelevant
  accXSmooth = true,
  accYSmooth = true,
  accZSmooth = true,
  odometer = true,
  trip = true,
  nop = true,
  airspeed = true,
  airflowspeed = true,
  altitude = true,
  lowpressure = true,
  oil = true,
  rpmTacho = true,
  rpmspin = true,
  boost = true,
  boostMax = true,
  wheelspeed = true,
  avgWheelAV = true,

  -- lights stuff, also irrelevant
  parkingbrakelight = true,
  turnsignal = true,
  parking = true,
  reverse = true,
  lights = true, -- use lights_state!
  signal_R = true,
  signal_L = true,
  hazard = true,
  lowhighbeam = true,
  lowbeam = true,
  highbeam = true,
  fog = true,
  lowhighbeam_signal_R = true,
  lowhighbeam_signal_L = true,
  reverse_wigwag_R = true,
  reverse_wigwag_L = true,
  highbeam_wigwag_R = true,
  highbeam_wigwag_L = true,
  brakelight_signal_R = true,
  brakelight_signal_L = true,
  brakelights = true,

  -- gearbox shit (shiftlogic)
  smoothedAvgAVInput = true,
  waterTemp = true,
  oilTemp = true,
  checkEngine = true,
  engineThrottle = true,
  engineLoad = true,
  engineTorque = true,
  flywheelTorque = true,
  gearboxTorque = true,
  isEngineRunning = true,
  minGearIndex = true,
  maxGearIndex = true,

  lockupClutchRatio = true,

  -- vehicle controller
  gearIndex = true,
  gear_M = true,
  gear_A = true, -- backwards compat
  gearModeIndex = true,
  fuel = true,
  lowfuel = true,
  fuelCapacity = true,
  fuelVolume = true,

  rpm = true,
  idlerpm = true,
  maxrpm = true,
  oiltemp = true,
  watertemp = true,
  checkengine = true,
  ignition = true,
  running = true,
  smoothShiftLogicAV = true,
  isShifting = true,

  -- handled in a different module
  throttle = true,
  throttle_input = true,
  regenThrottle = true,
  throttleOverride = true,
  brake = true,
  brake_input = true,
  brakeOverride = true,
  clutch = true,
  clutch_input = true,
  clutchOverride = true,
  clutchRatio = true,
  radiatorFanSpin = true,
  gearboxMode = true,

  parkingbrake = true,
  parkingbrake_input = true,
  steering = true,
  steering_input = true,

  -- EV specifics
  regenFromBrake = true,
  regenFromOnePedal = true,
  maxRegenStrength = true,

  -- powertrain and csvMetrics
  airIntake = true,
  airIntakeMax = true,
  exhaustFlow = true,

  intershaft = true,
  driveshaft_F = true,
  driveshaft_R = true,
  driveshaft = true,

  axle_FL = true,
  axle_FR = true,

  splitter_state = true,

  -- (forced induction)
  turboSpin = true,
  turboRPM = true,
  turboBoost = true,
  turboRpmRatio = true,

  superchargerBoost = true,

  -- wheels
  virtualAirspeed = true,
  wheelThermals = true,

  -- input
  steeringUnassisted = true,
  steering_timestamp = true,

  -- shifter
  hPatternAxisX = true,
  hPatternAxisY = true,

  -- cruise control
  cruiseControlActive = true,

  -- systems
  abs = true,
  absActive = true,
  hasABS = true,

  esc = true,
  escActive = true,
  hasESC = true,

  tcs = true,
  tcsActive = true,
  hasTCS = true,

  yawControlRequestReduceOversteer = true,
  postCrashBrakeTriggered = true,
  isYCBrakeActive = true,
  isTCBrakeActive = true,
  isABSBrakeActive = true,
  dseWarningPulse = true,
  dseRollingOver = true,
  dseRollOverStopped = true,
  dseCrashStopped = true,

  -- 4wd
  modeRangeBox = true,
  mode4WD = true,
}

local abbreviations = {
  lights_state = 1,
  hazard_enabled = 2,
  signal_right_input = 3,
  signal_left_input = 4,
  lightbar = 5,
  horn = 6,
  transbrake = 7,
  gear = 8,
  freezeState = 9,
  engineRunning = 10,
  ignitionLevel = 11,
}

--[[what we actually care about:
- lights_state
- hazard_enabled
- signal_right_input
- signal_left_input
- lightbar
- horn

- transbrake
- shifters

- gear  controller.mainController.shiftToGearIndex()
- freezeState  controller.mainController.setFreeze()

- engineRunning  controller.mainController.setStarter(true)
- ignitionLevel  controller.mainController.setEngineIgnition(true)

- the axle lift shit
- compression brake
- jato
- pneumatics (PLEASE)
]]

local lastElectrics = {}

local getData = {
  n = {},
  s = {},
  b = {},
  t = {}
}

local function get()
  local ret = next(getData) and getData or nil
  getData = {}
  dump(ret)
  return ret
end

local function getKey(fullKey)
  return abbreviations[fullKey] or fullKey
end

local function updateGFX()
  getData = {
    n = {},
    s = {},
    b = {},
    t = {}
  }
  for k,v in pairs(electrics.values) do
    if electricsIgnoreTbl[k] or lastElectrics[k] == v then goto next end
    lastElectrics[k] = v
    k = getKey(k)
    if type(v) == "number" then
      if v%1 ~= 0 then
        getData.n[k] = doubleToBytes(v)
      else
        getData.n[k] = v
      end
    elseif type(v) == "string" then
      getData.s[k] = v
    elseif type(v) == "boolean" then
      getData.b[k] = v and 1 or 0
    elseif type(v) == "table" then
      getData.t[k] = v
    end

    ::next::
  end

  if not next(getData.n) then
    getData.n = nil
  end
  if not next(getData.s) then
    getData.s = nil
  end
  if not next(getData.b) then
    getData.b = nil
  end
  if not next(getData.t) then
    getData.t = nil
  end
end

local function set(data)
end

local function onExtensionLoaded()
  -- add airbrakes and stuff to the blocked list
  for k,v in ipairs(controller.getControllersByType("pneumatics/airbrakes")) do
    electricsIgnoreTbl[v.name.."_pressure_service"] = true
    electricsIgnoreTbl[v.name.."_pressure_parking"] = true
  end
end

M.updateGFX = updateGFX
M.set = set
M.get = get
M.onExtensionLoaded = onExtensionLoaded

M.doubleToBytes = doubleToBytes
M.bytesToFloat = bytesToFloat

return M