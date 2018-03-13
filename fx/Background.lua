local Background = class "Background"
local Gradient = require "fx.Gradient"

local layerCount = 4
local layerDistance = 0.1
local noiseScale = 0.01
local noiseScaleIncrease = 0.004
local highFreqNoiseFactor = 0.2
local minHeight, maxHeight = 0.1, 0.16
local minHeightIncrease, maxHeightIncrease = 0.04, 0.08
local colors = {
    {93, 164, 88},
    {86, 128, 62},
    {255, 255, 255}, -- 46, 84, 42
    {36, 71, 57},

--    {71, 137, 66},
--    {68, 128, 62},
--    {54, 102, 50}
}

function Background:init(width, height)
    self.width, self.height = width, height
    self.layers = {}
end

function Background:regenerate(width, height, changeSize)
    if changeSize then
        self.layers = {}
        self.width, self.height = width, height
    end

    for i = 1, layerCount do
        local index = layerCount - i + 1
        local distance = layerDistance * i + i
        local color = Gradient:lerpColors(colors[1], colors[2], (i-1) * 1/layerCount)
        local secondColor = Gradient:lerpColors(colors[3], colors[4], (i-1) * 1/layerCount)
        local offset = (self.layers[i] and self.layers[i].offsetX) or 0
        local currentMinHeight, currentMaxHeight = minHeight + minHeightIncrease * i, maxHeight + maxHeightIncrease * i
        self.layers[index] = self:makeLayer(self.layers[index], width, height, distance, color, secondColor, i, offset, currentMinHeight, currentMaxHeight)
    end
end

function Background:makeLayer(layer, width, height, depth, bottomColor, topColor, scale, offset, minHeight, maxHeight)
    if not layer or not layer.canvas then
        layer = {}
        layer.canvas = love.graphics.newCanvas(width, height)
    end

    love.graphics.setCanvas(layer.canvas)
    love.graphics.clear()
    love.graphics.setColor(255, 255, 255)
    local gradient = Gradient({bottomColor, topColor}, height)
    local scale = noiseScale + noiseScaleIncrease * scale
    for x = 0, width do
        local lowFreqNoiseValue = love.math.noise(x * scale + offset, depth)
        local highFreqNoiseValue = love.math.noise(x * scale + offset, depth * scale)
        local noiseValue = lowFreqNoiseValue * (1 - highFreqNoiseFactor) + highFreqNoiseValue * highFreqNoiseFactor

        local noiseHeight = noiseValue * (maxHeight - minHeight) * height + minHeight
        local minY = height - noiseHeight - minHeight * height

        if height - minY > 0 then
            gradient:draw(x, minY, 1, math.floor(height - minY))
        end
    end
    love.graphics.setCanvas()
    layer.depth = depth
    layer.offsetX = offset
    return layer
end

function Background:draw(scale)
    for _, layer in ipairs(self.layers) do
        love.graphics.draw(layer.canvas, 0, 0, 0, scale, scale)
    end
end

function Background:update(dt, movementSpeed)
    for _, layer in ipairs(self.layers) do
        layer.offsetX = layer.offsetX + movementSpeed * dt
    end
    self:regenerate(self.width, self.height)
end

return Background