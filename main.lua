-- main.lua
-- (c) 2018 by Milan Gruner

local bump = require "libs.bump"

local groundY = 300

local Player = {
    isJumping = false,
    x = 0,
    y = 0,
    width = 16,
    height = 32,
    velocityX = 10,
    velocityY = 0,
    jumpVelocity = 10,
    gravity = 10
}

function love.init()
    --Player.sprite = love.graphics.loadImage("sprites/ananas.png")
end

function love.update(dt)
    Player.velocityY = Player.velocityY + Player.gravity * dt

    if Player.velocityY > Player.gravity then
        Player.velocityY = Player.gravity
    end

    Player.x = Player.x + Player.velocityX * dt
    Player.y = Player.y + Player.velocityY * dt
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
    Player.velocityY = -Player.jumpVelocity
end

function love.mousereleased(x, y, button)
    Player.velocityY = Player.velocityY + Player.jumpVelocity
end