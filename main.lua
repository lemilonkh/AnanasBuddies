-- main.lua
-- (c) 2018 by Milan Gruner

class = require "libs.30log"
inspect = require "libs.inspect"
local bump = require "libs.bump"
local anim8 = require "libs.anim8"

local ProgressBar = require "ui.ProgressBar"
local Background = require "fx.Background"
local SoundManager = require "util.SoundManager"

local isRunning = true

local Settings = {
    scale = 2,
    groundY = 300,
    backgroundColor = {28, 112, 167},
    backgroundSpeed = 4,
    scoreMultiplier = 1, -- points per second
}

local Player = {
    isPlayer = true,
    isJumping = false,
    canJump = false,
    hasLanded = true,
    score = 0,
    x = 40,
    y = 0,
    width = 32,
    height = 64,
    velocityX = 0,
    velocityY = 0,
    jumpVelocity = 250,
    gravity = 600,
    maxFallVelocity = 1400,
    health = 3,
}

local Ground = {
    isGround = true,
    color = {247, 160, 59},
    x = 0,
    y = 0
}

local Obstacles = {
    velocityX = -120,
    spacing = 120,
    count = 2,
    defaultWidth = 16,
    defaultHeight = 16,
}

local staminaBar, background, soundManager

local function getScreenSize(unscaled)
    if unscaled then return love.graphics.getWidth(), love.graphics.getHeight() end
    return love.graphics.getWidth() / Settings.scale, love.graphics.getHeight() / Settings.scale
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    love.resize(love.graphics.getDimensions())

    soundManager = SoundManager()

    Player.sprite = love.graphics.newImage("sprites/ananas.png")
    local spriteWidth, spriteHeight = Player.sprite:getWidth(), Player.sprite:getHeight()
    local grid = anim8.newGrid(Player.width, Player.height, spriteWidth, spriteHeight)
    Player.animation = anim8.newAnimation(grid('1-7', 1), 0.1, "pauseAtEnd")

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
            x = x, y = y, width = width, height = height, quad = quad, isObstacle = true
        }
        bumpWorld:add(obstacle, x, y, width, height)
        table.insert(Obstacles, obstacle)
    end

    staminaBar = ProgressBar("staminabar", 10, 10, 1, 0.5, "right", 24, 7, true)
    local width, height = getScreenSize()
    background = Background(width, height / 2)
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

local function gameOver()
    soundManager:play("explosion", "random")
    isRunning = false
    Player.health = 3
    print("Game over! Score: " .. math.floor(Player.score))
end

local function takeHit()
    soundManager:play("hit", "random")
    Player.health = Player.health - 1
    resetWorld() -- TODO remove obstacle and slow down time instead later
    if Player.health <= 0 then
        gameOver()
    end
end

function love.update(dt)
    if not isRunning then return end

    for i = 1, #Obstacles do
        local obstacle = Obstacles[i]
        obstacle.x = obstacle.x + Obstacles.velocityX * dt

        if obstacle.x < -obstacle.width then
            obstacle.x = love.graphics.getWidth() / Settings.scale + obstacle.width
            bumpWorld:update(obstacle, obstacle.x, obstacle.y)
        end

        local actualX, actualY, collisions = bumpWorld:move(obstacle, obstacle.x, obstacle.y)
        obstacle.x, obstacle.y = actualX, actualY

        for i = 1, #collisions do
            if collisions[i].other.isPlayer then
                takeHit()
            end
        end
    end

    Player.animation:update(dt)
    if Player.isJumping then
        Player.animation:pauseAtStart()
    else
        Player.animation:resume()
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
            takeHit()
        end
    end

    Player.score = Player.score + dt * Settings.scoreMultiplier
    staminaBar:update(dt)
    background:update(dt, Settings.backgroundSpeed)
end

function love.draw()
    love.graphics.setBackgroundColor(Settings.backgroundColor)
    love.graphics.setColor(255, 255, 255)

    background:draw(Settings.scale)

    love.graphics.push()
    love.graphics.scale(Settings.scale)

    for index, obstacle in ipairs(Obstacles) do
        love.graphics.draw(Obstacles.sprite, obstacle.quad, obstacle.x, obstacle.y)
        love.graphics.rectangle("line", obstacle.x, obstacle.y, obstacle.width, obstacle.height)
    end

    Player.animation:draw(Player.sprite, Player.x, Player.y)

    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("line", Player.x, Player.y, Player.width, Player.height)

    love.graphics.setColor(Ground.color)
    love.graphics.rectangle("fill", Ground.x, Ground.y, Ground.width, Ground.height)

    -- UI
    love.graphics.pop()
    staminaBar:draw()
    for i = 0, Player.health - 1 do
        love.graphics.draw(Player.sprite, Player.healthQuad, i * (Player.width + 10) + 10, 10)
    end

    love.graphics.print("Score: " .. math.floor(Player.score), 10, 10)
    love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 55, 10)

    -- grey overlay when paused
    if not isRunning then
        local width, height = getScreenSize(true)
        love.graphics.setColor(128, 128, 128, 128)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Game Over! Score: " .. math.floor(Player.score), 0, height / 2, width, "center")
    end
end

function love.resize(width, height)
    Ground.width = width / Settings.scale
    Ground.height = height / (2 * Settings.scale)

    local distanceY = Ground.height - Ground.y
    Ground.y = Ground.height

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

    background:regenerate(width, height / 4, true)
end

function love.keypressed(key)
    if key == "space" then
        if not isRunning then
            isRunning = true
            resetWorld()
            Player.score = 0
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
        isRunning = true
        resetWorld()
        Player.score = 0
        return
    end

    jump()
end

function love.mousereleased(x, y, button)
    fallFast()
end