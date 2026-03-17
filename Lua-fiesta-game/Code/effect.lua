local Effect = {}
Effect.__index = Effect

local dustImage
local explosionImage
local dustQuads
local explosionQuads

local function buildQuads(image, frameWidth, frameHeight)
    local quads = {}
    local count = math.floor(image:getWidth() / frameWidth)
    for index = 0, count - 1 do
        quads[index + 1] = love.graphics.newQuad(
            index * frameWidth,
            0,
            frameWidth,
            frameHeight,
            image:getWidth(),
            image:getHeight()
        )
    end
    return quads
end

local function ensureAssets()
    if not dustImage then
        dustImage = love.graphics.newImage("Dust_01.png")
        explosionImage = love.graphics.newImage("Explosion_01.png")
        dustQuads = buildQuads(dustImage, 64, 64)
        explosionQuads = buildQuads(explosionImage, 192, 192)
    end
end

function Effect.newDust(x, y, facing)
    ensureAssets()
    local self = setmetatable({}, Effect)
    self.kind = "dust"
    self.x = x
    self.y = y
    self.timer = 0
    self.duration = 0.42
    self.image = dustImage
    self.quads = dustQuads
    self.scale = 0.52
    self.rotation = facing == -1 and math.pi or 0
    self.ox = 32
    self.oy = 32
    self.layer = "back"
    return self
end

function Effect.newExplosion(x, y)
    ensureAssets()
    local self = setmetatable({}, Effect)
    self.kind = "explosion"
    self.x = x
    self.y = y
    self.timer = 0
    self.duration = 0.5
    self.image = explosionImage
    self.quads = explosionQuads
    self.scale = 0.22
    self.rotation = 0
    self.ox = 96
    self.oy = 96
    self.layer = "front"
    return self
end

function Effect:update(dt)
    self.timer = self.timer + dt
    return self.timer >= self.duration
end

function Effect:draw()
    local progress = self.timer / self.duration
    local frame = math.min(#self.quads, math.floor(progress * #self.quads) + 1)
    local alpha = 1 - math.max(0, progress - 0.55) / 0.45

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(
        self.image,
        self.quads[frame],
        self.x,
        self.y,
        self.rotation,
        self.scale,
        self.scale,
        self.ox,
        self.oy
    )
end

return Effect