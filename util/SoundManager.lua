local SoundManager = class "SoundManager"
local util = require "util.util"
--require "libs.slam" -- directly embeds itself into love.audio

local soundDirectory = "sounds/"
local availableSounds = {"explosion", "hit", "jump", "pickup", "wobble" }
local availableMusic = {"darkraqqen_mani_future_imperfections"}

local minPitch, maxPitch = 0.5, 2.0
local scale = 15 -- px / sound meter (sound world scale)

function SoundManager:init()
    self.sounds, self.music = {}, {}
    for _, soundName in pairs(availableSounds) do
        self.sounds[soundName] = love.audio.newSource(soundDirectory .. soundName .. ".wav", "static")
    end
    for musicIndex, musicName in pairs(availableMusic) do
        self.music[musicName] = love.audio.newSource(soundDirectory .. musicName .. ".ogg", "stream")
        self.music[musicIndex] = self.music[musicName]
    end
end

function SoundManager:setCenterPosition(x, y, z)
    love.audio.setPosition(x / scale, y / scale, z / scale)
end

function SoundManager:playMusic(musicNameOrIndex, looping, volume)
    looping = not looping and true
    volume = volume or 1.0

    local music = self.music[musicNameOrIndex]
    if not music then
        error("Couldn't find music track: " .. musicNameOrIndex)
    end

    music:setLooping(looping)
    music:setVolume(volume)
    music:play()
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