
Sprite = Object:clone {
  x = 0,
  y = 0,
  tile = 0,
  priority = 0,
}

function Sprite:init(x, y, t, logicComponent)
  self.x = x or self.x
  self.y = y or self.y
  self.tile = t or self.tile
  return self
end

function Sprite:setParent( p )
  self.parent = p
  return self
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

