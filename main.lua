function love.load()
  -- Keeps everything nice and pixely
  love.graphics.setDefaultFilter("nearest")
  
  -- Set the font
  love.graphics.setNewFont(20)
  
  -- Load the tilesheet
  tilesetImage = love.graphics.newImage("assets/medievalTileset.png")
  tileSize = 16
  
  -- Background tiles
  bgTiles = {}
  bgTiles[1] = getQuad(1, 1)
  bgTiles[2] = getQuad(3, 0)
  bgTiles[3] = getQuad(3, 1)
  
  -- Obstacles
  obTiles = {}
  obTiles[1] = getQuad(13, 5)
  obTiles[2] = getQuad(9, 7)
  
  -- Initalise the map
  mapWidth = 60
  mapHeight = 40
  
  tileScale = 4
  
  visibleTilesWidth = 15
  visibleTilesHeight = 11
  
  cameraX = 0
  cameraY = 0
  
  map = {}
  for x = 1, mapWidth do
    map[x] = {}
    for y = 1, mapHeight do
      map[x][y] = love.math.random(1, #bgTiles)
    end
  end
  
  obstacles = {}
  for x = 1, mapWidth do
    obstacles[x] = {}
    for y = 1, mapHeight do
      obstacles[x][y] = love.math.random(-10, #obTiles)
    end
  end
  
  player = {
    x = 0,
    y = 0,
    moveCooldown = 0.2, -- In seconds
    moveTimer = 10000000,
    img = love.graphics.newImage("assets/player.png"),
    breakMode = false
  }
end

function getQuad(x, y)
  return love.graphics.newQuad(
    x * tileSize,
    y * tileSize,
    tileSize,
    tileSize,
    tilesetImage:getWidth(),
    tilesetImage:getHeight())
end

function checkCollision(xOff, yOff)
  xOff = xOff or 0
  yOff = yOff or 0
  local o = obstacles[player.x+xOff+1]
  if o ~= nil then
    o = o[player.y+yOff+1]
    if o ~= nil and o > 0 then
      return true
    else
      return false
    end
  end
end

function love.update(dt)
  -- Exit on escape
  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end
  
  -- Player & camera movement
  playerXOffset = player.x - cameraX
  playerYOffset = player.y - cameraY
  
  if player.moveTimer >= player.moveCooldown and not player.breakMode then
    if love.keyboard.isDown("up") and not checkCollision(0, -1) then
      player.y = player.y - 1
      if player.y < 0 then player.y = 0 end
      
      if playerYOffset <= 5 then cameraY = cameraY - 1 end
      if cameraY < 0 then
        cameraY = 0
      end
      
      player.moveTimer = 0
    end
    
    if love.keyboard.isDown("right") and not checkCollision(1, 0) then
      player.x = player.x + 1
      if player.x >= mapWidth then player.x = mapWidth-1 end
      
      if playerXOffset >= 7 then cameraX = cameraX + 1 end
      if cameraX > mapWidth - visibleTilesWidth then
        cameraX = mapWidth - visibleTilesWidth
      end
      
      player.moveTimer = 0
    end
    
    if love.keyboard.isDown("down") and not checkCollision(0, 1) then
      player.y = player.y + 1
      if player.y >= mapHeight then player.y = mapHeight-1 end
      
      if playerYOffset >= 5 then cameraY = cameraY + 1 end
      if cameraY > mapHeight - visibleTilesHeight then
        cameraY = mapHeight - visibleTilesHeight
      end
      
      player.moveTimer = 0
    end
    
    if love.keyboard.isDown("left") and not checkCollision(-1, 0) then
      player.x = player.x - 1
      if player.x < 0 then player.x = 0 end
      
      if playerXOffset <= 7 then cameraX = cameraX - 1 end
      if cameraX < 0 then
        cameraX = 0
      end
      
      player.moveTimer = 0
    end
  end
    
  -- Check if in break mode
  if love.keyboard.isDown("x") then
    player.breakMode = true
  else
    player.breakMode = false 
  end
  
  if player.breakMode then
    if love.keyboard.isDown("up") and player.y > 0 then
      obstacles[player.x+1][player.y] = 0
    end
    
    if love.keyboard.isDown("right") and player.x < mapWidth - 1 then
      obstacles[player.x+2][player.y+1] = 0
    end
    
    if love.keyboard.isDown("down") and player.y < mapHeight - 1 then
      obstacles[player.x+1][player.y+2] = 0
    end
    
    if love.keyboard.isDown("left") and player.x > 0 then
      obstacles[player.x][player.y+1] = 0
    end
  end

  -- Update the player move timer
  player.moveTimer = player.moveTimer + dt
end

function love.draw()
  local tileDisplaySize = tileSize * tileScale
  
  for x = 1, visibleTilesWidth do
    for y = 1, visibleTilesHeight do
      -- Draw background
      love.graphics.draw(tilesetImage, bgTiles[map[x+cameraX][y+cameraY]], (x-1) * tileDisplaySize, (y-1) * tileDisplaySize, 0, tileScale, tileScale)
      
      -- Draw obstacles
      obstacle = obstacles[x+cameraX][y+cameraY]
      if obstacle > 0 then
        love.graphics.draw(tilesetImage, obTiles[obstacle], (x-1) * tileDisplaySize, (y-1) * tileDisplaySize, 0, tileScale, tileScale)
      end
    end
  end
  
  -- Draw player
  love.graphics.draw(player.img, (player.x-cameraX) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, 0, tileScale, tileScale)
  
  if player.breakMode then
    -- Draw break halo
    love.graphics.rectangle("line", (player.x-cameraX) * tileDisplaySize, (player.y-cameraY-1) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX+1) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX) * tileDisplaySize, (player.y-cameraY+1) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX-1) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
  end
  
  -- Write debug text
  love.graphics.print("PX: " .. player.x .. " PY: " .. player.y .. " SX: " .. cameraX .. " SY: " .. cameraY, 10, 10)
end