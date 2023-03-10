--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = {
        [1] = params.ball
    }
    self.level = params.level
    self.powerUp = params.powerUp

    -- give ball random starting velocity
    
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end

    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.paddle.size = changePaddleSize(self.score, self.health)
    
    -- updating balls
    for key, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
            paddleCollision(ball, self.paddle)
        end

        if ball.dx == 0 and ball.dy == 0 then
            ball:giveVelocity()
    end


    if self.powerUp.ability == 1 and not self.powerUp.inPlay then
        self.powerUp = PowerUp(2)
    end

    if self.powerUp.ability == 2 and not self.powerUp.inPlay then
        for key, brick in pairs(self.bricks) do
            brick.isLocked = false
        end
    end


    for key, ball in pairs(self.balls) do
        if ball:collides(self.powerUp) and self.powerUp.inPlay then
            brickCollision(ball, self.powerUp)
            self.powerUp:hit()
            self.powerUp.inPlay = false
            
            if self.powerUp.ability == 1 then
                self.balls =  {
                    [1] = ball,
                    [2] = Ball(math.random(3)),
                    [3] = Ball(math.random(3))
                }

                for key, ball in pairs(self.balls) do 
                    ball.x = self.powerUp.x + key * 3
                    ball.y = self.powerUp.y + key * 3
                end

            end
        break
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        ball = isBrickCollision(brick, self.balls)
        if brick.inPlay and ball ~= nil then
            -- change velocity

            brickCollision(ball, brick)
            -- add to score
            if not brick.isLocked then
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
            end

            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = ball
                })
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(ball.dy) < 150 then
                ball.dy = ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
end

    -- if ball goes below bounds, revert to serve state and decrease health
    for key, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            gSounds['hurt']:play()
            
            
            -- checking if we still have balls left
            if #self.balls == 1 then
                self.health = self.health - 1
            else
                table.remove(self.balls, key)
                break
            end

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
                
            else
                gStateMachine:change('serve', {
                    paddle = self.paddle,
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    powerUp = self.powerUp
                })
                
            end
        end
    end
    

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end


end

function PlayState:render()
    -- render powerUp after 10 seconds
    self.powerUp:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for key, ball in pairs(self.balls) do 
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end


function paddleCollision(ball, paddle)
    ball.y = paddle.y - 8
    ball.dy = -ball.dy

    --
    -- tweak angle of bounce based on where it hits the paddle
    --

    -- if we hit the paddle on its left side while moving left...
    if ball.x < paddle.x + (paddle.width / 2) and paddle.dx < 0 then
        ball.dx = -50 + -(8 * (paddle.x + paddle.width / 2 - ball.x))
    
    -- else if we hit the paddle on its right side while moving right...
    elseif ball.x > paddle.x + (paddle.width / 2) and paddle.dx > 0 then
        ball.dx = 50 + (8 * math.abs(paddle.x + paddle.width / 2 - ball.x))
    end

    gSounds['paddle-hit']:play()
end

function isBrickCollision(brick, balls)
    for key, ball in pairs(balls) do

        if ball:collides(brick) then
            return ball
        end
        
    end

    return nil
end

function brickCollision(ball, brick)
    if ball.x + 2 < brick.x and ball.dx > 0 then
                
        -- flip x velocity and reset position outside of brick
        ball.dx = -ball.dx
        ball.x = brick.x - 8
    
    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
    -- so that flush corner hits register as Y flips, not X flips
    elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
        
        -- flip x velocity and reset position outside of brick
        ball.dx = -ball.dx
        ball.x = brick.x + 32
    
    -- top edge if no X collisions, always check
    elseif ball.y < brick.y then
        
        -- flip y velocity and reset position outside of brick
        ball.dy = -ball.dy
        ball.y = brick.y - 8
    
    -- bottom edge if no X collisions or top collision, last possibility
    else
        
        -- flip y velocity and reset position outside of brick
        ball.dy = -ball.dy
        ball.y = brick.y + 16
    end

    -- slightly scale the y velocity to speed up the game, capping at +- 150
    if math.abs(ball.dy) < 150 then
        ball.dy = ball.dy * 1.02
    end
end

function changePaddleSize(score, health)
    size = 4 - math.floor(score / 2000)
    size = math.min(4, math.max(1, size) + (3 - health))
    return size

end