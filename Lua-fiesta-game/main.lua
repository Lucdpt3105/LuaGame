local Map    = require("map")
local Player = require("player")
local Dino   = require("dino")
local Coin   = require("coin")
local Enemy  = require("enemy")
local Arrow  = require("arrow")
local Effect = require("effect")

local VIRTUAL_W, VIRTUAL_H = 320, 288

local map, player, dino
local coins   = {}
local enemies = {}
local arrows  = {}
local effects = {}
local gameState
local surviveTime
local bestTime  = 0
local score     = 0
local bestScore = 0
local camX, camY = 0, 0
local portalCooldown = 0
local dustTimer = 0

local function getScreenScale()
    return love.graphics.getWidth() / VIRTUAL_W, love.graphics.getHeight() / VIRTUAL_H
end

-- ── Helpers ──────────────────────────────────────────────────
local function initCoins()
    coins = {}
    for _, pos in ipairs(map:getCoinPositions()) do
        table.insert(coins, Coin.new(pos.x, pos.y))
    end
end

local function initEnemies()
    enemies = {}
    for _, pos in ipairs(map:getEnemyPositions()) do
        table.insert(enemies, Enemy.new(pos[1], pos[2]))
    end
end

local function clearTransientWorldState()
    arrows = {}
    effects = {}
    dustTimer = 0
end

local function updateCamera()
    local maxCamX = math.max(0, map:getWidth() - VIRTUAL_W)
    local maxCamY = math.max(0, map:getHeight() - VIRTUAL_H)
    camX = player.x - VIRTUAL_W / 2
    camY = player.y - VIRTUAL_H / 2
    camX = math.max(0, math.min(camX, maxCamX))
    camY = math.max(0, math.min(camY, maxCamY))
end

local function doGameOver()
    if gameState ~= "playing" then return end
    gameState = "gameover"
    if surviveTime > bestTime  then bestTime  = surviveTime end
    if score       > bestScore then bestScore = score end
end

local function switchMap(dest)
    map            = Map.new(dest.mapIndex)
    player.x       = dest.spawnX
    player.y       = dest.spawnY
    dino           = Dino.new(9 * 32 + 16, 8 * 32 + 16)
    portalCooldown = 1.5    -- prevent instant re-trigger
    initCoins()
    initEnemies()
    clearTransientWorldState()
end

local function spawnExplosion(x, y)
    table.insert(effects, Effect.newExplosion(x, y))
end

local function tryShoot()
    local dirX, dirY = 0, 0
    if love.keyboard.isDown("left") then dirX = dirX - 1 end
    if love.keyboard.isDown("right") then dirX = dirX + 1 end
    if love.keyboard.isDown("up") then dirY = dirY - 1 end
    if love.keyboard.isDown("down") then dirY = dirY + 1 end

    if dirX == 0 and dirY == 0 then
        return
    end

    if player:canShoot() then
        player:beginShoot(dirX, dirY)
        local arrowX, arrowY = player:getArrowSpawn()
        table.insert(arrows, Arrow.new(arrowX, arrowY, dirX, dirY))
    end
end

local function updateArrows(dt)
    for index = #arrows, 1, -1 do
        local arrow = arrows[index]
        local shouldRemove = arrow:update(dt, map)

        if not shouldRemove and dino:isAlive() and arrow:touches(dino.x, dino.y, dino:getHitRadius()) then
            dino:kill()
            score = score + 100
            spawnExplosion(dino.x, dino.y)
            shouldRemove = true
        end

        if not shouldRemove then
            for enemyIndex = #enemies, 1, -1 do
                local enemy = enemies[enemyIndex]
                if enemy:isAlive() and arrow:touches(enemy.x, enemy.y, enemy:getHitRadius()) then
                    enemy:kill()
                    score = score + 35
                    spawnExplosion(enemy.x, enemy.y)
                    table.remove(enemies, enemyIndex)
                    shouldRemove = true
                    break
                end
            end
        end

        if shouldRemove then
            table.remove(arrows, index)
        end
    end
end

local function updateEffects(dt)
    for index = #effects, 1, -1 do
        if effects[index]:update(dt) then
            table.remove(effects, index)
        end
    end
end

local function spawnDust(dt)
    if player.moving then
        dustTimer = dustTimer + dt
        if dustTimer >= 0.08 then
            dustTimer = 0
            table.insert(effects, Effect.newDust(player.x - player.facing * 10, player.y + 11, player.facing))
        end
    else
        dustTimer = 0
    end
end

local function drawEffects(layer)
    for _, effect in ipairs(effects) do
        if effect.layer == layer then
            effect:draw()
        end
    end
end

local function drawHud()
    love.graphics.setColor(0.08, 0.11, 0.09, 0.85)
    love.graphics.rectangle("fill", 6, 6, VIRTUAL_W - 12, 28, 8, 8)
    love.graphics.rectangle("fill", 6, VIRTUAL_H - 30, VIRTUAL_W - 12, 18, 8, 8)

    love.graphics.setColor(0.95, 0.96, 0.88)
    love.graphics.print(string.format("Time %.1fs", surviveTime), 14, 14)

    love.graphics.setColor(1, 0.84, 0.18)
    love.graphics.print("Score " .. score, 88, 14)

    local monsterCount = #enemies + (dino:isAlive() and 1 or 0)
    love.graphics.setColor(0.97, 0.4, 0.33)
    love.graphics.print("Monsters " .. monsterCount, 155, 14)

    local collected = 0
    for _, coin in ipairs(coins) do
        if coin.collected then
            collected = collected + 1
        end
    end

    love.graphics.setColor(0.77, 0.67, 1)
    love.graphics.print("Map " .. map.mapIndex .. "/2", 240, 14)
    love.graphics.setColor(0.95, 0.96, 0.88)
    love.graphics.print("WASD move  Arrows shoot", 12, VIRTUAL_H - 26)

    love.graphics.setColor(1, 0.85, 0.18)
    love.graphics.print(collected .. "/" .. #coins .. " coins", VIRTUAL_W - 64, VIRTUAL_H - 26)
end

-- ── Start / restart game ─────────────────────────────────────
function startGame(mapIndex, spawnX, spawnY)
    mapIndex = mapIndex or 1
    spawnX   = spawnX   or 2 * 32 + 16
    spawnY   = spawnY   or 2 * 32 + 16

    map           = Map.new(mapIndex)
    player        = Player.new(spawnX, spawnY)
    dino          = Dino.new(9 * 32 + 16, 8 * 32 + 16)
    gameState     = "playing"
    surviveTime   = 0
    score         = 0
    camX, camY    = 0, 0
    portalCooldown = 0
    initCoins()
    initEnemies()
    clearTransientWorldState()
end

-- ── LÖVE callbacks ───────────────────────────────────────────
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())
    startGame()
end

function love.update(dt)
    if gameState == "playing" then
        surviveTime      = surviveTime + dt
        portalCooldown   = math.max(0, portalCooldown - dt)

        player:update(dt, map)
        tryShoot()
        dino:update(dt, map, player)
        for _, en in ipairs(enemies) do en:update(dt, map) end
        updateArrows(dt)
        spawnDust(dt)
        updateEffects(dt)

        -- Collect coins
        for _, coin in ipairs(coins) do
            coin:update(dt)
            if coin:checkCollect(player) then
                score = score + 10
            end
        end

        updateCamera()

        -- Portal detection (only when cooldown has expired)
        if portalCooldown <= 0 then
            local tile = map:getTileAt(player.x, player.y)
            if tile == 2 then
                switchMap(map:getPortalDest())
            end
        end

        -- Game-over checks
        if dino:touches(player) then doGameOver() end
        for _, en in ipairs(enemies) do
            if en:touches(player) then doGameOver() end
        end
    end

    if gameState == "gameover" then
        if love.keyboard.isDown("r") then
            startGame()
        end
    end
end

function love.draw()
    local scaleX, scaleY = getScreenScale()
    love.graphics.push()
    love.graphics.scale(scaleX, scaleY)

    love.graphics.push()
    love.graphics.translate(-camX, -camY)

    map:draw()
    drawEffects("back")

    for _, coin in ipairs(coins) do coin:draw() end
    for _, en   in ipairs(enemies) do en:draw() end

    player:draw()
    for _, arrow in ipairs(arrows) do arrow:draw() end
    dino:draw()
    drawEffects("front")

    love.graphics.pop()

    drawHud()

    if gameState == "gameover" then
        love.graphics.setColor(0, 0, 0, 0.72)
        love.graphics.rectangle("fill", 0, 0, VIRTUAL_W, VIRTUAL_H)

        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf("CAUGHT!", 0, 85, VIRTUAL_W, "center")

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(string.format("Time:  %.1f s", surviveTime),  0, 118, VIRTUAL_W, "center")
        love.graphics.printf("Score: " .. score,                           0, 138, VIRTUAL_W, "center")
        love.graphics.printf(string.format("Best Time:  %.1f s", bestTime), 0, 162, VIRTUAL_W, "center")
        love.graphics.printf("Best Score: " .. bestScore,                  0, 182, VIRTUAL_W, "center")

        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Press R to retry", 0, 210, VIRTUAL_W, "center")
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end

