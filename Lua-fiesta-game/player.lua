local Player = {}
Player.__index = Player

local FRAME_SIZE = 192
local IDLE_FPS = 7
local RUN_FPS = 10
local SHOOT_FPS = 18
local DRAW_SCALE = 0.24

local idleImage
local runImage
local shootImage
local idleQuads
local runQuads
local shootQuads

local function buildQuads(image)
    local quads = {}
    local frameCount = math.floor(image:getWidth() / FRAME_SIZE)
    for index = 0, frameCount - 1 do
        quads[index + 1] = love.graphics.newQuad(
            index * FRAME_SIZE,
            0,
            FRAME_SIZE,
            FRAME_SIZE,
            image:getWidth(),
            image:getHeight()
        )
    end
    return quads
end

local function ensureAssets()
    if not idleImage then
        idleImage = love.graphics.newImage("Archer/Archer_Idle.png")
        runImage = love.graphics.newImage("Archer/Archer_Run.png")
        shootImage = love.graphics.newImage("Archer/Archer_Shoot.png")
        idleQuads = buildQuads(idleImage)
        runQuads = buildQuads(runImage)
        shootQuads = buildQuads(shootImage)
    end
end

local function normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length == 0 then
        return 0, 0
    end
    return x / length, y / length
end

function Player.new(x, y)
    ensureAssets()

    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.speed = 122
    self.size = 20
    self.frameSize = FRAME_SIZE
    self.scale = DRAW_SCALE
    self.animTimer = 0
    self.facing = 1
    self.state = "idle"
    self.moving = false
    self.shootTimer = 0
    self.shootCooldown = 0
    self.aimX = 1
    self.aimY = 0
    self.shadowSize = 10
    return self
end

function Player:setState(nextState)
    if self.state ~= nextState then
        self.state = nextState
        self.animTimer = 0
    end
end

function Player:canShoot()
    return self.shootCooldown <= 0
end

function Player:beginShoot(dirX, dirY)
    dirX, dirY = normalize(dirX, dirY)
    if dirX == 0 and dirY == 0 then
        dirX = self.facing
    end

    self.aimX = dirX
    self.aimY = dirY
    if dirX ~= 0 then
        self.facing = dirX > 0 and 1 or -1
    end

    self.shootCooldown = 0.26
    self.shootTimer = #shootQuads / SHOOT_FPS
    self:setState("shoot")
end

function Player:getArrowSpawn()
    return self.x + self.aimX * 20, self.y - 2 + self.aimY * 10
end

function Player:update(dt, map)
    local moveX, moveY = 0, 0

    if love.keyboard.isDown("w") then moveY = moveY - 1 end
    if love.keyboard.isDown("s") then moveY = moveY + 1 end
    if love.keyboard.isDown("a") then moveX = moveX - 1 end
    if love.keyboard.isDown("d") then moveX = moveX + 1 end

    moveX, moveY = normalize(moveX, moveY)

    local newX = self.x + moveX * self.speed * dt
    local newY = self.y + moveY * self.speed * dt
    local prevX, prevY = self.x, self.y

    if moveX ~= 0 then
        self.facing = moveX > 0 and 1 or -1
    end

    if not map:collides(newX, self.y, self.size) then
        self.x = newX
    end
    if not map:collides(self.x, newY, self.size) then
        self.y = newY
    end

    self.moving = self.x ~= prevX or self.y ~= prevY
    self.shootCooldown = math.max(0, self.shootCooldown - dt)
    self.shootTimer = math.max(0, self.shootTimer - dt)

    if self.shootTimer > 0 then
        self:setState("shoot")
    elseif self.moving then
        self:setState("run")
    else
        self:setState("idle")
    end

    self.animTimer = self.animTimer + dt
end

function Player:getAnimation()
    if self.state == "run" then
        return runImage, runQuads, RUN_FPS, false
    end
    if self.state == "shoot" then
        return shootImage, shootQuads, SHOOT_FPS, true
    end
    return idleImage, idleQuads, IDLE_FPS, false
end

function Player:draw()
    local image, quads, fps, clampLastFrame = self:getAnimation()
    local frameIndex = math.floor(self.animTimer * fps) + 1
    if clampLastFrame then
        frameIndex = math.min(#quads, frameIndex)
    else
        frameIndex = ((frameIndex - 1) % #quads) + 1
    end

    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", self.x, self.y + 14, self.shadowSize, 4)

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        image,
        quads[frameIndex],
        self.x,
        self.y + 2,
        0,
        self.facing * self.scale,
        self.scale,
        self.frameSize / 2,
        self.frameSize / 2
    )
end

return Player

