local Background = class "Background"

local layerCount = 4
local layerDistance = 0.1
local noiseScale = 0.03
local noiseScaleIncrease = 0.004
local minHeight, maxHeight = 0, 0.35

function Background:init(width, height)
    self.width, self.height = width, height
    self.layers = {}
end

function Background:regenerate(width, height)
    for i = 1, layerCount do
        local distance = layerDistance * i
        local color = {i * 32, 255 - i * 32, 128 - i * 32, 128 }
        local offset = (self.layers[i] and self.layers[i].offsetX) or 0
        self.layers[i] = self:makeLayer(self.layers[i], width, height, distance, color, i, offset)
    end
end

function Background:makeLayer(layer, width, height, depth, color, scale, offset)
    if not layer or not layer.canvas then
        layer = {}
        layer.canvas = love.graphics.newCanvas(width, height)
    end

    love.graphics.setCanvas(layer.canvas)
    love.graphics.clear()
    love.graphics.setColor(color)
    local scale = noiseScale + noiseScaleIncrease * scale
    for x = 0, width do
        local noise = love.math.noise(x * scale + offset, depth) *  (maxHeight - minHeight) * height + minHeight
        love.graphics.line(x, height, x, height - noise)
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