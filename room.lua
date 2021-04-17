function newRoom(x, y, w, h)
    local room = {
        x = x or 0,
        y = y or 0,
        w = w or 16,
        h = h or 16,
        data = {},
        title = "",
    }
    room.data = fill2d0s(room.w, room.h)
    
    return room
end

function drawRoom(room, p8data, highlight)
    love.graphics.setColor(1, 1, 1)
    for i = 0, room.w - 1 do
        for j = 0, room.h - 1 do
            local n = room.data[i][j]
            if not highlight or n~=0 then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(p8data.spritesheet, p8data.quads[n], room.x + i*8, room.y + j*8)
                
                if highlight then
                    love.graphics.setColor(0, 1, 0.5, 0.5)
                    love.graphics.rectangle("fill", room.x + i*8, room.y + j*8, 8, 8)
                end
            end
        end
    end
end
