
Sprite = Object:clone {
  x = 0,
  y = 0,
  tile = 0,
  priority = 0,
}

function Sprite:init(x, y, t)
  self.x = x or self.x
  self.y = y or self.y
  self.tile = t or self.tile
  return self
end

function Sprite:setParent( p )
  self.parent = p
  return self
end

function Sprite:draw( x, y, dt )
  Graphics:drawTile( x, y, self.tile )
end

function Sprite:move( dx, dy )
  local x, y = floor(self.x + dx), floor(self.y + dy)
  local other = self.parent:getSpriteAt( x, y )
  if other then return self end
  local tile = self.parent:getTileAt( x, y )
  if tile:isSolid() then return self end

  self.parent:moveSprite( self, dx, dy )

  return self
end

function Sprite.sortingFunction( a, b )
  if a.priority == b.priority then
    if a.y == b.y then
      return ( a.x < b.x )
    else
      return ( a.y < b.y )
    end
  else
    return a.priority > b.priority
  end
end

function Sprite:runLogic()
  --
end

------------------------------------------------------------

SpriteWorld = Object:clone {}

function SpriteWorld:init()
  self.sprites = {}
  self.spatialHash = {}
  self.logicQueue = {}
  return self
end

function SpriteWorld:setTileLayer( tl )
  self.tileLayer = tl
  return self
end

function SpriteWorld:getTileAt( x, y )
  return self.tileLayer:getTile(x, y)
end

function SpriteWorld:runAllLogic(...)
  local Q = self.logicQueue
  for _, spr in ipairs(self.sprites) do table.insert(Q, spr) end
  table.sort(Q, Sprite.sortingFunction)
  local N = #Q
  for i = 1, N do
    Q[i]:runLogic(...)
  end
  for i = 1, N do Q[i] = nil end
  return self
end

function SpriteWorld:getSpriteAt( x, y )
  return self.spatialHash[ y * 1000 + x ]
end

function SpriteWorld:moveSprite( spr, dx, dy )
  self.spatialHash[ spr.y * 1000 + spr.x ] = nil
  spr.x = floor(spr.x + dx)
  spr.y = floor(spr.y + dy)
  self.spatialHash[ spr.y * 1000 + spr.x ] = spr
  return self
end

function SpriteWorld:addSprite( spr )
  for _, v in ipairs(self.sprites) do
    if v == spr then return self end
  end
  table.insert( self.sprites, spr )
  self.spatialHash[ spr.y * 1000 + spr.x ] = spr
  spr:setParent( self )
  return self
end

function SpriteWorld:removeSprite( spr )
  self.spatialHash[ spr.y * 1000 + spr.x ] = nil
  for i, v in ipairs(self.sprites) do
    if v == spr then
      table.remove( self.sprites, i )
      break
    end
  end
  return self
end

