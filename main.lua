-- main.lua
-- (c) 2018 by Milan Gruner

local bump = require "libs.bump"
local anim8 = require "libs.anim8"

local Settings = {
    scale = 4,
    groundY = 300
}

local Player = {
    isJumping = false,
    canJump = false,
    x = 20,
    y = 0,
    width = 16,
    height = 32,
    velocityX = 0,
    velocityY = 0,
    jumpVelocity = 200,
    gravity = 200,
    maxFallVelocity = 800
}

local Ground = {
    isGround = true,
    color = {247, 160, 59},
    x = 0,
    y = 0
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    Player.sprite = love.graphics.newImage("sprites/pineapple.png")
    local grid = anim8.newGrid(Player.width, Player.height, Player.sprite:getWidth(), Player.sprite:getHeight())
    Player.animation = anim8.newAnimation(grid('1-7', 1), 0.1)

    Ground.width = love.graphics.getWidth()  / Settings.scale
    Ground.height = love.graphics.getHeight() / (2 * Settings.scale)
    Ground.y = Ground.height

    bumpWorld = bump.newWorld()
    bumpWorld:add(Player, Player.x, Player.y, Player.width, Player.height)
    bumpWorld:add(Ground, Ground.x, Ground.y, Ground.height, Ground.width)
end

function love.update(dt)
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
        end
    end
end

function love.draw()
    love.graphics.scale(Settings.scale)
    love.graphics.setColor(255, 255, 255)
    Player.animation:draw(Player.sprite, Player.x, Player.y)
    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("line", Player.x, Player.y, Player.width, Player.height)
    love.graphics.setColor(Ground.color)
    love.graphics.rectangle("fill", Ground.x, Ground.y, Ground.width, Ground.height)
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