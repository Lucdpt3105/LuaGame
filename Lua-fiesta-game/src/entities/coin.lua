local Coin = {}
Coin.__index = Coin

local image

function Coin.new(x, y)
    local self = setmetatable({}, Coin)
    if not image then
        image = love.graphics.newImage("assets/sprites/items/Icon_03.png")
    end

    self.x = x
    self.y = y
    self.image = image
    self.collected = false
    self.radius = 9
    self.bobTimer = math.random() * math.pi * 2
    self.scale = 0.44
    self.ox = self.image:getWidth() / 2
    self.oy = self.image:getHeight() / 2
    return self
end

function Coin:update(dt)
    if not self.collected then
        self.bobTimer = self.bobTimer + dt * 3.2
    end
end

function Coin:draw()
    if self.collected then
        return
    end

    local bobY = math.sin(self.bobTimer) * 2.5
    local pulse = 1 + math.sin(self.bobTimer * 1.4) * 0.04

    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.ellipse("fill", self.x, self.y + 10, 8, 3)

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        self.image,
        self.x,
        self.y + bobY,
        0,
        self.scale * pulse,
        self.scale * pulse,
        self.ox,
        self.oy
    )
end

function Coin:checkCollect(player)
    if self.collected then
        return false
    end

    local dx = self.x - player.x
    local dy = self.y - player.y
    if math.sqrt(dx * dx + dy * dy) < self.radius + player.size * 0.5 then
        self.collected = true
        return true
    end

    return false
end

return Coin
