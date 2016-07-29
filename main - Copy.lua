bgSheet = nil
spriteSheet = nil
tileM = 2
tileS = 21

player = {
  x = 0,
  y = 0,
  speed = 150,
  quad = nil
}

map = {}

function getTile(x, y)
  return love.graphics.newQuad(
    tileM * (x+1) + tileS * x,
    tileM * (y+1) + tileS * y,
    tileS,
    tileS,
    spriteSheet:getWidth(),
    spriteSheet:getHeight())
end

function love.load()
  love.graphics.setDefaultFilter("nearest")
  
  love.graphics.setBackgroundColor(122, 195, 255)
  
  bgSheet = love.graphics.newImage("assets/backgrounds.png")
  spriteSheet = love.graphics.newImage("assets/spriteSheet.png")
  
  player.quad = getTile(19, 0)
  
  map = {
    { x = 1, y = 5, quad = getTile(2, 0) },
    { x = 2, y = 5, quad = getTile(3, 0) },
    { x = 3, y = 5, quad = getTile(3, 0) },
    { x = 4, y = 5, quad = getTile(4, 0) }
  }
end

function love.update(dt)  
  -- Exit game
  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end
  
  -- Movement
  if love.keyboard.isDown("left") then
    player.x = player.x - player.speed * dt
  end
  
  if love.keyboard.isDown("right") then
    player.x = player.x + player.speed * dt
  end
  
  -- Physics
  -- Gravity
  local gravity = 1
  player.y = player.y + gravity;
  -- Collisions
  for i = 1, table.getn(map) do
    local m = map[i]
    if (player.x + tileS >= m.x*tileS and
      player.x <= m.x*tileS + tileS and
      player.y + tileS >= m.y*tileS and
      player.y <= m.y*tileS + tileS) then
      print("Collision!")
    end
  end
end

function love.draw()
  local scale = 2;
  
  for i = 1, table.getn(map) do
    local m = map[i]
    love.graphics.draw(spriteSheet, m.quad, m.x*scale*tileS, m.y*scale*tileS, 0, scale, scale)
  end
  
  love.graphics.draw(spriteSheet, player.quad, player.x, player.y, 0, scale, scale)
end