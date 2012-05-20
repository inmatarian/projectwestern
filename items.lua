
Item = Object:clone {
  lookup = {},
  name = "",
  desc = "",
  quantity = 0,
  useDist = 1
}

function Item:init()
  self.lookup[self.id] = self
  if self.name then self.lookup[self.name] = self end
end

local NULLITEM = Item:initialize { id = 0 }

function Item:getItem( identifier )
  return self.lookup[ identifier ] or NULLITEM
end

--------------------------------------------------------------------------------

Item:initialize {
  id = 1,
  name = "Aloe",
  desc = "Recover some Hit Points."
}

Item:initialize {
  id = 2,
  name = "Cohosh",
  desc = "Recover most Hit Points."
}

Item:initialize {
  id = 3,
  name = "Valerian",
  desc = "Raises Morale."
}

Item:initialize {
  id = 4,
  name = "Rosemary",
  desc = "Remove Shock."
}

Item:initialize {
  id = 5,
  name = "Thistle",
  desc = "Remove Poison."
}

Item:initialize {
  id = 6,
  name = "Echinacea",
  desc = "Heals all conditions."
}

Item:initialize {
  id = 7,
  name = "Hartshorn",
  desc = "Wake the Fallen."
}

Item:initialize {
  id = 8,
  name = "Manchineel",
  desc = "Inflict Poison"
}

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

