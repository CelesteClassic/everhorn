nuklear = require 'nuklear'
filedialog = require 'filedialog'
serpent = require 'serpent'

require 'util'
require 'room'
require 'autotiles'



-- global constants
global_scale=2 -- global scale, to run nicely on hi dpi displays
tms = 4*global_scale -- tile menu scale
psep = love.system.getOS() == "Windows" and "\\" or "/" -- path separator



-- GLOBAL VARIABLES (im dirty like that)
-- and stuff that has to do with them

function newProject()
    -- this is UI things
		love.graphics.setNewFont(12*global_scale)
    app = {
        camX = 0,
        camY = 0,
        camScale = 2, --based on camScaleSetting
        camScaleSetting = 1, -- 0, 1, 2 is 1x, 2x, 3x etc, -1, -2, -3 is 0.5x, 0.25x, 0.125x
        room = nil,
        suppressMouse = false, -- disables mouse-driven editing in love.update() when a click has triggered different action, reset on release
        tool = "brush",
        currentTile = 0,
        message = nil,
        messageTimeLeft = nil,
        playtesting = false,
        showToolPanel = true,
		showGarbageTiles=false,
        
        -- history (undo stack)
        history = {},
        historyN = 0,
        
        font = love.graphics.getFont(),
        
        left = 0, top = 0, -- top left corner of editing area
        
        -- these are used in various hacks to work around nuklear being big dumb (or me idk)
        anyWindowHovered = false,
        enterPressed = false,
        roomAdded = false,
        
    }
		--ui:styleSetFont(love.graphics.getFont())
		ui:stylePush({['font']=app.font})
		--print(app.font:getHeight())
    -- this is what goes into history and (mostly) gets saved
    project = {
        rooms = {}, 
        selection = nil,
    }
    
    -- basic p8data with blank spritesheet
    local data = {}
    local imgdata = love.image.newImageData(128, 64)
    imgdata:mapPixel(function() return 0, 0, 0, 1 end)
    data.spritesheet = love.graphics.newImage(imgdata)
    data.quads = {}
    for i = 0, 15 do
        for j = 0, 15 do
            data.quads[i + j*16] = love.graphics.newQuad(i*8, j*8, 8, 8, data.spritesheet:getDimensions())
        end
    end
    
    p8data = data
end

function toScreen(x, y)
    return (app.camX + x) * app.camScale + app.left,
           (app.camY + y) * app.camScale + app.top
end
 
function fromScreen(x, y)
    return (x - app.left)/app.camScale - app.camX,
           (y - app.top)/app.camScale - app.camY
end

function activeRoom()
    return app.room and project.rooms[app.room]
end

function mouseOverTile()
    if activeRoom() then
        local x, y = love.mouse.getPosition()
        local mx, my = fromScreen(x, y)
        local ti, tj = div8(mx - activeRoom().x), div8(my - activeRoom().y)
        if ti >= 0 and ti < activeRoom().w and tj >= 0 and tj < activeRoom().h then
            return ti, tj
        end
    end
end

function showMessage(msg)
    app.message = msg
    app.messageTimeLeft = 4
end

function placeSelection()
    if project.selection and app.room then
        local sel, room = project.selection, activeRoom()
        local i0, j0 = div8(sel.x - room.x), div8(sel.y - room.y)
        for i = 0, sel.w - 1 do
            if i0 + i >= 0 and i0 + i < room.w then
                for j = 0, sel.h - 1 do
                    if j0 + j >= 0 and j0 + j < room.h then
                        room.data[i0 + i][j0 + j] = sel.data[i][j]
                    end
                end
            end
        end
    end
    project.selection = nil
end

function select(i1, j1, i2, j2)
    local i0, j0, w, h = rectCont2Tiles(i1, j1, i2, j2)
    if w > 1 or h > 1 then
        local r = activeRoom()
        local selection = newRoom(r.x + i0*8, r.y + j0*8, w, h)
        for i = 0, w - 1 do
            for j = 0, h - 1 do
                selection.data[i][j] = r.data[i0 + i][j0 + j]
                r.data[i0 + i][j0 + j] = 0
            end
        end
        project.selection = selection
    end
end

function pushHistory()
    local s = dumpproject(project)
    if s ~= app.history[app.historyN] then
        --print("BEFORE: "..tostring(app.history[app.historyN]))
        --print("AFTER: "..s)
        app.historyN = app.historyN + 1
    
        for i = app.historyN, #app.history do
            app.history[i] = nil
        end
        
        app.history[app.historyN] = s
    end
end

function undo()
    if app.historyN >= 2 then
        app.historyN = app.historyN - 1
        
        local err
        project, err = loadproject(app.history[app.historyN])
        if err then error(err) end
    end
    
    if not activeRoom() then app.room = nil end
end

function redo()
    if app.historyN <= #app.history - 1 then
        app.historyN = app.historyN + 1
        
        local err
        project, err = loadproject(app.history[app.historyN])
        if err then error(err) end
    end
    
    if not activeRoom() then app.room = nil end
end



require 'fileio'
require 'mainloop'
require 'keyboard'
require 'mouse'
