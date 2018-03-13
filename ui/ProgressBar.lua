local ProgressBar = class "ProgressBar"
local Tween = require "libs.tween"
local util = require "util.util"

local progressBarAnimationSpeed = 3

function ProgressBar:init(imageName, x, y, scale, initialValue, anchorSide, offsetLeft, offsetRight, fadeIn)
    self.positionX, self.positionY = x or 0, y or 0
    self.value = 0
    self.image = love.graphics.newImage("sprites/" .. imageName .. ".png")
    self.fillImage = love.graphics.newImage("sprites/" .. imageName .. "_fill.png")
    self.scale = scale or 1.0
    self.drawContext = "ui"
    self.anchorSide = anchorSide or "left"
    self.offsetLeft = offsetLeft or 0
    self.offsetRight = offsetRight or 0
    self.fillOffsetX = 0
    self.isAnimating = false

    if fadeIn then
        self:animateToValue(initialValue)
    else
        self:setValue(initialValue)
    end

    self.targetValue = self.value
end

function ProgressBar:setPosition(x, y)
    self.positionX, self.positionY = x or 0, y or 0
end

function ProgressBar:setScale(scale)
    self.scale = scale
end

function ProgressBar:animateToValue(targetValue, tweenFunction)
    if targetValue == self.targetValue then return end

    tweenFunction = tweenFunction or "outQuint"
    self.isAnimating = true
    self.targetValue = util.fract(targetValue)
    self.valueTween = Tween.new(progressBarAnimationSpeed, self, {value = util.fract(targetValue)}, tweenFunction)
end

-- @param [Float] value in interval [0, 1]
function ProgressBar:setValue(value, isAnimation)
    value = value or self.value
    if value < 0.0 then value = 0.0 end
    if value > 1.0 then value = 1.0 end

    self.value = value

    if not isAnimation then
        self.isAnimating = false
    end

    local width, height = self.fillImage:getDimensions()
    width = width - self.offsetLeft - self.offsetRight
    local widthOffset = 0
    if self.anchorSide == "right" then
        self.fillOffsetX = math.floor(width * (1.0 - value)) + self.offsetLeft
        widthOffset = self.offsetRight
    else
        widthOffset = self.offsetLeft
    end
    local quadWidth = math.floor(width * util.fract(value)) + widthOffset
    self.quad = love.graphics.newQuad(self.fillOffsetX, 0, quadWidth, height, self.fillImage:getDimensions())
end

function ProgressBar:update(dt)
    if not self.isAnimating then return false end

    local previousValue = self.value
    local isFinished = self.valueTween:update(dt)
    if isFinished then self.isAnimating = false end

    if previousValue ~= self.value then
        self:setValue(self.value, true)
    end
end

function ProgressBar:draw()
    local positionX, positionY = self.positionX, self.positionY
    if self.anchorSide == "right" then
        positionX = love.graphics.getWidth() - self.scale * self.image:getWidth() - positionX
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.fillImage, self.quad, positionX + self.fillOffsetX, positionY, 0, self.scale)
    love.graphics.draw(self.image, positionX, positionY, 0, self.scale)
end

return ProgressBar