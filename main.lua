--[[----------------------------------------------------------------------------
-- PROJECT WESTERN
-- INNY IS WORKING ON THIS
-- STEAL MY CODE AND DIE IN A FIRE
-- ... because the code is bad, your computer will set on fire while trying
-- to run it. Seriously, I care about your safety, please be careful.
--]]----------------------------------------------------------------------------

floor = math.floor
function NULLFUNC() end
function sign(x) return (((x==0) and 0) or ((x>0) and 1)) or -1 end
function bound(a, b, c) return (((b<a) and a) or (b>c) and c) or b end

--------------------------------------------------------------------------------

for _, M in ipairs {
  "object", "util", "ascii", "graphics", "input", "statemachine", "textwindow",
  "tilelayer", "tile", "sprite", "explorer", "menuscreen", "battle", "items"
}
do require(M) end

--------------------------------------------------------------------------------

E = Util.symbol()

--------------------------------------------------------------------------------

Snitch = ScrollingWindow:clone {
  dt = 1, visible = false
}

function Snitch:init()
  Snitch:superinit(self, 0, 0, 40, 1, 2993)
  return self:writeln("-")
end

function Snitch:toggle()
  Snitch.visible = not Snitch.visible
  Snitch.dt = 0.99
end

function Snitch:draw(dt)
  if not self.visible then return end
  dt = dt + Snitch.dt
  if dt >= 1 then
    dt = dt - 1
    local fps = love.timer.getFPS()
    local garbage = collectgarbage("count")
    self:writeln("FPS:", fps, "Mem:", math.floor(garbage).."k")
  end
  Snitch.dt = dt
  Snitch:super().draw(self, dt)
end

--------------------------------------------------------------------------------

PlayerStats = Object:clone {
  statNames = {
    "name",
    "hitPoints",
    "maxHP",
    "magicPoints",
    "vigor",
    "acuity",
    "speed",
    "techLevel",
    "techPoints",
    "experience"
  }
}

function PlayerStats:init( datum )
  for _, k in ipairs(self.statNames) do
    self[k] = datum[k] or 0
  end
  self.knowledge = {}
end

function PlayerStats:recoverHealthStep( fraction )
  local hp, max = self.hitPoints, self:maxHP()
  local charge = math.max(0.5, math.min(32, hp/2)) * fraction
  local newhp = math.min( max, hp + charge )
  self.hitPoints = newhp
  -- print('Hp:', hp, max, charge, newhp)
end

function PlayerStats:recoverMagicStep( fraction )
  local mp, max = self.magicPoints, self.intelligence*1.15
  local charge = math.max((max-mp)/10, 0.01) * fraction
  local newmp = math.min( 99, mp + charge )
  self.magicPoints = newmp
  -- print('Mp:', mp, max, charge, newmp)
end

--------------------------------------------------------------------------------

Game = {
  deltaTime = 0,
  focused = true,
  inventory = Inventory(),
  HugoDatum = {
    name = "Hugo",
    hitPoints = 0,
    maxHP = 30,
    magicPoints = 0,
    vigor = 10,
    acuity = 10,
    speed = 10,
    techLevel = 1,
    techPoints = 1,
    experience = 0
  }
}

function Game.init()
  Graphics:init()
  Input:init()
  Game:reset()
end

function Game.update(dt)
  if Game.focused then
    Game.deltaTime = dt
    Graphics.deltaTime = dt

    if Input.tap.f2 then
      Graphics:saveScreenshot()
    elseif Input.tap.f3 then
      Snitch:toggle()
    elseif Input.tap.f5 then
      Graphics:setNextScale()
    elseif Input.tap.f9 then
      error("Debug crash!")
    elseif Input.tap.f10 then
      Game:quit()
    end

    StateMachine:send( E.update, dt )
  else
    Game.deltaTime = 0
    Graphics.deltaTime = 0
  end

  Input:update(dt)
end

function Game.draw()
  Graphics:start()
  StateMachine:send( E.draw, Graphics.deltaTime )
  Graphics:stop()
end

function Game.keypressed(k, u)
  Input:keypressed(k, u)
end

function Game.keyreleased(k)
  Input:keyreleased(k)
end

function Game.focus(f)
  Game.focused = f
end

function Game:reset()
  Game.players = {
    PlayerStats( Game.HugoDatum ),
    PlayerStats( Game.HugoDatum ),
    PlayerStats( Game.HugoDatum ),
    PlayerStats( Game.HugoDatum )
  }

  StateMachine:clear()
  StateMachine:push( ExplorerState() )

  collectgarbage()
end

function Game:quit()
  love.event.quit()
end

--------------------------------------------------------------------------------

love.load = Game.init
love.update = Game.update
love.draw = Game.draw
love.keypressed = Game.keypressed
love.keyreleased = Game.keyreleased
love.focus = Game.focus

