local Settings = require "data.Settings"

Player = {
    isPlayer = true,
    isJumping = false,
    canJump = false,
    hasLanded = true,
    score = 0,
    x = 40,
    y = 10,
    width = 32,
    height = 64,
    velocityX = 0,
    velocityY = 0,
    jumpVelocity = 250,
    gravity = 600,
    maxFallVelocity = 1400,
    health = Settings.maxPlayerHealth,
    stamina = 0,
}

Banana = {
    isEnemy = true,
    x = 500,
    y = 0,
    width = 32,
    height = 64,
    velocityX = -10,
    velocityY = 0,
    health = 3,
    stamina = 0,
}

Ground = {
    isGround = true,
    color = {247, 160, 59},
    x = 0,
    y = 0,
}

Obstacles = {
    velocityX = -120,
    spacing = 120,
    count = 2,
    pickupCount = 20,
    defaultWidth = 16,
    defaultHeight = 16,
}