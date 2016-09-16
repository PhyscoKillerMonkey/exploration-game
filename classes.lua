function createClass(class, parent)
  class.__index = class
  parent = parent or child
  setmetatable(class, {
    __index = parent,
    __call = function (cls, ...)
      local self = setmetatable({}, cls)
      self:new(...)
      return self
    end
  })
end

Sprite = {}
createClass(Sprite)
function Sprite:new(x, y, sheet)
  self.sheet = sheet
  self.quad = getQuad(x, y, sheet)
end
function Sprite:draw(x, y)
  love.graphics.draw(self.sheet, self.quad, x, y, 0, tileScale, tileScale)
end

local AnimatedSprite = {}
createClass(AnimatedSprite, Sprite)
function AnimatedSprite:new(x, y, sheet)
  Sprite:new(x, y, sheet)
  self.frameTimer = 0
  self.currentAnimation = ""
  self.animationNames = {}
  self.animationFrames = {}
  self.animationDurations = {}
end
function AnimatedSprite:addAnimation(name, frameDuration, frames)
  table.insert(self.animationNames, name)
  self.animationFrames[name] = {}
  self.animationDurations[name] = frameDuration
  for i, v in ipairs(frames) do
    table.insert(self.animationFrames[name], getQuad(v[1], v[2], self.sheet))
  end
end
function AnimatedSprite:updateFrame(dt)
  local name = self.currentAnimation
  if name ~= "" then
    self.frameTimer = self.frameTimer + dt
    local frames = self.animationFrames[name]
    local duration = self.animationDurations[name]
    if self.frameTimer > duration * #frames then
      self.frameTimer = 0.0001 -- Cant be 0 cause division by 0
    end
    local frame = math.ceil(self.frameTimer / duration)
    self.quad = frames[frame]
  else
    print("No animation assigned")
  end
end

Tile = {}
createClass(Tile)
function Tile:new(x, y, background)
  self.x = x
  self.y = y
  self.background = background
  self.object = nil
  self.items = {}
end

Object = {}
createClass(Object)
function Object:new(sprite, onBreak, blocking)
  self.sprite = sprite
  self.onBreak = onBreak
  self.blocking = blocking
end

Item = {}
createClass(Item)
function Item:new(sprite, name)
  self.sprite = sprite
  self.name = name
end

local classes = {
  createClass = createClass,
  Sprite = Sprite,
  AnimatedSprite = AnimatedSprite,
  Tile = Tile,
  Object = Object,
  Item = Item
}

return classes
