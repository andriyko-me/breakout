paletteColors = {
    -- blue
    [1] = {
        ['r'] = 99,
        ['g'] = 155,
        ['b'] = 255
    },
    -- green
    [2] = {
        ['r'] = 106,
        ['g'] = 190,
        ['b'] = 47
    },
    -- red
    [3] = {
        ['r'] = 217,
        ['g'] = 87,
        ['b'] = 99
    },
    -- purple
    [4] = {
        ['r'] = 215,
        ['g'] = 123,
        ['b'] = 186
    },
    -- gold
    [5] = {
        ['r'] = 251,
        ['g'] = 242,
        ['b'] = 54
    }
}

PowerUp = Class{}

function PowerUp:init()
    self.powerUp = math.random(2)
    self.x = math.random(16, VIRTUAL_WIDTH - 16)
    self.y = math.random (VIRTUAL_HEIGHT / 2, 2 * VIRTUAL_HEIGHT / 3)
    self.width = 16
    self.height = 16
    self.inPlay = true
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)


    self.psystem:setParticleLifetime(0.5, 1)
    self.psystem:setLinearAcceleration(-15, 0, 15, 80)
    self.psystem:setEmissionArea('normal', 10, 10)
end

function PowerUp:render()
    if self.inPlay then
        love.graphics.draw(gTextures['main'], gFrames['powerUps'][self.powerUp], self.x, self.y)
    end
end

function PowerUp:hit()
    self.psystem:setColors(251/255, 242/255, 54/255, 100)
    self.psystem:emit(64)
    self.inPlay = false
    
    -- sound on hit
    gSounds['brick-hit-2']:stop()
    gSounds['brick-hit-2']:play()
    
end

