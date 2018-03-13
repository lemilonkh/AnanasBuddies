local Gradient = class "Gradient"

function Gradient:init(colors, interpolationColorCount)
    if interpolationColorCount then
        if #colors ~= 2 then
            error("Color interpolation needs exactly two colors in the first argument of Gradient constructor!")
        end
        self.colors = self:generateColors(colors[1], colors[2], interpolationColorCount)
    else
        self.colors = colors
    end

    local direction = colors.direction or "horizontal"
    if direction == "horizontal" then
        direction = true
    elseif direction == "vertical" then
        direction = false
    else
        error("Invalid direction '" .. tostring(direction) .. "' for gradient.  Horizontal or vertical expected.")
    end

    local result = love.image.newImageData(direction and 1 or #self.colors, direction and #self.colors or 1)
    for i, color in ipairs(self.colors) do
        local x, y
        if direction then
            x, y = 0, i - 1
        else
            x, y = i - 1, 0
        end
        result:setPixel(x, y, color[1], color[2], color[3], color[4] or 255)
    end
    result = love.graphics.newImage(result)
    result:setFilter('linear', 'linear')
    self.image = result
end

function Gradient:draw(x, y, w, h, r, ox, oy, kx, ky)
    return -- tail call for a little extra bit of efficiency
    love.graphics.draw(self.image, x, y, r, w / self.image:getWidth(), h / self.image:getHeight(), ox, oy, kx, ky)
end

--- Linear interpolation from colorA to colorB, using colorCount steps/ pixels
function Gradient:generateColors(colorA, colorB, colorCount)
    local colors = {}
    local t = 0
    for i = 1, colorCount do
        colors[i] = {
            colorA[1] * t + colorB[1] * (1-t),
            colorA[2] * t + colorB[2] * (1-t),
            colorA[3] * t + colorB[3] * (1-t),
            (colorA[4] or 255) * t + (colorB[4] or 255) * (1-t)
        }
        t = t + 1 / colorCount
    end
    return colors
end

return Gradient