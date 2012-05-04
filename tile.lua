
Tile = Object:clone {
  lookup = {},
  opaque = false
}

function Tile:init( id, opaque, solid )
  self.lookup[id] = self
  self.opaque = opaque or 0
  self.solid = solid or false
end

function Tile:getTile( id )
  return self.lookup[id] or self.Void
end

function Tile:opaqueness( id )
  if id then
    return self.lookup[id].opaque
  else
    return self.opaque
  end
end

function Tile:isSolid( id )
  if id then
    return self.lookup[id].solid
  else
    return self.solid
  end
end

Tile.Void = Tile(1, 0, true)
Tile.Ocean = Tile(2, 0, true)
Tile.River = Tile(3, 0, true)
Tile.Beach = Tile(4, 0)
Tile.Marsh = Tile(5, 0)
Tile.Grass = Tile(6, 0)
Tile.Bush = Tile(7, 0)
Tile.Trees = Tile(8, 50)
Tile.Hills = Tile(9, 25)
Tile.Mountains = Tile(10, 100, true)


