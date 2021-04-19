function love.mousepressed(x, y, button, istouch, presses)
    if ui:mousepressed(x, y, button, istouch, presses) then
        return
    end
    
    local mx, my = fromScreen(x, y)
    if button == 1 then
        if not app.toolMenuX then
            local oldActiveRoom = app.room
            for i, room in ipairs(project.rooms) do
                if mx >= room.x and mx <= room.x + room.w*8
                and my >= room.y and my <= room.y + room.h*8 then
                    app.room = i
                end
            end
            if app.room ~= oldActiveRoom then
                app.suppressMouse = true
            end
            
            if love.keyboard.isDown("lalt") then
                if app.room then
                    app.roomMoveX, app.roomMoveY = mx - activeRoom().x, my - activeRoom().y
                end
                return
            end
            
            if app.tool == "brush" and not app.suppressMouse then
				app.brushing = true
			elseif app.tool == "select" then
				local ti, tj = mouseOverTile()
				if not project.selection then
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
            return
        end
        
        if app.tool == "brush" then
			app.brushing = true
		end
    elseif button == 3 then
        app.camMoveX, app.camMoveY = fromScreen(x, y)
    end
    
    if button == 1 or button == 2 then
		local ti, tj = mouseOverTile()
		if app.tool == "rectangle" and ti then
			app.rectangleI, app.rectangleJ = ti, tj
		end
	end
end

function love.mousereleased(x, y, button, istouch, presses)
    if ui:mousereleased(x, y, button, istouch, presses) then
        return
    end
    
    local ti, tj = mouseOverTile()
	
    if app.tool == "rectangle" or app.tool == "select" then
		local i1, j1 = app.rectangleI or app.selectTileI, app.rectangleJ or app.selectTileJ
		
		if app.tool == "rectangle" and i1 and ti then
			local room = activeRoom()
			
			local n = app.currentTile
			if app.autotile then
				n = autotiles[autotilet[n]][15] -- inner version
			end
			if button == 2 then
				n = 0
			end
			
			local i0, j0, w, h = rectCont2Tiles(i1, j1, ti, tj)
			for i = i0, i0 + w - 1 do
				for j = j0, j0 + h - 1 do
					room.data[i][j] = n
				end
			end
			
			if app.autotile then
				for i = i0, i0 + w - 1 do
					autotileWithNeighbors(room, i, j0)
					autotileWithNeighbors(room, i, j0 + h - 1)
				end
				for j = j0 + 1, j0 + h - 2 do
					autotileWithNeighbors(room, i0, j)
					autotileWithNeighbors(room, i0 + w - 1, j)
				end
			end
 		elseif app.tool == "select" then
			if i1 and ti then
				placeSelection()
				
				select(ti, tj, i1, j1)
			end
			
			if project.selection and project.selectionMoveX then
				if project.selection.x == project.selectionStartX and project.selection.y == project.selectionStartY then
					placeSelection()
				end
			end
		end
    end
    
    app.camMoveX, app.camMoveY = nil, nil
    app.roomMoveX, app.roomMoveY = nil, nil
    app.roomResizeSideX, app.roomResizeSideY = nil, nil
    app.brushing = false
    app.rectangleI, app.rectangleJ = nil, nil
    app.selectTileI, app.selectTileJ = nil, nil
    project.selectionMoveX, project.selectionMoveY = nil, nil
    
    app.suppressMouse = false
    
    -- just save history every time a mouse button is released lol
    pushHistory()
end

function love.mousemoved(x, y, dx, dy, istouch)
    if ui:mousemoved(x, y, dx, dy, istouch) then
        return
    end
    
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
    -- this is an inelegant solution to the fact that some slut decided that scrollbars scroll even if the window isn't even hovered
    if app.anyWindowHovered then
        if ui:wheelmoved(x, y) then
            return
        end
    end
    
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
