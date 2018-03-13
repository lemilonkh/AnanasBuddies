-- main.lua
-- (c) 2018 by Milan Gruner

inspect = require "libs.inspect"
local bump = require "libs.bump"
local anim8 = require "libs.anim8"

local isRunning = true

local Settings = {
    scale = 4,
    groundY = 300,
    backgroundColor = {28, 112, 167}
}

local Player = {
    isPlayer = true,
    isJumping = false,
    canJump = false,
    score = 0,
    x = 40,
    y = 0,
    width = 16,
    height = 32,
    velocityX = 0,
    velocityY = 0,
    jumpVelocity = 200,
    gravity = 400,
    maxFallVelocity = 1200
}

local Ground = {
    isGround = true,
    color = {247, 160, 59},
    x = 0,
    y = 0
}

local Obstacles = {
    velocityX = -40,
    spacing = 60,
    count = 2,
    defaultWidth = 16,
    defaultHeight = 16,
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    Ground.width = love.graphics.getWidth()  / Settings.scale
    Ground.height = love.graphics.getHeight() / (2 * Settings.scale)
    Ground.y = Ground.height

    Player.sprite = love.graphics.newImage("sprites/pineapple.png")
    local grid = anim8.newGrid(Player.width, Player.height, Player.sprite:getWidth(), Player.sprite:getHeight())
    Player.animation = anim8.newAnimation(grid('1-7', 1), 0.1)

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
end

local function gameOver()
    isRunning = false
    print("Game over!")
end

function love.update(dt)
    if not isRunning then return end

    for i = 1, #Obstacles do
        local obstacle = Obstacles[i]
        obstacle.x = obstacle.x + Obstacles.velocityX * dt

        if obstacle.x < -obstacle.width then
            obstacle.x = love.graphics.getWidth() / Settings.scale + obstacle.width
        end

        local actualX, actualY, collisions = bumpWorld:move(obstacle, obstacle.x, obstacle.y)
        obstacle.x, obstacle.y = actualX, actualY

        for i = 1, #collisions do
            if collisions[i].other.isPlayer then
                gameOver()
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
            Player.canJump = true
            Player.isJumping = false
            Player.velocityY = 0
        elseif collision.other.isObstacle then
            gameOver()
        end
    end
end

local function getScreenSize()
    return love.graphics.getWidth() / Settings.scale, love.graphics.getHeight() / Settings.scale
end

function love.draw()
    love.graphics.setBackgroundColor(Settings.backgroundColor)
    love.graphics.setColor(255, 255, 255)

    love.graphics.print("Score: " .. Player.score, 10, 10)
    love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 55, 10)

    love.graphics.scale(Settings.scale)

    for index, obstacle in ipairs(Obstacles) do
        love.graphics.draw(Obstacles.sprite, obstacle.quad, obstacle.x, obstacle.y)
    end

    Player.animation:draw(Player.sprite, Player.x, Player.y)

    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("line", Player.x, Player.y, Player.width, Player.height)

    love.graphics.setColor(Ground.color)
    love.graphics.rectangle("fill", Ground.x, Ground.y, Ground.width, Ground.height)

    -- grey overlay when paused
    if not isRunning then
        love.graphics.setColor(128, 128, 128, 128)
        love.graphics.rectangle("fill", 0, 0, getScreenSize())
    end
end

function love.keypressed(key)
    if key == " " then
        Player.velocityY = -Player.jumpVelocity
    end
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    if Player.canJump then
        Player.isJumping = true
        Player.canJump = false
        Player.velocityY = -Player.jumpVelocity
    end
end

function love.mousereleased(x, y, button)
    if Player.isJumping then
        Player.isJumping = false
        Player.velocityY = Player.velocityY + Player.jumpVelocity
    end
end