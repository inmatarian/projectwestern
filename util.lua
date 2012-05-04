
Util = {}

function Util.meta(tab,le)
  return setmetatable(le or {}, tab)
end

Util.symbol = Util.meta {
  __call = function(S, t) return setmetatable(t or {}, getmetatable(S)) end,
  __index = function(S, k) return rawset(S, k, k)[k] end,
  __nexindex = function(S, k, v) error("Bad usage of enum table.") end,
}

Util.const = Util.meta {
  __call = function(S, t) return setmetatable(t, getmetatable(S)) end,
  __newindex = function(S, k, v) error("Read-only table error! ", 2) end,
  __index = function(S, k) error("Read-only typo error! "..k, 2) end
}

function Util.set(...)
  local s = {}
  for i = 1, select('#',...) do
    s[select(i,...)] = true
  end
  return s
end

function Util.array( size, default )
  local a = {}
  if type(default) ~= "nil" then
    for i = 1, size do a[i] = default end
  end
  return a
end

function Util.lookup( tab )
  for i, v in ipairs(tab) do
    tab[v] = i
  end
  return tab
end

function Util.tostringr( val, indent )
  local str
  indent = indent or ""
  if type(val) == "table" then
    str = "{\n"
    local max = 25
    for key, value in pairs(val) do
      str = str .. indent .. "  [" .. tostring(key) .. "] = "
      str = str .. Util.tostringr(value, indent.."  ") .. "\n"
      if max <= 1 then
        str = str .. indent .. "  ...\n"
        break
      end
      max = max - 1
    end
    str = str .. indent .. "}"
  else
    str = tostring(val)
  end
  return str
end

function Util.printr( val )
  print( Util.tostringr(val) )
end

