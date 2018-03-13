local Background = class "Background"

local layerCount = 4
local layerDistance = 0.1
local noiseScale = 0.03
local noiseScaleIncrease = 0.004
local minHeight, maxHeight = 0, 0.35

function Background:init(width, height)
    self.layers = {}
    for i = 1, layerCount do
        local distance = layerDistance * i
        local color = {i * 32, 255 - i * 32, 128 - i * 32, 128}
        self.layers[i] = self:makeLayer(width, height, distance, color, i)
    end
end

function Background:makeLayer(width, height, depth, color, scale)
    local layer = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(layer)
    love.graphics.setColor(color)
    local scale = noiseScale + noiseScaleIncrease * scale
    for x = 0, width do
        local noise = love.math.noise(x * scale, depth) *  (maxHeight - minHeight) * height + minHeight
        love.graphics.line(x, height, x, height - noise)
    end
    love.graphics.setCanvas()
    return layer
end

function Background:draw(scale)
    for _, layer in ipairs(self.layers) do
        love.graphics.draw(layer, 0, 0, 0, scale, scale)
    end
end

function Background:update(dt)

end

return Background