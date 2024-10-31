
local M = {
  name = "powertrain",
  abbreviation = "p",
  author = "DaddelZeit (NGMP Official)"
}

local abbreviations = {
  combustionEngine = "e",
  frictionClutch = "c",
  centrifugalClutch = "cc",
  manualGearbox = "m",
  rangeBox = "r",
  differential = "d",
}
local abbreviationsRev = require("ngmp/utils").switchKeysAndValues(abbreviations)

local powertrainOverrides = {
  combustionEngine = function(device)
    device.maxPhysicalAV = math.huge
    device.maxTorqueRating = 0
  end,
  frictionClutch = function(device)
    device.clutchThermalsEnabledCoef = 0
  end,
  centrifugalClutch = function(device)
    device.clutchThermalsEnabledCoef = 0
  end,
  manualGearbox = function(device)
    for k,_ in ipairs(device.gearRatios) do
      device.shiftRequiredClutchInput[k] = 0
    end
  end,
}

local powertrainSyncFuncsGet = {
  combustionEngine = function(device)
    if not device.thermals then return end
    return {
      device.thermals.cylinderWallTemperature,
      device.thermals.oilTemperature,
      device.thermals.engineBlockTemperature,
      device.thermals.exhaustTemperature,
      device.thermals.coolantTemperature,
      device.compressionBrakeCoefDesired > 0 and device.compressionBrakeCoefDesired or nil,
    }
  end,
  -- should be handled in electrics
  --manualGearbox = function(device)
  --  if device.NGMP_lastGear ~= device.gearIndex then
  --    device.NGMP_lastGear = device.gearIndex
  --    return device.gearIndex
  --  end
  --end
  rangeBox = function(device)
    if device.NGMP_lastMode ~= device.mode then
      device.NGMP_lastMode = device.mode
      return {
        device.mode,
      }
    end
  end,
  differential = function(device)
    if device.NGMP_lastMode ~= device.mode then
      device.NGMP_lastMode = device.mode
      return {
        device.mode,
      }
    end
  end
}

local function get()
  local data = {}
  for deviceType, func in pairs(powertrainSyncFuncsGet) do
    for key,device in ipairs(powertrain.getDevicesByType(deviceType)) do
      if key == 1 then key = "" else key = tostring(key) end
      data[abbreviations[deviceType]..key] = func(device)
    end
  end
  return next(data) and data or nil
end

local powertrainSyncFuncsSet = {
  combustionEngine = function(device, data)
    device.thermals.cylinderWallTemperature = data[1]
    device.thermals.oilTemperature = data[2]
    device.thermals.engineBlockTemperature = data[3]
    device.thermals.exhaustTemperature = data[4]
    device.thermals.coolantTemperature = data[5]

    if device.compressionBrakeCoefDesired ~= device.NGMP_lastCompressionBrake then
      device:setCompressionBrakeCoef(data[6] and data[6] or 0)
      device.NGMP_lastCompressionBrake = device.compressionBrakeCoefDesired
    end
  end,
  rangeBox = function(device, data)
    device:setMode(data[1])
  end,
  differential = function(device, data)
    device:setMode(data[1])
  end
}

local function set(data)
  for deviceTypeAbbr, val in pairs(data) do
    local deviceType = abbreviationsRev[deviceTypeAbbr]
    if deviceType and powertrainSyncFuncsSet[deviceType] then
      for _,device in ipairs(powertrain.getDevicesByType(deviceType)) do
        powertrainSyncFuncsSet[deviceType](device, val)
      end
    end
  end
end

local function addPowertrainSyncFunc(deviceType, abbreviation, setFunc, getFunc)
  abbreviations[deviceType] = abbreviation
  powertrainSyncFuncsSet[deviceType] = setFunc
  powertrainSyncFuncsGet[deviceType] = getFunc
end

local function applyPowertrainOverride(device, func)
  func(device)
end

local function onExtensionLoaded()
  for deviceType, func in pairs(powertrainOverrides) do
    for _,device in ipairs(powertrain.getDevicesByType(deviceType)) do
      applyPowertrainOverride(device, func)
    end
  end
end

M.set = set
M.get = get
M.addPowertrainSyncFunc = addPowertrainSyncFunc
M.applyPowertrainOverride = applyPowertrainOverride
M.onExtensionLoaded = onExtensionLoaded

return M
