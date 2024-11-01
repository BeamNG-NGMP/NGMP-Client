
local M = {}

local socket = require("socket")

local tcp

-- close connection
M.disconnect = function(connection)
  tcp:close()
  connection.connected = false
end

-- start connection
-- will disconnect if already connected
M.connect = function(connection)
  if connection.connected then
    M.disconnect(connection)
  end

  tcp:settimeout(connection.timeout)

  do
    local result, error = tcp:connect(connection.ip, connection.port)
    if result then
      connection.connected = true
      return result
    elseif error then
      connection.errType = "Launcher connection!"
      connection.err = error
      log("E", "ngmp.netWrapper.tcp.connect", connection.errType)
      log("E", "ngmp.netWrapper.tcp.connect", error)
      return false
    else
      return nil
    end
  end
end

-- receive a specific amount of bytes
-- the UDP wrapper works around the discard functionality luasocket uses
-- tcp does not do this by default
M.receive = function(bytes)
  return tcp:receive(bytes)
end

-- pieces together the header
M.send = function(packetType, dataStr)
  local len = ffi.string(ffi.new("uint32_t[1]", {#dataStr}), 4)
  local success, err = tcp:send(packetType..len..dataStr)
  if not success then
    return err
  end
end

M.init = function(connection)
  tcp = socket.tcp()

  connection.connected = false
  connection.timeout = 0
  connection.tcp = tcp
end

return M
