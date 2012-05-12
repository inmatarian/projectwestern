
Item = Object:clone {
  lookup = {},
  name = "",
  desc = "",
  quantity = 0
}

function Item:init( id, name, desc )
  self.id = id
  self.name = name
  self.desc = desc
  self.lookup[id] = self
  if name then self.lookup[name] = self end
end

local NULLITEM = Item( 0 )

function Item:getItem( identifier )
  return self.lookup[ identifier ] or NULLITEM
end

Item( 1, "Aloe",      "Recover some Hit Points." )
Item( 2, "Cohosh",    "Recover most Hit Points." )
Item( 3, "Valerian",  "Raises Morale." )
Item( 4, "Rosemary",  "Remove Shock." )
Item( 5, "Thistle",   "Remove Poison." )
Item( 6, "Echinacea", "Heals all conditions." )
Item( 7, "Hartshorn", "Wake the Fallen." )
Item( 8, "Manchineel", "Inflict Poison")

--------------------------------------------------------------------------------

Inventory = Object:clone {
  MAX = 32
}

function Inventory:init()
  self.stash = {}
  for i = 1, self.MAX do
    self.stash[i] = Item:getItem(i):clone()
  end
end

function Inventory:getItem( index )
  return self.stash[index] or NULLITEM
end

function Inventory:swapItems( i, j )
  self.stash[i], self.stash[j] = self.stash[j], self.stash[i]
end

function Inventory:itemName( index )
  return self:getItem(index).name
end

function Inventory:quantity( index )
  return self:getItem(index).quantity
end

function Inventory:itemDesc( index )
  return self:getItem(index).desc
end

