local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y)
    local self = setmetatable({}, Enemy)
    self.x = x
    self.y = y
    self.speed = 45
    self.size = 20
    self.alive = true
    -- Start moving in a random direction
    local angle = math.random() * math.pi * 2
    self.dirX = math.cos(angle)
    self.dirY = math.sin(angle)
    self.changeTimer = math.random() * 1.5 + 0.5   -- seconds until next direction change
    self.wobbleTimer = math.random() * math.pi * 2  -- phase offset for idle wobble
    return self
end

function Enemy:update(dt, map)
    if not self.alive then
        return
    end

    self.changeTimer = self.changeTimer - dt
    self.wobbleTimer = self.wobbleTimer + dt * 6

    -- Pick a new random direction periodically
    if self.changeTimer <= 0 then
        local angle = math.random() * math.pi * 2
        self.dirX = math.cos(angle)
        self.dirY = math.sin(angle)
        self.changeTimer = math.random() * 1.5 + 0.8
    end

    local newX = self.x + self.dirX * self.speed * dt
    local newY = self.y + self.dirY * self.speed * dt

    if not map:collides(newX, self.y, self.size) then
        self.x = newX
    else
        self.dirX = -self.dirX      -- bounce off horizontal wall
        self.changeTimer = 0.2      -- soon pick a new angle
    end
    if not map:collides(self.x, newY, self.size) then
        self.y = newY
    else
        self.dirY = -self.dirY      -- bounce off vertical wall
        self.changeTimer = 0.2
    end
end

function Enemy:draw()
    if not self.alive then
        return
    end

    local half = self.size / 2
    local bobY = math.sin(self.wobbleTimer) * 1.5
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", self.x + 1, self.y + half + bobY - 1, half * 0.85, 2)
    -- Body (red blob)
    love.graphics.setColor(0.85, 0.15, 0.2)
    love.graphics.ellipse("fill", self.x, self.y + bobY, half, half * 0.85)
    -- Eyes (white)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x - 3,  self.y - 3  + bobY, 3)
    love.graphics.circle("fill", self.x + 3,  self.y - 3  + bobY, 3)
    -- Pupils (black)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", self.x - 2.5, self.y - 2.5 + bobY, 1.5)
    love.graphics.circle("fill", self.x + 3.5, self.y - 2.5 + bobY, 1.5)
end

function Enemy:touches(player)
    if not self.alive then
        return false
    end

    local dx = self.x - player.x
    local dy = self.y - player.y
    return math.sqrt(dx * dx + dy * dy) < (self.size * 0.5 + player.size * 0.5)
end

function Enemy:isAlive()
    return self.alive
end

function Enemy:kill()
    self.alive = false
end

function Enemy:getHitRadius()
    return self.size * 0.5
end

return Enemy
