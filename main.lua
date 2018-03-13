-- main.lua
-- (c) 2018 by Milan Gruner

class = require "libs.30log"
inspect = require "libs.inspect"
local bump = require "libs.bump"
local anim8 = require "libs.anim8"

local util = require "util.util"
local ProgressBar = require "ui.ProgressBar"
local Background = require "fx.Background"
local SoundManager = require "util.SoundManager"
local Settings = require "data.Settings"
require "data.Entities"

local mobile = false
local noise
if love.system.getOS() == "iOS" or love.system.getOS() == "Android" then
    mobile = true
    Settings.scale = Settings.mobileScale
else
    noise = require "libs.noise"
end

local isRunning = true

local staminaBar, background, soundManager, noiseShader, noiseTimer

local function getScreenSize(unscaled)
    if unscaled then return love.graphics.getWidth(), love.graphics.getHeight() end
    return love.graphics.getWidth() / Settings.scale, love.graphics.getHeight() / Settings.scale
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    local font = love.graphics.newFont("fonts/permanent_marker.ttf", 40)
    love.graphics.setFont(font)

    if not mobile then
        noise.init()
        noiseShader = noise.build_shader("libs/noise.frag", Settings.noiseSeed)
        noiseTimer = 0
    end

    love.resize(love.graphics.getDimensions())

    soundManager = SoundManager()

    Player.sprite = love.graphics.newImage("sprites/ananas.png")
    local spriteWidth, spriteHeight = Player.sprite:getWidth(), Player.sprite:getHeight()
    local grid = anim8.newGrid(Player.width, Player.height, spriteWidth, spriteHeight)
    Player.animation = anim8.newAnimation(grid('1-7', 1), 0.1, "pauseAtEnd")
    Player.glassesAnimation = anim8.newAnimation(grid('1-7', 3), 0.1, "pauseAtEnd")

    Player.healthQuad = love.graphics.newQuad(0, 0, Player.width, Player.height, spriteWidth, spriteHeight)

    bumpWorld = bump.newWorld()
    bumpWorld:add(Player, Player.x, Player.y, Player.width, Player.height)
    bumpWorld:add(Ground, Ground.x, Ground.y, Ground.height, Ground.width)

    Obstacles.sprite = love.graphics.newImage("sprites/obstacles.png")
    local tileWidth, tileHeight = 16, 16
    for i = 1, Obstacles.count do
        local quad = love.graphics.newQuad((i - 1) * tileWidth, 0, tileWidth, tileHeight, Obstacles.sprite:getWidth(), Obstacles.sprite:getHeight())
        local width, height = Obstacles.defaultWidth, Obstacles.defaultHeight
        local x, y = love.graphics.getWidth() / Settings.scale + i * Obstacles.spacing, Ground.y - height
        local obstacle = {
            x = x, y = y, width = width, height = height, quad = quad, isObstacle = true, index = #Obstacles + 1
        }
        bumpWorld:add(obstacle, x, y, width, height)
        table.insert(Obstacles, obstacle)
    end

    local plantSprite = love.graphics.newImage("sprites/plant.png")
    local width, height = plantSprite:getWidth(), plantSprite:getHeight()
    for i = 1, Obstacles.pickupCount do
        local x = love.graphics.getWidth() / Settings.scale + Obstacles.count * Obstacles.spacing + i * Obstacles.spacing
        local y = Ground.y - height
        local plantObstacle = {
            x = x, y = y, width = width, height = height, sprite = plantSprite, isPickup = true, index = #Obstacles + 1
        }
        bumpWorld:add(plantObstacle, x, y, width, height)
        table.insert(Obstacles, plantObstacle)
    end

    staminaBar = ProgressBar("staminabar", 70, 35, 1, 0, "right", 24, 7, false)
    local width, height = getScreenSize()
    background = Background(width, height * (1 - Settings.groundPercentage))
end

local function jump()
    if Player.canJump then
        soundManager:play("jump", "random")
        Player.isJumping = true
        Player.canJump = false
        Player.hasLanded = false
        Player.velocityY = -Player.jumpVelocity
    end
end

local function fallFast()
    if Player.isJumping then
        Player.isJumping = false
        Player.velocityY = Player.velocityY + Player.jumpVelocity
    end
end

local function resetWorld()
    for i = 1, #Obstacles do
        Obstacles[i].x = love.graphics.getWidth() / Settings.scale + i * Obstacles.spacing
    end
end

local function removeObstacle(obstacle)
    bumpWorld:remove(obstacle)
    if Obstacles[obstacle.index] == obstacle then
        Obstacles[obstacle.index] = nil
    end
    --util.clearAllEqualValues(Obstacles, obstacle)
    --util.removeValue(Obstacles, obstacle)
end

local function resetGame()
    isRunning = true
    resetWorld()
    Player.score = 0
    Player.stamina = 0
end

local function gameOver()
    soundManager:play("explosion", "random")
    isRunning = false
    Player.health = 3
    print("Game over! Score: " .. math.floor(Player.score))
end

local function takeHit(obstacle)
    soundManager:play("hit", "random")
    Player.health = Player.health - 1
    -- TODO slow down time
    removeObstacle(obstacle)
    if Player.health <= 0 then
        gameOver()
    end
end

local function collectPickup(pickup)
    soundManager:play("pickup", "random")
    Player.stamina = Player.stamina + Settings.pickupStamina
    -- TODO add combo multiplier
--    bumpWorld:remove(pickup)
--    util.removeValue(Obstacles, pickup)
    pickup.x = love.graphics.getWidth() / Settings.scale + pickup.sprite:getWidth()
    bumpWorld:update(pickup, pickup.x, pickup.y)
end

function love.update(dt)
    if not isRunning then return end

    for i = 1, #Obstacles do
        local obstacle = Obstacles[i]
        if obstacle then
            obstacle.x = obstacle.x + Obstacles.velocityX * dt

            if obstacle.x < -obstacle.width then
                obstacle.x = love.graphics.getWidth() / Settings.scale + obstacle.width
                bumpWorld:update(obstacle, obstacle.x, obstacle.y)
            end

            local actualX, actualY, collisions = bumpWorld:move(obstacle, obstacle.x, obstacle.y)
            obstacle.x, obstacle.y = actualX, actualY

            for i = 1, #collisions do
                if collisions[i].other.isPlayer then
                    if obstacle.isObstacle then
                        takeHit(obstacle)
                    elseif obstacle.isPickup then
                        collectPickup(obstacle)
                    end
                end
            end
        end
    end

    if Player.stamina ~= staminaBar.targetValue then
        staminaBar:animateToValue(Player.stamina)
    end

    Player.animation:update(dt)
    Player.glassesAnimation:update(dt)
    if Player.isJumping then
        Player.animation:pauseAtStart()
        Player.glassesAnimation:pauseAtStart()
    else
        Player.animation:resume()
        Player.glassesAnimation:resume()
    end

    Player.velocityY = Player.velocityY + Player.gravity * dt

    if Player.velocityY > Player.maxFallVelocity then
        Player.velocityY = Player.gravity
    end

    local targetX = Player.x + Player.velocityX * dt
    local targetY = Player.y + Player.velocityY * dt
    local actualX, actualY, collisions = bumpWorld:move(Player, targetX, targetY)
    Player.x, Player.y = actualX, actualY

    for i = 1, #collisions do
        local collision = collisions[i]
        if collision.other.isGround then
            if not Player.hasLanded then
                Player.hasLanded = true
                soundManager:play("wobble", "random")
            end
            Player.canJump = true
            Player.isJumping = false
            Player.velocityY = 0
        elseif collision.other.isObstacle then
            takeHit(collision.other)
        elseif collision.other.isPickup then
            collectPickup(collision.other)
        end
    end

    Player.score = Player.score + dt * Settings.scoreMultiplier * math.floor(Player.stamina + 1)
    staminaBar:update(dt)
    background:update(dt, Settings.backgroundSpeed)
    if not mobile then
        noiseTimer = noiseTimer + dt
    end
end

function love.draw()
    love.graphics.setBackgroundColor(Settings.backgroundColor)
    love.graphics.setColor(255, 255, 255)
    local width, height = getScreenSize(true)

    background:draw(Settings.scale)

    love.graphics.push()
    love.graphics.scale(Settings.scale)

    for i = 1, #Obstacles do
        local obstacle = Obstacles[i]
        if obstacle then
            if obstacle.quad then
                love.graphics.draw(Obstacles.sprite, obstacle.quad, obstacle.x, obstacle.y)
            elseif obstacle.sprite then
                love.graphics.draw(obstacle.sprite, obstacle.x, obstacle.y)
            end
            if Settings.debugDraw then
                love.graphics.rectangle("line", obstacle.x, obstacle.y, obstacle.width, obstacle.height)
            end
        end
    end

    if Settings.debugDraw then
        love.graphics.setColor(255, 0, 0)
        love.graphics.rectangle("line", Player.x, Player.y, Player.width, Player.height)
    end

    love.graphics.setColor(Ground.color)
    love.graphics.rectangle("fill", Ground.x, Ground.y, Ground.width, Ground.height)

    -- overlay effects
    if not mobile then
        local noiseAlpha = util.fract(staminaBar.value) * Settings.maxNoiseAlpha
        love.graphics.setColor(50, 200, 70, noiseAlpha)
        noise.sample(noiseShader, noise.types.simplex3d, width, height, 0, 0, 1, 1, noiseTimer)

        if Player.stamina > 1 then
            love.graphics.setColor(255, 0, 50, noiseAlpha / 5)
            noise.sample(noiseShader, noise.types.simplex3d, width, height, 0, 0, 5, 5, noiseTimer * 2 + 10)
        end
        if Player.stamina > 2 then
            love.graphics.setColor(157, 59, 75, noiseAlpha + 20)
            noise.sample(noiseShader, noise.types.simplex3d, width, height, 5, 5, 7, 7, noiseTimer / 2 + 3.14)
        end
    end

    love.graphics.setColor(255, 255, 255)
    Player.animation:draw(Player.sprite, Player.x, Player.y)
    Player.glassesAnimation:draw(Player.sprite, Player.x, Player.y)

    -- UI
    love.graphics.pop()
    staminaBar:draw()
    for i = 0, Player.health - 1 do
        love.graphics.draw(Player.sprite, Player.healthQuad, i * (Player.width + 10) + 70, 10)
    end

    love.graphics.print(math.floor(Player.stamina) .. "x", love.graphics.getWidth() - 60, 20)
    love.graphics.print(math.floor(Player.score), 20, 20)
    love.graphics.print(love.timer.getFPS() .. "FPS", love.graphics.getWidth() - 120, height - 50)

    -- grey overlay when paused
    if not isRunning then
        love.graphics.setColor(128, 128, 128, 128)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Game Over! Score: " .. math.floor(Player.score), 0, height / 2, width, "center")
    end
end

function love.resize(width, height)
    local previousHeight = Ground.height
    Ground.width = width / Settings.scale
    Ground.height = height * Settings.groundPercentage / Settings.scale

    local distanceY = Ground.height - (previousHeight or Ground.height)
    Ground.y = height / Settings.scale - Ground.height

    if distanceY == 0 or not bumpWorld then
        return
    end

    Player.y = Player.y + distanceY
    for index, obstacle in ipairs(Obstacles) do
        obstacle.y = obstacle.y + distanceY
        bumpWorld:update(obstacle, obstacle.x, obstacle.y)
    end

    bumpWorld:update(Player, Player.x, Player.y)

    bumpWorld:remove(Ground)
    bumpWorld:add(Ground, Ground.x, Ground.y, Ground.width, Ground.height)

    background:regenerate(width, height * (1 - Settings.groundPercentage) / Settings.scale, true)
end

function love.keypressed(key)
    if key == "space" then
        if not isRunning then
            resetGame()
            return
        end

        jump()
    end
    if key == "escape" then
        love.event.quit()
    end
    if key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end

function love.keyreleased(key)
    if key == "space" then
        fallFast()
    end
end

function love.mousepressed(x, y, button)
    if not isRunning then
        resetGame()
        return
    end

    jump()
end

function love.mousereleased(x, y, button)
    fallFast()
end