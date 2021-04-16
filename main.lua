local nuklear = require 'nuklear'
local filedialog = require 'filedialog'
require 'util'

-- tile menu scale
-- didnt know where else to put it
local tms = 4 



-- ROOMS

function newRoom(x, y, w, h)
	local room = {
		x = x or 0,
		y = y or 0,
		w = w or 16,
		h = h or 16,
		data = {},
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



-- GLOBAL VARIABLES
-- and stuff that has to do with them

local ui

-- UI only stuff
local app = {
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

local project = {
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



-- FILE READING AND WRITING

function loadpico8(filename)
	local file, err = io.open(filename)

	local data = {}
	
	data.palette = {
		{0,  0,  0,  255},
		{29, 43, 83, 255},
		{126,37, 83, 255},
		{0,  135,81, 255},
		{171,82, 54, 255},
		{95, 87, 79, 255},
		{194,195,199,255},
		{255,241,232,255},
		{255,0,  77, 255},
		{255,163,0,  255},
		{255,240,36, 255},
		{0,  231,86, 255},
		{41, 173,255,255},
		{131,118,156,255},
		{255,119,168,255},
		{255,204,170,255}
	}
	
	local sections = {}
	local cursec = nil
	for line in file:lines() do
		local sec = string.match(line, "^__(%a+)__$")
		if sec then
			cursec = sec
			sections[sec] = {}
		elseif cursec then
			table.insert(sections[cursec], line)
		end
	end
	file:close()
	
	local spritesheet_data = love.image.newImageData(128, 64)
	for j = 0, spritesheet_data:getHeight() - 1 do
		local line = sections["gfx"][j + 1]
		for i = 0, spritesheet_data:getWidth() - 1 do
			local s = string.sub(line, 1 + i, 1 + i)
			local b = tob2(s)
			local c = data.palette[b + 1]
			spritesheet_data:setPixel(i, j, c[1]/255, c[2]/255, c[3]/255, 1)
		end
	end
	
	data.spritesheet = love.graphics.newImage(spritesheet_data)
	
	data.quads = {}
	for i = 0, 15 do
		for j = 0, 15 do
			data.quads[i + j*16] = love.graphics.newQuad(i*8, j*8, 8, 8, data.spritesheet:getDimensions())
		end
	end
	
	data.map = {}
	for i = 0, 127  do
		data.map[i] = {}
		for j = 0, 31 do
			local s = string.sub(sections["map"][j + 1], 1 + 2*i, 2 + 2*i)
			data.map[i][j] = tob2(s)
		end
		for j = 32, 63 do
			local i_ = i%64
			local j_ = i <= 63 and j*2 or j*2 + 1
			local line = sections["gfx"][j_ + 1] or "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
			local s = string.sub(line, 1 + 2*i_, 2 + 2*i_)
			data.map[i][j] = tob2_swapnibbles(s)
		end
	end
	
	return data
end

function openMap(filename)
	local file = io.open(filename, "r")
	local str = file:read("*a")
	file:close()
	
	local p, err = loadlua(str)
	if not err then
		project = p
		
		app.filename = filename
		return true
	end
end

function saveMap(filename)
	local file = io.open(filename, "w")
	file:write(dumplua(project))
	file:close()
	
	app.filename = filename
	
	return true
end

function loadMapFromPico8(filename)
	local p8data = loadpico8(filename)
	
	project.rooms = {}
	for I = 0, 7 do
		for J = 0, 3 do
			local room = newRoom(I*128, J*128, 16, 16)
			for i = 0, 15 do
				for j = 0, 15 do
					room.data[i][j] = p8data.map[I*16 + i][J*16 + j]
				end
			end
			table.insert(project.rooms, room)
		end
	end
	
	return true
end

function updateCart(filename)
	local map = fill2d0s(128, 64)
	
	for _, room in ipairs(project.rooms) do
		local i0, j0 = div8(room.x), div8(room.y)
		for i = 0, room.w - 1 do
			for j = 0, room.h - 1 do
				map[i0+i][j0+j] = room.data[i][j]
			end
		end
	end
	
	local file = io.open(filename, "r")
	local out = {}
	
	local ln = 1
	local gfxstart, mapstart
	for line in file:lines() do
		if line == "__gfx__" then
			gfxstart = ln
		elseif line == "__map__" then
			mapstart = ln
		end
		
		table.insert(out, line)
		ln = ln + 1
	end
	
	for j = 0, 31 do
		local line = ""
		for i = 0, 127 do
			line = line .. bytetohex(map[i][j])
		end
		out[mapstart+j+1] = line
	end
	for j = 32, 63 do
		local line = ""
		for i = 0, 127 do
			line = line .. bytetohex_swapnibbles(map[i][j])
		end
		out[gfxstart+(j-32)*2+65] = string.sub(line, 1, 128)
		out[gfxstart+(j-32)*2+66] = string.sub(line, 129, 256)
	end
	
	-- code updates
	for k = 1, #out do
		if out[k] == "--@everhorn_levels" then
			while #out >= k+1 and out[k+1] ~= "--@end" do
				if #out >= k+1 then
					table.remove(out, k+1)
				else
					return false
				end
			end
			
			local value = {}
			for i = 1, #project.rooms do
				local room = project.rooms[i]
				value[i] = string.format("%d,%d,%d,%d,(title)", room.x/128, room.y/128, room.w/16, room.h/16)
			end
			
			table.insert(out, k+1, dumplua(value))
		end
	end
	
	file:close()
	file = io.open(filename, "w")
	file:write(table.concat(out, "\n"))
	file:close()
	
	return true
end



-- UI things

function tileButton(n)
	local x, y, w, h = ui:widgetBounds()
	ui:image({p8data.spritesheet, p8data.quads[n]})
	if ui:inputIsHovered(x, y, w, h) then
		app.currentTile = n
		
		love.graphics.setLineWidth(1)
		love.graphics.setColor(0, 1, 0.5)
		x, y = x - 0.5, y - 0.5
		w, h = w + 1, h + 1
		ui:line(x, y, x + w, y)
		ui:line(x, y, x, y + h)
		ui:line(x + w, y, x + w, y + h)
		ui:line(x, y + h, x + w, y + h)
	end
end

function toolLabel(label, tool)
	local hov = ui:widgetIsHovered()
	local x, y, w, h = ui:widgetBounds()
	
	local color = "#afafaf"
	if tool == app.tool then
		color = "#ffffff"
	end
	
	if hov then
		local bg = "#afafaf"
		ui:rectMultiColor(x, y, w + 4, h, bg, bg, bg, bg)
		color = "#2d2d2d"
		ui:stylePush {
			window = {
				background = bg,
			}
		}
		
		app.tool = tool
	end
	
	ui:label(label, "left", color)
	
	if hov then ui:stylePop() end
end

function closeToolMenu()
	app.toolMenuX, app.toolMenuY = nil, nil
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



-- MAIN LOOP

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.keyboard.setKeyRepeat(true)

	ui = nuklear.newUI()
	
	p8data = loadpico8(love.filesystem.getSource().."\\celeste.p8")
	
	pushHistory()
end

function love.update(dt)
	ui:frameBegin()
	
	if app.toolMenuX then
		ui:stylePush {
			window = {
				spacing = {x = 1, y = 1},
				padding = {x = 1, y = 1},
			},
		}
		
		if ui:windowBegin("Tool Panel", app.toolMenuX - 80, app.toolMenuY, 80, 8*8*tms + 10) then
			-- hacky ass shit
			-- nuklear wasnt made for this apparently
			if ui:windowIsHovered() then
				ui:windowSetFocus("Tool Panel")
			end
			
			ui:layoutRow("dynamic", 25, 1)
			toolLabel("Tileset", "tile")
			toolLabel("Selection", "select")
		end
		ui:windowEnd()
		
		if app.tool == "tile" then
			if ui:windowBegin("Tileset", app.toolMenuX, app.toolMenuY, 16*8*tms + 18, 8*8*tms + 10) then
				for j = 0, 7 do
					ui:layoutRow("static", 8*tms, 8*tms, 16)
					for i = 0, 15 do
						tileButton(i+j*16)
					end
				end
			end
			ui:windowEnd()
		end
		
		ui:stylePop()
		
	end
	
	ui:frameEnd()

	if not app.suppressMouse and not love.keyboard.isDown("lalt") and (love.mouse.isDown(1) or love.mouse.isDown(2)) then
		if app.tool == "tile" then
			local n = app.currentTile
			if love.mouse.isDown(2) then
				n = 0
			end
			local ti, tj = mouseOverTile()
			if ti then
				activeRoom().data[ti][tj] = n
			end
		end
	end
	
	local x, y = love.mouse.getPosition()
	local mx, my = fromScreen(x, y)
	
	if app.roomResizeSideX and app.room then
		local room = activeRoom()
		
		local left, top = room.x, room.y
		local right, bottom = left + room.w*8, top + room.h*8
		
		local ax = app.roomResizeSideX > 0 and right or left
		local ay = app.roomResizeSideY > 0 and bottom or top
		
		local dx = div8(math.abs(mx-ax)) * sign(mx-ax) * app.roomResizeSideX
		local dy = div8(math.abs(my-ay)) * sign(my-ay) * app.roomResizeSideY
		
		if dx ~= 0 or dy ~= 0 then
			local newdata, neww, newh = {}, math.max(1, room.w + dx), math.max(1, room.h + dy)
			
			-- copy all tiles (even if outside bounds - so they persist if you cut part of room off and then resize back)
			for i, col in pairs(room.data) do
				for j, n in pairs(col) do
					local i_, j_ = i + (ax == left and dx or 0), j + (ay == top and dy or 0)
					
					if not newdata[i_] then newdata[i_] = {} end
					newdata[i_][j_] = n
				end
			end
			-- add 0 when no data is there
			for i = 0, neww - 1 do
				newdata[i] = newdata[i] or {}
				for j = 0, newh - 1 do
					newdata[i][j] = newdata[i][j] or 0
				end
			end
			
			room.x = room.x - (ax == left and 8*(neww-room.w) or 0)
			room.y = room.y - (ay == top and 8*(newh-room.h) or 0)
			room.data, room.w, room.h = newdata, neww, newh
		end
	end
	
	if project.selection and app.tool ~= "select" then
		placeSelection()
	end
	
	if app.message then
		app.messageTimeLeft = app.messageTimeLeft - dt
		if app.messageTimeLeft < 0 then
			app.message = nil
			app.messageTimeLeft = nil
		end
	end
end

function love.draw()
	love.graphics.clear(0.25, 0.25, 0.25)
	love.graphics.reset()
	
	love.graphics.setLineStyle("rough")
	
	local x, y = love.mouse.getPosition()
	local mx, my = fromScreen(x, y)
	
	app.W, app.H = love.graphics.getDimensions()
	love.graphics.translate(math.floor(app.camScale * app.camX),
	                        math.floor(app.camScale * app.camY))
	love.graphics.scale(app.camScale)
	
	love.graphics.setColor(0.28, 0.28, 0.28)
	love.graphics.setLineWidth(2)
	for i = 0, 7 do
		for j = 0, 3 do
			love.graphics.rectangle("line", i*128, j*128, 128, 128)
		end
	end
	
	for _, room in ipairs(project.rooms) do
		drawRoom(room, p8data)
		if room ~= activeRoom() then
			love.graphics.setColor(0.5, 0.5, 0.5, 0.4)
			love.graphics.rectangle("fill", room.x, room.y, room.w*8, room.h*8)
		end
	end
	if project.selection then
		drawRoom(project.selection, p8data, true)
		love.graphics.setColor(0, 1, 0.5)
		love.graphics.setLineWidth(1 / app.camScale)
		love.graphics.rectangle("line", project.selection.x + 0.5 / app.camScale, project.selection.y + 0.5 / app.camScale, project.selection.w*8, project.selection.h*8)
	end
	
	local ti, tj = mouseOverTile()
	
	if app.tool == "tile" then
		if ti and not app.toolMenuX then
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(p8data.spritesheet, p8data.quads[app.currentTile], activeRoom().x + ti*8, activeRoom().y + tj*8)
			
			love.graphics.setColor(0, 1, 0.5)
			love.graphics.setLineWidth(1 / app.camScale)
			love.graphics.rectangle("line", activeRoom().x + ti*8 + 0.5 / app.camScale, 
			                                activeRoom().y + tj*8 + 0.5 / app.camScale, 8, 8)
		end
	elseif app.tool == "select" then
		if app.selectTileI and ti then
			local i, j, w, h = rectCont2Tiles(ti, tj, app.selectTileI, app.selectTileJ)
			love.graphics.setColor(0, 1, 0.5)
			love.graphics.setLineWidth(1 / app.camScale)
			love.graphics.rectangle("line", activeRoom().x + i*8 + 0.5 / app.camScale, 
			                                activeRoom().y + j*8 + 0.5 / app.camScale,
			                                w*8, h*8)
		end
	end
	
	love.graphics.reset()
	love.graphics.setColor(1, 1, 1)
	
	if app.message then
		love.graphics.print(app.message, 5, app.H - 18)
	end
	
	ui:draw()
end



-- KEYBOARD

function love.keypressed(key, scancode, isrepeat)
	ui:keypressed(key, scancode, isrepeat)
	
	local dx, dy = 0, 0
	if key == "left" then dx = -1 end
	if key == "right" then dx = 1 end
	if key == "up" then dy = -1 end
	if key == "down" then dy = 1 end
	if project.selection then
		project.selection.x = project.selection.x + dx*8
		project.selection.y = project.selection.y + dy*8
	end
	
	-- Ctrl+Z, Ctrl+Shift+Z
	if love.keyboard.isDown("lctrl") then
		if key == "z" then
			if love.keyboard.isDown("lshift") then
				redo()
			else
				undo()
			end
		end
	end
	
	if isrepeat then
		return
	end
	
	local x, y = love.mouse.getPosition()
	local mx, my = fromScreen(x, y)
	
	if key == "n" then
		local room = newRoom(roundto8(mx-64), roundto8(my-64), 16, 16)
		table.insert(project.rooms, room)
		app.room = #project.rooms
	elseif key == "delete" and love.keyboard.isDown("lshift") then
		if app.room then
			table.remove(project.rooms, app.room)
			if not activeRoom() then app.room = nil end
		end
	elseif key == "space" then
		if app.toolMenuX then
			app.toolMenuX, app.toolMenuY = nil, nil
		else
			if app.tool == "tile" then
				local i, j = app.currentTile%16, math.floor(app.currentTile/16)
				app.toolMenuX = x - (i + 0.5)*8*tms - i - 1
				app.toolMenuY = y - (j + 0.5)*8*tms - j - 1
			else
				app.toolMenuX, app.toolMenuY = x, y
			end
		end
	elseif key == "return" then
		placeSelection()
	elseif love.keyboard.isDown("lctrl") then
		-- Ctrl+O
		if key == "o" then
			local filename = filedialog.open()
			if filename then
				local openOk = false
				
				local ext = string.match(filename, ".(%w+)$")
				if ext == "ahm" then
					openOk = openMap(filename)
				elseif ext == "p8" then
					openOk = loadMapFromPico8(filename)
				end
				
				if openOk then
					showMessage("Opened "..string.match(filename, "\\([^\\]*)$"))
				else
					showMessage("Failed to open file")
				end
				
				app.history = {}
				app.historyN = 0
				pushHistory()
			end
		-- Ctrl+S
		elseif key == "s" then
			local filename
			if app.filename and not love.keyboard.isDown("lshift") then
				filename = app.filename
			else
				filename = filedialog.save()
			end
			
			if filename then
				if saveMap(filename) then
					showMessage("Saved "..string.match(filename, "\\([^\\]*)$"))
				end
			end
		-- Ctrl+U
		elseif key == "u" then
			local filename
			if app.cartfilename and not love.keyboard.isDown("lshift") then
				filename = app.cartfilename
			else
				filename = filedialog.open("*.p8\0*.p8\0")
			end
			app.cartfilename = filename
			
			if filename then
				if updateCart(filename) then
					showMessage("Updated "..string.match(filename, "\\([^\\]*)$"))
				else
					showMessage("Failed to update cart")
				end
			end
		-- Ctrl+X
		elseif key == "x" then
			if project.selection then
				local s = dumplua {"selection", project.selection}
				love.system.setClipboardText(s)
				project.selection = nil
				
				showMessage("Cut")
			end
		-- Ctrl+C
		elseif key == "c" then
			if project.selection then
				local s = dumplua {"selection", project.selection}
				love.system.setClipboardText(s)
				placeSelection()
				
				showMessage("Copied")
			end
		elseif key == "v" then
			placeSelection() -- to clean selection first
			
			local t, err = loadlua(love.system.getClipboardText())
			if not err then
				if type(t) == "table" then
					if t[1] == "selection" then
						local s = t[2]
						project.selection = s
						project.selection.x = roundto8(mx - s.w*4)
						project.selection.y = roundto8(my - s.h*4)
						app.tool = "select"
						
						showMessage("Pasted")
					else
						err = true
					end
				else
					err = true
				end
			end
			if err then
				showMessage("Failed to paste (did you paste something you're not supposed to?)")
			end
		end
	end
end

function love.keyreleased(key, scancode)
	ui:keyreleased(key, scancode)
	
	local x, y = love.mouse.getPosition()
	local mx, my = fromScreen(x, y)
	
	pushHistory()
end

function love.textinput(text)
	ui:textinput(text)
end



-- MOUSE

function love.mousepressed(x, y, button, istouch, presses)
	ui:mousepressed(x, y, button, istouch, presses)
	
	local mx, my = fromScreen(x, y)
	if button == 1 then
		if app.toolMenuX then
			closeToolMenu()
			app.suppressMouse = true
		else
			local oldActiveRoom = app.room
			app.room = nil
			for i, room in ipairs(project.rooms) do
				if mx >= room.x and mx <= room.x + room.w*8
				and my >= room.y and my <= room.y + room.h*8 then
					app.room = i
				end
			end
			if app.room ~= oldActiveRoom then
				app.suppressMouse = true
			end
			
			if app.room then
				if love.keyboard.isDown("lalt") then
					app.roomMoveX, app.roomMoveY = mx - activeRoom().x, my - activeRoom().y
				end
			end
			
			if app.tool == "select" then
				if not project.selection then
					local ti, tj = mouseOverTile()
					if ti then
						app.selectTileI, app.selectTileJ = ti, tj
					end
				else
					project.selectionMoveX, project.selectionMoveY = mx - project.selection.x, my - project.selection.y
					project.selectionStartX, project.selectionStartY = project.selection.x, project.selection.y
				end
			end
		end
	elseif button == 2 then
		if love.keyboard.isDown("lalt") and app.room then
			app.roomResizeSideX = sign(mx - activeRoom().x - activeRoom().w*8/2)
			app.roomResizeSideY = sign(my - activeRoom().y - activeRoom().h*8/2)
		end
	elseif button == 3 then
		app.camMoveX, app.camMoveY = fromScreen(x, y)
	end
end

function love.mousereleased(x, y, button, istouch, presses)
	ui:mousereleased(x, y, button, istouch, presses)
	
	local ti, tj = mouseOverTile()
	if app.tool == "select" then
		if app.selectTileI and ti then
			placeSelection()
		
			local i0, j0, w, h = rectCont2Tiles(ti, tj, app.selectTileI, app.selectTileJ)
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
		
		if project.selection and project.selectionMoveX then
			if project.selection.x == project.selectionStartX and project.selection.y == project.selectionStartY then
				placeSelection()
			end
		end
	end
	
	app.camMoveX, app.camMoveY = nil, nil
	app.roomMoveX, app.roomMoveY = nil, nil
	app.roomResizeSideX, app.roomResizeSideY = nil, nil
	app.selectTileI, app.selectTileJ = nil, nil
	project.selectionMoveX, project.selectionMoveY = nil, nil
	
	app.suppressMouse = false
	
	pushHistory()
end

function love.mousemoved(x, y, dx, dy, istouch)
	ui:mousemoved(x, y, dx, dy, istouch)
	
	local mx, my = fromScreen(x, y)
	local ti, tj = div8(mx), div8(my)
	if app.camMoveX then
		app.camX = app.camX + mx - app.camMoveX
		app.camY = app.camY + my - app.camMoveY
	end
	if app.roomMoveX and app.room then
		activeRoom().x = roundto8(mx - app.roomMoveX)
		activeRoom().y = roundto8(my - app.roomMoveY)
	end
	if project.selectionMoveX and project.selection then
		project.selection.x = roundto8(mx - project.selectionMoveX)
		project.selection.y = roundto8(my - project.selectionMoveY)
	end
end

function love.wheelmoved(x, y)
	ui:wheelmoved(x, y)
	
	if y ~= 0 then
		local mx, my = love.mouse.getPosition()
		rmx, rmy = fromScreen(mx, my)
		
		if y > 0 then
			app.camScaleSetting = app.camScaleSetting + 1
		elseif y < 0 then
			app.camScaleSetting = app.camScaleSetting - 1
		end
		app.camScaleSetting = math.min(math.max(app.camScaleSetting, -3), 20)
		app.camScale = app.camScaleSetting > 0 and (app.camScaleSetting + 1) or 2 ^ app.camScaleSetting
		
		nrmx, nrmy = fromScreen(mx, my)
		app.camX = app.camX + nrmx - rmx
		app.camY = app.camY + nrmy - rmy
	end
end
