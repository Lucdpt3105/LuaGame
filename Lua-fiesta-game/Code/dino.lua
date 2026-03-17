local Dino = {}
Dino.__index = Dino

function Dino.new(x, y)
    local self = setmetatable({}, Dino)
    self.x      = x
    self.y      = y
    self.speed  = 55
    self.size   = 24
    self.hp     = 3
    self.maxHp  = 3
    self.image  = love.graphics.newImage("Hungry-dino 2.png")
    local imgW  = self.image:getWidth()
    local imgH  = self.image:getHeight()
    self.scaleX = self.size / imgW
    self.scaleY = self.size / imgH
    self.ox     = imgW / 2
    self.oy     = imgH / 2
    self.facing = 1
    self.hitFlash = 0
    return self
end

function Dino:update(dt, map, player)
    if not self:isAlive() then return end

    self.hitFlash = math.max(0, self.hitFlash - dt)

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

        if dx ~= 0 then
            self.facing = dx > 0 and 1 or -1
        end
    end
end

function Dino:draw()
    if not self:isAlive() then return end

    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.ellipse("fill", self.x, self.y + 10, 10, 4)

    if self.hitFlash > 0 then
        love.graphics.setColor(1, 0.4, 0.4)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.draw(
        self.image,
        self.x, self.y,
        0,
        self.facing * self.scaleX, self.scaleY,
        self.ox, self.oy
    )

    -- HP bar
    if self.hp < self.maxHp then
        local barW = 24
        local barH = 3
        local bx   = self.x - barW / 2
        local by   = self.y - 16
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", bx, by, barW, barH)
        love.graphics.setColor(0.9, 0.25, 0.2)
        love.graphics.rectangle("fill", bx, by, barW * (self.hp / self.maxHp), barH)
    end
end

function Dino:hit()
    self.hp = self.hp - 1
    self.hitFlash = 0.15
    return self.hp <= 0
end

function Dino:touches(player)
    if not self:isAlive() then return false end
    local dx   = self.x - player.x
    local dy   = self.y - player.y
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist < (self.size / 2 + player.size / 2)
end

function Dino:isAlive()
    return self.hp > 0
end

function Dino:kill()
    self.hp = 0
end

function Dino:getHitRadius()
    return self.size * 0.45
end

return Dino
