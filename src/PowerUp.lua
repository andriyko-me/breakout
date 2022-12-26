

PowerUp = Class{}

function PowerUp:init()
    self.powerUp = math.random(2)
    self.x = math.random(16, VIRTUAL_WIDTH - 16)
    self.y = math.random (VIRTUAL_HEIGHT / 2, VIRTUAL_HEIGHT / 3 + VIRTUAL_HEIGHT / 2)
end

function PowerUp:render()
    love.graphics.draw(gTextures['main'], gFrames['powerUps'][self.powerUp], self.x, self.y)
end
