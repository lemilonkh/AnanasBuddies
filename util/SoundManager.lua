local SoundManager = class "SoundManager"
local util = require "util.util"
--require "libs.slam" -- directly embeds itself into love.audio

local soundDirectory = "sounds/"
local availableSounds = {"explosion", "hit", "jump", "pickup", "wobble"}

local minPitch, maxPitch = 0.5, 2.0
local scale = 15 -- px / sound meter (sound world scale)

function SoundManager:init()
    self.sounds = {}
    for _, soundName in pairs(availableSounds) do
        self.sounds[soundName] = love.audio.newSource(soundDirectory .. soundName .. ".wav", "static")
    end
end

function SoundManager:setCenterPosition(x, y, z)
    love.audio.setPosition(x / scale, y / scale, z / scale)
end

function SoundManager:play(soundName, pitch, x, y, z, relative)
    pitch = pitch or 1

    if pitch == "random" then
        pitch = util.random(minPitch, maxPitch)
    end

    relative = relative or false

    local sound = self.sounds[soundName]
    sound:setPitch(pitch)
    local instance = sound:play()
--    instance:setPitch(pitch)
--
--    if x or y or z then
--        x, y, z = x or 0, y or 0, z or 0
--
--        instance:setPosition(x / scale, y / scale, z / scale)
--        instance:setRelative(relative)
--    end
end

return SoundManager