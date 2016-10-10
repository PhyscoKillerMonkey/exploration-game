local c = require "classes"

local player = {
  x = 8,
  y = 6,
  facing = 0,

  offX = 0,
  offY = 0,

  moving = "none",
  nextMove = "none",
  lastMove = "none",
  timer = 0,
  turnDuration = 0.1, -- Seconds before starting to walk

  sprite = c.AnimatedSprite(0, 0, playerSheet),
  breakMode = false,
  invOpen = false,
  inventory = {}
}

function player:update(dt)
  -- Update the turn timer
  self.timer = self.timer - dt

  for i, v in ipairs({"up", "right", "down", "left"}) do
    if love.keyboard.wasPressed(v) then
      self.lastMove = self.nextMove
      self.nextMove = v
      --print(self.lastMove .. " " .. self.nextMove)
    end
    if love.keyboard.wasReleased(v) then
      self.nextMove = self.lastMove
      self.lastMove = "none"
      --print(self.lastMove .. " " .. self.nextMove)
    end
  end

  if self.moving == "none" and self.nextMove ~= "none" then
    if self.nextMove == "up" then
      if self.facing ~= "up" then
        self.timer = self.turnDuration
        self.facing = "up"
      elseif self.timer <= 0 and not checkCollision(0, -1) then
        self.moving = "up"
        self.y = self.y - 1
        self.offY = 1
      end

    elseif self.nextMove == "right" then
      if self.facing ~= "right" then
        self.timer = self.turnDuration
        self.facing = "right"
      elseif self.timer <= 0 and not checkCollision(1, 0) then
        self.moving = "right"
        self.x = self.x + 1
        self.offX = -1
      end

    elseif self.nextMove == "down" then
      if self.facing ~= "down" then
        self.timer = self.turnDuration
        self.facing = "down"
      elseif self.timer <= 0 and not checkCollision(0, 1) then
        self.moving = "down"
        self.y = self.y + 1
        self.offY = -1
      end

    elseif self.nextMove == "left" then
      if self.facing ~= "left" then
        self.timer = self.turnDuration
        self.facing = "left"
      elseif self.timer <= 0 and not checkCollision(-1, 0) then
        self.moving = "left"
        self.x = self.x - 1
        self.offX = 1
      end
    end
  end

  local step = 0.05
  if self.moving == "up" then
    self.offY = self.offY - step
    self.sprite.currentAnimation = "walkU"
    if self.offY <= 0 then self.moving = "none" end

  elseif self.moving == "right" then
    self.offX = self.offX + step
    self.sprite.currentAnimation = "walkR"
    if self.offX >= 0 then self.moving = "none" end

  elseif self.moving == "down" then
    self.offY = self.offY + step
    self.sprite.currentAnimation = "walkD"
    if self.offY >= 0 then self.moving = "none" end

  elseif self.moving == "left" then
    self.offX = self.offX - step
    self.sprite.currentAnimation = "walkL"
    if self.offX <= 0 then self.moving = "none" end

  elseif self.moving == "none" then
    self.offX = 0
    self.offY = 0

    if self.facing == "up" then
      self.sprite.currentAnimation = "idleU"
    elseif self.facing == "right" then
      self.sprite.currentAnimation = "idleR"
    elseif self.facing == "down" then
      self.sprite.currentAnimation = "idleD"
    elseif self.facing == "left" then
      self.sprite.currentAnimation = "idleL"
    end
  end
end

player.sprite:addAnimation("idleD", 0.8, {{0, 0}, {1, 0}})
player.sprite:addAnimation("walkD", 0.16, {{0, 1}, {0, 0}, {1, 1}, {0, 0}})
player.sprite:addAnimation("idleR", 0.8, {{2, 0}, {3, 0}})
player.sprite:addAnimation("walkR", 0.16, {{2, 1}, {2, 0}, {3, 1}, {2, 0}})
player.sprite:addAnimation("idleU", 0.8, {{0, 2}, {1, 2}})
player.sprite:addAnimation("walkU", 0.16, {{0, 3}, {0, 2}, {1, 3}, {0, 2}})
player.sprite:addAnimation("idleL", 0.8, {{2, 2}, {3, 2}})
player.sprite:addAnimation("walkL", 0.16, {{2, 3}, {2, 2}, {3, 3}, {2, 2}})
player.sprite.currentAnimation = "idleU"

for i = 1, 5 do
  player.inventory[i] = { item = nil, count = 0 }
end

return player
