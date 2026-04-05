-- main.lua
-- Thin state manager: delegates to the current game state

local states = {
    play     = require("src.states.play"),
    gameover = require("src.states.gameover"),
    win      = require("src.states.win"),
}

local fontManager = require("src.utils.fontManager")  -- Thêm font manager

local currentState
local currentName
local playState  -- keep reference for background drawing

local function switchState(name, params)
    currentName = name
    currentState = states[name]
    currentState.enter(params)
end

function love.load()
    fontManager.init()  -- Khởi tạo font hỗ trợ Việt
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())
    playState = states.play
    switchState("play")
end

function love.update(dt)
    local nextState, params = currentState.update(dt)
    if nextState then
        if nextState == "play" then
            switchState("play")
        else
            switchState(nextState, params)
        end
    end
end

function love.draw()
    -- Always draw the play state as background (frozen when not active)
    playState.draw()

    -- Overlay states draw on top
    if currentName ~= "play" then
        currentState.draw()
    end
end
