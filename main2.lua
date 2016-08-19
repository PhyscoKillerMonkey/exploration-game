function table.print(t, depth)
  depth = depth or 1
  if depth == 1 then print("{") end
  if depth < 6 then
    for k, v in pairs(t) do
      if type(k) == "string" then
        k = '"' .. k .. '"'
      end
      if type(v) == "string" then
        v = '"' .. v .. '"'
        print(getSpaces(depth) .. k .. " = " .. v)
      elseif type(v) == "table" then
        print(getSpaces(depth) .. k .. " = {")
        table.print(v, depth + 1)
        print(getSpaces(depth) .. "}")
      else
        print(getSpaces(depth) .. k .. " = " .. v)
      end
    end
  else
    print(getSpaces(depth) .. " overflow")
  end
  if depth == 1 then print ("}") end
end

function getSpaces(depth)
  local output = ""
  for i = 0, depth-1 do
    output = output .. "\t"
  end
  return output
end

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

local Person = {}
createClass(Person)
function Person:new()
  self.name = "noName"
end
function Person:getName()
  return self.name
end
function Person:setName(name)
  self.name = name
end
function Person:toString()
  return "Person object, name=" .. self.name
end

local Student = {}
createClass(Student, Person)
function Student:new()
  Person:new() -- Call the inherited constructor
  self.year = 0
  self.subject = "none"
  self.classes = { something = 1, "History", "Maths" }
end
function Student:getYear()
  return self.year
end
function Student:setYear(year)
  self.year = year
end
function Student:toString()
  return "Student object, name=" .. self.name .. ", year=" .. self.year .. ", subject=" .. self.subject
end

local Sprite = {}
createClass(Sprite)
function Sprite:new(sheet, x, y)
  self.sheet = sheet
  self.quad = getQuad(x, y, sheet)
end
function Sprite:draw(x, y)
  love.graphics.draw(self.sheet, self.quad, x, y, 0, tileScale, tileScale)
end

local AnimatedSprite = {}
createClass(AnimatedSprite, Sprite)
function AnimatedSprite:new(sheet, x, y)
  Sprite:new(sheet, x, y)
  self.frameTimer = 0
  self.frameDuration = 0.5 -- In seconds
  self.currentAnimation = ""
  self.animationNames = {}
  self.animations = {}
end
function AnimatedSprite:addAnimation(name, frames)
  table.insert(self.animationNames, name)
  self.animations[name] = {}
  for i, v in ipairs(frames) do
    table.insert(self.animations[name], getQuad(v[1], v[2], self.sheet))
  end
end
function AnimatedSprite:updateFrame(dt)
  if self.currentAnimation ~= "" then
    self.frameTimer = self.frameTimer + dt
    local a = self.animations[self.currentAnimation]
    if self.frameTimer > self.frameDuration * #a then
      self.frameTimer = 0.0001 -- Cant be 0 cause division by 0
    end
    local frame = math.ceil(self.frameTimer / self.frameDuration)
    self.quad = a[frame]
  else
    print("No animation assigned")
  end
end

function getQuad(x, y, image)
  return love.graphics.newQuad(
    x * tileSize,
    y * tileSize,
    tileSize,
    tileSize,
    image:getWidth(),
    image:getHeight())
end

function love.load()
  -- Keeps everything nice and pixely
  love.graphics.setDefaultFilter("nearest")

  playerSheet = love.graphics.newImage("assets/player.png")
  tileSize = 16
  tileScale = 4

  player = AnimatedSprite(playerSheet, 0, 0)
  player:addAnimation("idle", {{0, 0}, {1, 0}})
  player.currentAnimation = "idle"
end

function love.update(dt)
  -- Exit on escape
  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end

  player:updateFrame(dt)
end

function love.draw()
  player:draw(100, 100)
end
