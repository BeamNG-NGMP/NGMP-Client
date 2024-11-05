
local M = {}

local im = ui_imgui

-- Thanks to Paul Kulchenko on Stack Overflow
-- https://stackoverflow.com/a/16643628
local function splitIP(ipStr)
  if type(ipStr) ~= "string" then return false end

  do
    -- check for format 1.11.111.111 for ipv4
    local ip, port = ipStr:match("^(.+)%:(%d+)$")
    if port and tonumber(port) > 65535 then
      return false
    end

    if ip then
      local chunks = {ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")}
      if #chunks == 4 and (port and tonumber(port) < 65535 or true) then
        for _,v in pairs(chunks) do
          if tonumber(v) > 255 then
            return false
          end
        end
        return table.concat(chunks, "."), port
      end
    end
  end

  -- [1fff:0:a88:85a3::ac1f]:8001
  do
    -- check for ipv6 format, should be 8 'chunks' of numbers/letters
    -- without leading/trailing chars
    -- or fewer than 8 chunks, but with only one `::` group
    local chunks = {ipStr:match("^"..(("([a-fA-F0-9]*):"):rep(8):gsub(":$","$")))}
    if #chunks == 8 or #chunks < 8 and ipStr:match('::') and not ipStr:gsub("::","",1):match('::') then
      for _,v in pairs(chunks) do
        if #v > 0 and tonumber(v, 16) > 65535 then return false end
      end
      local port = ipStr:match("%[.+%]:(%d+)$")
      if port then
        return ipStr:match("%[(.+)%]:%d+$"), port
      else
        return ipStr
      end
    end
  end

  do
    if ipStr:match("[%(%[%s]") then
      return
    end
  end

  do
    if ipStr:match("%.") then
      return ipStr
    end
  end

  return ipStr
end

local function buildIP(ip_address, port)
  local finalIp = ip_address
  if finalIp and port and port ~= "" then
    finalIp = finalIp..":"..port
  end
  return finalIp
end

local function ffiConvertNumber(str, bytes)
  local _res = ffi.new(string.format("uint%d_t[1]", bytes*8))
  ffi.copy(_res, str, bytes)
  return _res[0]
end

M.splitIP = splitIP
M.buildIP = buildIP
M.ffiConvertNumber = ffiConvertNumber

return M
