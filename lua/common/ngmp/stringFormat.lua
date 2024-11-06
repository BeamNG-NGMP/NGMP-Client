return function(str, context)
  local function iterate(inputString)
    return inputString:gsub("%b{}", function(block)
      block:match("^{(.+)}$"):gsub("%b{}", function(subBlock)
        block = block:gsub(subBlock, iterate(subBlock))
      end)

      local varName, digits = block:match("{(.*):(%%.*)}")
      digits = type(context[varName]) == "number" and digits or nil
      varName = varName or block:match("{(.*)}")

      return context[varName] and (digits and string.format(digits, context[varName]) or tostring(context[varName])) or block
    end)
  end

  return iterate(str)
end
