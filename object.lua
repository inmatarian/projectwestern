
local MT = {}

function MT.__call(parent, ...)
  return parent:new(...)
end

function MT.__index(obj, key)
  local val = rawget(obj, "__parent")[key]
  if type(val)=="nil" then
    local handler = obj.__unknown
    if type(handler)=="function" then
      val = handler(obj, key)
    end
  end
  return val
end

Object = {}
Object.__parent = MT
setmetatable( Object, MT )

function Object:init() return self end

function Object:new(...)
  local instance = setmetatable({}, self)
  return instance:init(...) or instance
end

function Object:clone(body)
  body = body or {}
  body.__index = body
  body.__parent = self
  return setmetatable(body, MT)
end

function Object:super()
  local mt = getmetatable(self)
  if mt == MT then
    return rawget(self, "__parent")
  else
    return mt
  end
end

function Object:superinit(obj, ...)
  return self:super().init(obj, ...)
end

function Object:isA(ancestor)
  repeat
    if self == ancestor then return true end
    self = self:super()
  until self == Object
  return self == ancestor
end

function Object:mixin(...)
  for i = 1, select('#', ...) do
    for k, v in pairs(select(i, ...)) do
      if not rawget(self, k) then rawset(self, k, v) end
    end
  end
end

function Object:__unknown() end

do
  local Test = Object:clone()
  Test.blah = 27
  function Test:lol() return self.blah end
  local Test2 = Test:clone()
  Test2.blah = 42
  local test = Test2()
  assert( not test.value )
  assert( test.blah == 42 )
  assert( test:lol() == 42 )
  Test2.blah = 2993
  assert( test:lol() == 2993 )
  assert( test:isA(Test2) and test:isA(Test) )
  assert( not Test:isA(Test2) )
end

