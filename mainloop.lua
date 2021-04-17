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
		color = "#00ff88"
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
			toolLabel("Brush", "brush")
			toolLabel("Selection", "select")
		end
		ui:windowEnd()
		
		if app.tool == "brush" then
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
		if app.tool == "brush" then
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
	
	if app.tool == "brush" then
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
