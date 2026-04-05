-- src/states/play.lua
-- Main gameplay state

local Map    = require("src.world.map")
local Player = require("src.entities.player")
local Dino   = require("src.entities.dino")
local Coin   = require("src.entities.coin")
local Enemy  = require("src.entities.enemy")
local Arrow  = require("src.entities.arrow")
local Effect = require("src.entities.effect")
local Camera = require("src.systems.camera")
local HUD    = require("src.systems.hud")
local Audio  = require("src.systems.audio")

local VIRTUAL_W, VIRTUAL_H = 320, 288
local NUM_MAPS = Map.getNumMaps()

local PlayState = {}

local map, player, dino, camera
local coins   = {}
local enemies = {}
local arrows  = {}
local effects = {}
local surviveTime
local bestTime  = 0
local score     = 0
local bestScore = 0
local portalCooldown = 0
local dustTimer = 0

-- Cross-map persistent state
local mapSavedState = {}

-- ── Helpers ──────────────────────────────────────────────────
local function initCoins()
    coins = {}
    local saved = mapSavedState[map.mapIndex]
    for i, pos in ipairs(map:getCoinPositions()) do
        local c = Coin.new(pos.x, pos.y)
        if saved and saved.coinCollected[i] then
            c.collected = true
        end
        table.insert(coins, c)
    end
end

local function initEnemies()
    enemies = {}
    local saved = mapSavedState[map.mapIndex]
    for i, pos in ipairs(map:getEnemyPositions()) do
        local en = Enemy.new(pos[1], pos[2])
        if saved and saved.enemyHp[i] ~= nil then
            en.hp = saved.enemyHp[i]
        end
        table.insert(enemies, en)
    end
end

local function initDino()
    local saved = mapSavedState[map.mapIndex]
    dino = Dino.new(9 * 32 + 16, 8 * 32 + 16)
    if saved and saved.dinoHp ~= nil then
        dino.hp = saved.dinoHp
    end
end

local function saveMapState()
    local state = { coinCollected = {}, enemyHp = {}, dinoHp = dino.hp }
    for i, c in ipairs(coins) do
        state.coinCollected[i] = c.collected
    end
    for i, en in ipairs(enemies) do
        state.enemyHp[i] = en.hp
    end
    mapSavedState[map.mapIndex] = state
end

local function clearTransientWorldState()
    arrows = {}
    effects = {}
    dustTimer = 0
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

    if dirX == 0 and dirY == 0 then return end

    if player:canShoot() then
        player:beginShoot(dirX, dirY)
        local arrowX, arrowY = player:getArrowSpawn()
        table.insert(arrows, Arrow.new(arrowX, arrowY, dirX, dirY))
        Audio.playBowAttack()
    end
end

local function updateArrows(dt)
    for index = #arrows, 1, -1 do
        local arrow = arrows[index]
        local shouldRemove = arrow:update(dt, map)

        if not shouldRemove and dino:isAlive() and arrow:touches(dino.x, dino.y, dino:getHitRadius()) then
            local killed = dino:hit()
            if killed then
                score = score + 100
                spawnExplosion(dino.x, dino.y)
                Audio.playRandomBlocked()
            else
                score = score + 20
                Audio.playRandomHit()
            end
            shouldRemove = true
        end

        if not shouldRemove then
            for enemyIndex = #enemies, 1, -1 do
                local enemy = enemies[enemyIndex]
                if enemy:isAlive() and arrow:touches(enemy.x, enemy.y, enemy:getHitRadius()) then
                    local killed = enemy:hit()
                    if killed then
                        score = score + 35
                        spawnExplosion(enemy.x, enemy.y)
                        Audio.playRandomBlocked()
                    else
                        score = score + 10
                        Audio.playRandomHit()
                    end
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

local function getTotalProgress()
    local totalCoins, collectedCoins = 0, 0
    local totalMonsters, killedMonsters = 0, 0

    for mi = 1, NUM_MAPS do
        local coinCount = Map.getCoinCount(mi)
        local enemyCount = Map.getEnemyCount(mi)
        totalCoins = totalCoins + coinCount
        totalMonsters = totalMonsters + enemyCount + 1  -- +1 for dino

        local s = mapSavedState[mi]
        if s then
            for i = 1, coinCount do
                if s.coinCollected[i] then collectedCoins = collectedCoins + 1 end
            end
            if s.dinoHp and s.dinoHp <= 0 then killedMonsters = killedMonsters + 1 end
            for i = 1, enemyCount do
                if s.enemyHp[i] and s.enemyHp[i] <= 0 then killedMonsters = killedMonsters + 1 end
            end
        end
    end

    -- Also count current map live state
    local s = mapSavedState[map.mapIndex]
    if not s then
        for i, c in ipairs(coins) do
            if c.collected then collectedCoins = collectedCoins + 1 end
        end
        if not dino:isAlive() then killedMonsters = killedMonsters + 1 end
        for _, en in ipairs(enemies) do
            if not en:isAlive() then killedMonsters = killedMonsters + 1 end
        end
    end

    return {
        collectedCoins = collectedCoins,
        totalCoins = totalCoins,
        killedMonsters = killedMonsters,
        totalMonsters = totalMonsters,
        numMaps = NUM_MAPS,
    }
end

local function checkWinCondition()
    saveMapState()

    for mi = 1, NUM_MAPS do
        local s = mapSavedState[mi]
        if not s then return false end

        local mapCoins = Map.getCoinCount(mi)
        for i = 1, mapCoins do
            if not s.coinCollected[i] then return false end
        end

        if s.dinoHp > 0 then return false end

        local mapEnemyCount = Map.getEnemyCount(mi)
        for i = 1, mapEnemyCount do
            if s.enemyHp[i] and s.enemyHp[i] > 0 then return false end
        end
    end

    return true
end

local function switchMap(dest)
    saveMapState()
    map            = Map.new(dest.mapIndex)
    player.x       = dest.spawnX
    player.y       = dest.spawnY
    portalCooldown = 1.5
    initCoins()
    initEnemies()
    initDino()
    clearTransientWorldState()
end

-- ── Public API ───────────────────────────────────────────────
function PlayState.enter()
    mapSavedState = {}
    map           = Map.new(1)
    player        = Player.new(2 * 32 + 16, 2 * 32 + 16)
    camera        = Camera.new(VIRTUAL_W, VIRTUAL_H)
    surviveTime   = 0
    score         = 0
    portalCooldown = 0
    initCoins()
    initEnemies()
    initDino()
    clearTransientWorldState()
    Audio.startMusic()
end

function PlayState.update(dt)
    surviveTime    = surviveTime + dt
    portalCooldown = math.max(0, portalCooldown - dt)
    Audio.updateFootstepTimer(dt)

    player:update(dt, map)
    tryShoot()
    dino:update(dt, map, player)
    for _, en in ipairs(enemies) do en:update(dt, map) end
    updateArrows(dt)
    spawnDust(dt)
    updateEffects(dt)

    -- Footstep sounds when player is moving
    if player.moving then
        Audio.playFootstep()
    end

    for _, coin in ipairs(coins) do
        coin:update(dt)
        if coin:checkCollect(player) then
            score = score + 10
            Audio.playCoinPickup()
        end
    end

    camera:follow(player, map:getWidth(), map:getHeight())

    if portalCooldown <= 0 then
        local tile = map:getTileAt(player.x, player.y)
        if tile == 2 then
            Audio.playPortal()
            switchMap(map:getPortalDest())
        end
    end

    -- Game-over checks
    if dino:touches(player) then
        if surviveTime > bestTime  then bestTime  = surviveTime end
        if score       > bestScore then bestScore = score end
        Audio.stopMusic()
        Audio.playGameOver()
        return "gameover", { surviveTime = surviveTime, score = score, bestTime = bestTime, bestScore = bestScore }
    end
    for _, en in ipairs(enemies) do
        if en:touches(player) then
            if surviveTime > bestTime  then bestTime  = surviveTime end
            if score       > bestScore then bestScore = score end
            Audio.stopMusic()
            Audio.playGameOver()
            return "gameover", { surviveTime = surviveTime, score = score, bestTime = bestTime, bestScore = bestScore }
        end
    end

    -- Win condition
    if checkWinCondition() then
        if surviveTime > bestTime  then bestTime  = surviveTime end
        if score       > bestScore then bestScore = score end
        Audio.stopMusic()
        Audio.playWin()
        return "win", { surviveTime = surviveTime, score = score, bestTime = bestTime, bestScore = bestScore }
    end

    return nil
end

function PlayState.draw()
    local scaleX = love.graphics.getWidth() / VIRTUAL_W
    local scaleY = love.graphics.getHeight() / VIRTUAL_H
    love.graphics.push()
    love.graphics.scale(scaleX, scaleY)

    camera:apply()

    map:draw()
    drawEffects("back")

    for _, coin in ipairs(coins) do coin:draw() end
    for _, en   in ipairs(enemies) do en:draw() end

    player:draw()
    for _, arrow in ipairs(arrows) do arrow:draw() end
    dino:draw()
    drawEffects("front")

    camera:release()

    saveMapState()
    HUD.draw(VIRTUAL_W, VIRTUAL_H, surviveTime, score, map, getTotalProgress())

    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end

return PlayState
