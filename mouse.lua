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
