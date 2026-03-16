local Dino = {}
Dino.__index = Dino

function Dino.new(x, y)
    local self = setmetatable({}, Dino)
    self.x      = x
    self.y      = y
    self.speed  = 55
    self.size   = 24
    self.alive  = true
    self.image  = love.graphics.newImage("Hungry-dino 2.png")
    local imgW  = self.image:getWidth()
    local imgH  = self.image:getHeight()
    self.scaleX = self.size / imgW
    self.scaleY = self.size / imgH
    self.ox     = imgW / 2   -- draw origin at image centre (enables flip)
    self.oy     = imgH / 2
    self.facing = 1           -- 1 = right, -1 = left
    return self
end

function Dino:update(dt, map, player)
    if not self.alive then
        return
    end

    local dx   = player.x - self.x
    local dy   = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 1 then
        local nx   = dx / dist
        local ny   = dy / dist
        local newX = self.x + nx * self.speed * dt
        local newY = self.y + ny * self.speed * dt

        if not map:collides(newX, self.y, self.size) then
            self.x = newX
        end
        if not map:collides(self.x, newY, self.size) then
            self.y = newY
        end

        -- Face the direction of travel
        if dx ~= 0 then
            self.facing = dx > 0 and 1 or -1
        end
    end
end

function Dino:draw()
    if not self.alive then
        return
    end

    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.ellipse("fill", self.x, self.y + 10, 10, 4)

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        self.image,
        self.x, self.y,
        0,
        self.facing * self.scaleX, self.scaleY,
        self.ox, self.oy
    )
end

function Dino:touches(player)
    if not self.alive then
        return false
    end

    local dx   = self.x - player.x
    local dy   = self.y - player.y
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist < (self.size / 2 + player.size / 2)
end

function Dino:isAlive()
    return self.alive
end

function Dino:kill()
    self.alive = false
end

function Dino:getHitRadius()
    return self.size * 0.45
end

return Dino

