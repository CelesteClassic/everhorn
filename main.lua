nuklear = require 'nuklear'
filedialog = require 'filedialog'
serpent = require 'serpent'

require 'util'
require 'room'

-- global constants (only one so far lol)
tms = 4 

-- GLOBAL VARIABLES
-- and stuff that has to do with them

ui = nil

-- UI only stuff
app = {
	camX = 0,
	camY = 0,
	camScale = 3, --based on camScaleSetting
	camScaleSetting = 2, -- 0, 1, 2 is 1x, 2x, 3x etc, -1, -2, -3 is 0.5x, 0.25x, 0.125x
	room = nil,
	suppressMouse = false, -- disables mouse-driven editing in love.update() when a click has triggered different action, reset on release
	tool = "tile",
	currentTile = 0,
	message = nil,
	messageTimeLeft = nil,
	
	-- history (undo stack)
	history = {},
	historyN = 0,
}

project = {
	rooms = {},	
	selection = nil,
}

function toScreen(x, y)
	return (app.camX + x) * app.camScale,
	       (app.camY + y) * app.camScale
end
 
function fromScreen(x, y)
	return x/app.camScale - app.camX,
	       y/app.camScale - app.camY
end

function activeRoom()
	return project.rooms[app.room]
end

function mouseOverTile()
	if app.room then
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

function pushHistory()
	local s = dumplua(project)
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
		project, err = loadlua(app.history[app.historyN])
		if err then error(err) end
	end
	
	if not activeRoom() then app.room = nil end
end

function redo()
	if app.historyN <= #app.history - 1 then
		app.historyN = app.historyN + 1
		
		local err
		project, err = loadlua(app.history[app.historyN])
		if err then error(err) end
	end
	
	if not activeRoom() then app.room = nil end
end

require 'fileio'
require 'mainloop'
require 'keyboard'
require 'mouse'
