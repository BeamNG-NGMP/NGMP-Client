
local M = {}

local socket = require("socket")

local udp
local receiveBuffer = ""

-- close connection
M.disconnect = function(connection)
  udp:close()
  if connection then
    connection.connected = false
  end
end

-- start connection
-- will disconnect if already connected
M.connect = function(connection)
  if connection.connected then
    M.disconnect(connection)
  end

  udp:settimeout(connection.timeout)

  do
    local result, error = udp:setsockname(connection.ip, connection.clientPort)
    if error then
      connection.errType = "Client socket init failed!"
      connection.err = error
      log("E", "ngmp.netWrapper.udp.connect", connection.errType)
      log("E", "ngmp.netWrapper.udp.connect", error)
      return false
    end
  end

  do
    local result, error = udp:setpeername(connection.ip, connection.port)
    if result then
      connection.connected = true
      return result
    elseif error then
      connection.errType = "Launcher peer init failed!"
      connection.err = error
      log("E", "ngmp.netWrapper.udp.connect", connection.errType)
      log("E", "ngmp.netWrapper.udp.connect", error)
      return false
    else
      return nil
    end
  end
end

-- receive a specific amount of bytes
M.receive = function(bytes)
  receiveBuffer = receiveBuffer..udp:receive()
  local data = receiveBuffer:sub(1, bytes)
  receiveBuffer = receiveBuffer:sub(bytes)

  return data
end

-- pieces together the header
M.send = function(packetType, dataStr)
  local len = ffi.string(ffi.new("uint32_t[1]", {#dataStr}), 4)
  local success, err = udp:send(packetType..len..dataStr)
  if not success then
    return err
  end
end

M.init = function(connection)
  udp = socket.udp()

  connection.connected = false
  connection.timeout = 0
  connection.udp = udp
end

return M
