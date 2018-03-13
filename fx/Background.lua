local Background = class "Background"
local Gradient = require "fx.Gradient"

local layerCount = 5
local layerDistance = 0.1
local noiseScale = 0.03
local noiseScaleIncrease = 0.004
local minHeight, maxHeight = 0.1, 0.30
local minHeightIncrease, maxHeightIncrease = 0.04, 0.08

function Background:init(width, height)
    self.width, self.height = width, height
    self.layers = {}
end

function Background:regenerate(width, height)
    for i = 1, layerCount do
        local index = layerCount - i + 1
        local distance = layerDistance * i
        local color = {i * 32, 255 - i * 32, 128 - i * 32, 128 }
        local offset = (self.layers[i] and self.layers[i].offsetX) or 0
        local currentMinHeight, currentMaxHeight = minHeight + minHeightIncrease * i, maxHeight + maxHeightIncrease * i
        self.layers[index] = self:makeLayer(self.layers[index], width, height, distance, color, i, offset, currentMinHeight, currentMaxHeight)
    end
end

function Background:makeLayer(layer, width, height, depth, color, scale, offset, minHeight, maxHeight)
    if not layer or not layer.canvas then
        layer = {}
        layer.canvas = love.graphics.newCanvas(width, height)
    end

    love.graphics.setCanvas(layer.canvas)
    love.graphics.clear()
    love.graphics.setColor(255, 255, 255) --color)
    local secondColor = {255, 0, 0}
    local gradient = Gradient({color, secondColor}, height)
    local scale = noiseScale + noiseScaleIncrease * scale
    for x = 0, width do
        local noiseHeight = love.math.noise(x * scale + offset, depth) *  (maxHeight - minHeight) * height + minHeight
        local minY = height - noiseHeight - minHeight * height

        if height - minY > 0 then
            gradient:draw(x, minY, 1, math.floor(height - minY))
            --love.graphics.line(x, height, x, minY)
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