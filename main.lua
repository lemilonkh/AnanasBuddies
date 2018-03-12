-- main.lua
-- (c) 2018 by Milan Gruner

local bump = require "libs.bump"

local groundY = 300

local Player = {
    isJumping = false,
    canJump = false,
    x = 0,
    y = 0,
    width = 16,
    height = 32,
    velocityX = 50,
    velocityY = 0,
    jumpVelocity = 10,
    gravity = 50
}

local Ground = {
    isGround = true,
    x = 0,
    y = groundY
}

function love.load()
    Ground.width = love.graphics.getWidth()
    Ground.height = love.graphics.getHeight() / 2
    Ground.y = Ground.height
    --Player.sprite = love.graphics.loadImage("sprites/ananas.png")
    bumpWorld = bump.newWorld()
    bumpWorld:add(Player, Player.x, Player.y, Player.width, Player.height)
    bumpWorld:add(Ground, Ground.x, Ground.y, Ground.height, Ground.width)
end

function love.update(dt)
    Player.velocityY = Player.velocityY + Player.gravity * dt

    if Player.velocityY > Player.gravity then
        Player.velocityY = Player.gravity
    end

    local targetX = Player.x + Player.velocityX * dt
    local targetY = Player.y + Player.velocityY * dt
    local actualX, actualY, collisions = bumpWorld:move(Player, targetX, targetY)
    Player.x, Player.y = actualX, actualY

    for i = 1, #collisions do
        print("Collision")
        local collision = collisions[i]
        if collision.other.isGround then
            Player.canJump = true
            Player.isJumping = false
        end
    end
end

function love.draw()
    --love.graphics.draw(Player.sprite, Player.x, Player.y)
    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("line", Player.x, Player.y, Player.width, Player.height)
    love.graphics.setColor(0, 255, 128)
    love.graphics.rectangle("line", 0, groundY, love.graphics.getWidth(), love.graphics.getHeight() - groundY)
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