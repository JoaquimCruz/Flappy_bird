local SCREEN_WIDTH = 240
local SCREEN_HEIGHT = 136
local bird_x = 50
local bird_y = SCREEN_HEIGHT / 2
local flapT = 0
local flap_speed = 0.02
local map_scroll_speed = 0.5
local offset_x = 0
local map_width = 30
local ground_height = 16

local pipes = {}
local pipe_gap = 30
local pipe_speed = 1
local spawn_timer = 0
local spawn_interval = 75
local bird_velocity = 0
local gravity = 0.08
local jump_strength = -2.0

local score = 0
local high_score = 0
local game_over = false


function updateScore()
    for _, pipe in ipairs(pipes) do
        if bird_x > pipe.top.x + 32 and not pipe.scored then

            score = score + 1
            pipe.scored = true
  
        end
    end
end

function drawPipes()
    for _, pipe in ipairs(pipes) do
        for i = 0, pipe.top.h - 8, 8 do
            spr(44, pipe.top.x, i, 0, 1, 0, 0, 2, 1)
        end
        spr(12, pipe.top.x, pipe.top.h - 8, 0, 1, 0, 0, 2, 1)

        for i = 0, pipe.bottom.h - 8, 8 do
            spr(44, pipe.bottom.x, 150 - pipe.bottom.h + i, 0, 1, 0, 0, 2, 1)
        end
        spr(28, pipe.bottom.x, 150 - pipe.bottom.h, 0, 1, 0, 0, 2, 1)
    end
end

function spawnPipe()
    local pipe_x = SCREEN_WIDTH
    local min_height = 20
    local max_height = 136 - pipe_gap - min_height
    local offset = -8

    local top_height = math.random(min_height, max_height) + offset
    if top_height < min_height then top_height = min_height end

    local bottom_height = 136 - top_height - pipe_gap
    if bottom_height < min_height then
        bottom_height = min_height
        top_height = 136 - bottom_height - pipe_gap
    end

    local pipe = {
        top = {x = pipe_x, y = 0, h = top_height},
        bottom = {x = pipe_x, y = SCREEN_HEIGHT - bottom_height, h = bottom_height},
        scored = false
    }
    table.insert(pipes, pipe)
end

function updatePipes()
    for i = #pipes, 1, -1 do
        local pipe = pipes[i]
        pipe.top.x = pipe.top.x - pipe_speed
        pipe.bottom.x = pipe.bottom.x - pipe_speed

        if pipe.top.x + 32 < 0 then
            table.remove(pipes, i)
        end
    end

    spawn_timer = spawn_timer + 1
    if spawn_timer >= spawn_interval then
        spawnPipe()
        spawn_timer = 0
    end
end

function updateDifficulty()
    if score % 10 == 0 and score > 0 then 
        pipe_speed = pipe_speed + 0.005
        if pipe_gap > 20 then 
            pipe_gap = pipe_gap - 1
        end
    end
end

local game_started = false

function drawStartScreen()
    print("High Score: " .. high_score, SCREEN_WIDTH / 2 - 30, SCREEN_HEIGHT / 2 + 30, 0)
    print("PRESS Z TO START", SCREEN_WIDTH / 2 - 40, SCREEN_HEIGHT / 2, 0)
end

function saveHighScore()
    dset(0, high_score) -- Salva o recorde no índice 0
end

function loadHighScore()
    high_score = dget(0) or 0 -- Carrega o recorde; se não houver, define como 0
end

function reset_game()
    if score > high_score then
        high_score = score
    end
    bird_y = SCREEN_HEIGHT / 2
    bird_velocity = 0
    pipe_speed = 1
    pipes = {}
    game_over = false
    score = 0
    spawn_timer = 0
end

function TIC()
    if not game_started then
        if btnp(4) then
            game_started = true
            
        end
        drawStartScreen()
        return
    end
    
    if not game_over then
        bird_velocity = bird_velocity + gravity
        bird_y = bird_y + bird_velocity

        updatePipes()
        updateScore()

        for _, pipe in ipairs(pipes) do
            if bird_x + 16 > pipe.top.x and bird_x < pipe.top.x + 16 then
                if bird_y < pipe.top.h or bird_y > SCREEN_HEIGHT - pipe.bottom.h then
                    game_over = true
                end
            end
        end

        if bird_y > SCREEN_HEIGHT - ground_height or bird_y < 0 then
            game_over = true
        end

        if btnp(4) then
            bird_velocity = jump_strength
            sfx(0) -- Som de pulo
        end
    else
        if btnp(4) then
            reset_game()
        end
    end

    flapT = (flapT + flap_speed) % 1
    local flap_offset = math.sin(flapT * math.pi * 2) * 2
    offset_x = (offset_x + map_scroll_speed) % (map_width * 8)

    cls(10)
    map(0, 0, 240 / 8 + 1, 136 / 8 + 1, -offset_x, 0)
    map(0, 0, 240 / 8 + 1, 136 / 8 + 1, -offset_x + map_width * 8, 0)

    drawPipes()

    local bird_sprite_left = 257 - math.floor(math.cos(flapT * math.pi * 2))
    local bird_sprite_right = 259
    spr(bird_sprite_left, bird_x, bird_y + flap_offset, 4, 1, 0, 0, 1, 2)
    spr(bird_sprite_right, bird_x + 8, bird_y + flap_offset, 4, 1, 0, 0, 1, 2)

    updateDifficulty()
    print("Score: " .. score, 5, 5, 3)

    if game_over then
        print("WASTED", SCREEN_WIDTH / 2 - 20, SCREEN_HEIGHT / 2 - 10, 3)
        print("Press Z to Restart", SCREEN_WIDTH / 2 - 50, SCREEN_HEIGHT / 2 + 7, 3)
         
        if score > high_score then
            print("New High Score: " .. score, SCREEN_WIDTH / 2 - 45, SCREEN_HEIGHT / 2 - 30, 3)
        else
        			print("High Score: " .. high_score, SCREEN_WIDTH / 2 - 40, SCREEN_HEIGHT / 2 - 30, 3)
        end
    end
end

