-- src/systems/audio.lua
-- Audio manager system for game sound effects and music

local Audio = {}

-- Audio sources cache
local sources = {}
local musicSource = nil
local masterVolume = 0.7
local sfxVolume = 1.0
local musicVolume = 0.5
local audioEnabled = true

-- Footstep throttle
local footstepTimer = 0
local FOOTSTEP_INTERVAL = 0.28  -- seconds between footstep sounds

-- All audio file paths (relative to project root)
local SOUND_PATHS = {
    -- Bow / combat
    bow_attack      = "assets/audio/sfx/bow_attack.ogg",
    bow_hit         = "assets/audio/sfx/bow_hit.ogg",
    bow_putaway     = "assets/audio/sfx/bow_putaway.ogg",

    -- Footsteps
    footstep_stone  = "assets/audio/sfx/footstep_stone.ogg",
    footstep_wood   = "assets/audio/sfx/footstep_wood.ogg",

    -- Movement
    jump            = "assets/audio/sfx/jump.ogg",
    land            = "assets/audio/sfx/land.ogg",
    chain_jump      = "assets/audio/sfx/chain_jump.ogg",

    -- UI / Events  (reusing existing files creatively)
    coin_pickup     = "assets/audio/sfx/land.ogg",         -- short "thud" works for coin
    portal          = "assets/audio/sfx/chain_jump.ogg",   -- chain rattle = teleport
    game_over       = "assets/audio/sfx/bow_putaway.ogg",  -- somber put-away feel
    win             = "assets/audio/sfx/bow_hit.ogg",      -- impactful victory sting

    -- Music
    music_bg        = "assets/audio/music/background.mp3",
}

-- ── Internal helpers ─────────────────────────────────────────

local function loadSound(key)
    if sources[key] then return sources[key] end
    if not audioEnabled then return nil end

    local path = SOUND_PATHS[key]
    if not path then
        print("[Audio] Unknown key: " .. tostring(key))
        return nil
    end

    local ok, source = pcall(function()
        return love.audio.newSource(path, "static")
    end)

    if ok and source then
        sources[key] = source
        return source
    else
        print("[Audio] Failed to load '" .. key .. "' from: " .. path)
        return nil
    end
end

local function playClone(key, volume)
    if not audioEnabled then return end
    local source = loadSound(key)
    if not source then return end

    local clone = source:clone()
    clone:setVolume(masterVolume * sfxVolume * (volume or 1.0))
    love.audio.play(clone)
end

-- ── Combat sounds ────────────────────────────────────────────

function Audio.playBowAttack()
    playClone("bow_attack")
end

function Audio.playRandomHit()
    playClone("bow_hit")
end

function Audio.playRandomBlocked()
    playClone("bow_hit", 1.2)
end

-- ── Footsteps (with built-in throttle) ───────────────────────

function Audio.updateFootstepTimer(dt)
    if footstepTimer > 0 then
        footstepTimer = footstepTimer - dt
    end
end

function Audio.playFootstep()
    if footstepTimer > 0 then return end
    footstepTimer = FOOTSTEP_INTERVAL

    -- Randomly choose between stone and wood footstep
    local choices = { "footstep_stone", "footstep_wood" }
    playClone(choices[math.random(#choices)], 0.5)
end

-- ── Event sounds ─────────────────────────────────────────────

function Audio.playCoinPickup()
    playClone("coin_pickup", 0.6)
end

function Audio.playPortal()
    playClone("portal", 0.8)
end

function Audio.playGameOver()
    playClone("game_over", 1.0)
end

function Audio.playWin()
    playClone("win", 1.0)
end

-- ── Background music ─────────────────────────────────────────

function Audio.startMusic()
    if not audioEnabled then return end

    if musicSource then
        musicSource:stop()
    end

    local source = loadSound("music_bg")
    if not source then return end

    musicSource = source:clone()
    musicSource:setVolume(masterVolume * musicVolume)
    musicSource:setLooping(true)
    love.audio.play(musicSource)
end

function Audio.stopMusic()
    if musicSource then
        musicSource:stop()
        musicSource = nil
    end
end

-- ── Volume controls ──────────────────────────────────────────

function Audio.setMasterVolume(vol)
    masterVolume = math.max(0, math.min(1, vol))
end

function Audio.getMasterVolume()
    return masterVolume
end

function Audio.setSfxVolume(vol)
    sfxVolume = math.max(0, math.min(1, vol))
end

function Audio.setMusicVolume(vol)
    musicVolume = math.max(0, math.min(1, vol))
    if musicSource then
        musicSource:setVolume(masterVolume * musicVolume)
    end
end

function Audio.setEnabled(enabled)
    audioEnabled = enabled
    if not enabled then
        Audio.stopMusic()
    end
end

-- ── Lifecycle ────────────────────────────────────────────────

function Audio.cleanup()
    Audio.stopMusic()
    sources = {}
    footstepTimer = 0
end

function Audio.preload()
    if not audioEnabled then return end
    local critical = { "bow_attack", "bow_hit", "footstep_stone", "footstep_wood",
                       "coin_pickup", "portal", "game_over", "win", "music_bg" }
    for _, key in ipairs(critical) do
        loadSound(key)
    end
end

return Audio
