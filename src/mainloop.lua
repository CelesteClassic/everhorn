-- UI things

function tileButton(n, highlight)
    local x, y, w, h = ui:widgetBounds()
    ui:image({p8data.spritesheet, p8data.quads[n]})
    
    local hov = false
    if ui:inputIsHovered(x, y, w, h) then
        hov = true
    end
    if hov or highlight then
		love.graphics.setLineWidth(1)
        if hov then
			love.graphics.setColor(0, 1, 0.5)
		else
			love.graphics.setColor(1, 1, 1)
		end
        x, y = x - 0.5, y - 0.5
        w, h = w + 1, h + 1
        ui:line(x, y, x + w, y)
        ui:line(x, y, x, y + h)
        ui:line(x + w, y, x + w, y + h)
        ui:line(x, y + h, x + w, y + h)
    end
    if ui:inputIsMousePressed("left", x, y, w, h) then
		return true
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
        local bg = "#00ff88" --"#afafaf"
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
    love.keyboard.setKeyRepeat(true)

    ui = nuklear.newUI()
    
    --p8data = loadpico8(love.filesystem.getSource().."\\celeste.p8")
    
    newProject()
    pushHistory()
end

function love.update(dt)
    app.W, app.H = love.graphics.getDimensions()
    local rpw = app.W * 0.10 -- room panel width
    app.left, app.top = rpw, 0

    ui:frameBegin()
		--ui:scale(2)
    ui:stylePush {
        window = {
            spacing = {x = 1, y = 1},
            padding = {x = 1, y = 1},
        },
        selectable = {
			padding = {x = 0, y = 0},
			["normal active"] = "#000000",
			["hover active"] = "#000000",
			["pressed active"] = "#000000",
		}
    }
    
    -- room panel
    if ui:windowBegin("Room Panel", 0, 0, rpw, app.H, {"scrollbar"}) then
        ui:layoutRow("dynamic", 25*global_scale, 1)
        for n = 1, #project.rooms do
            if ui:selectable("["..n.."] "..project.rooms[n].title, n == app.room) then
                app.room = n
            end
        end
        
        if app.roomAdded then
			ui:windowSetScroll(0, 100000)
			app.roomAdded = false
		end
    end
    ui:windowEnd()
    
    -- tool panel
    if app.showToolPanel then
		local tpw = 16*8*tms + 18, 9*(8*tms+1) + 25 + 2
		if ui:windowBegin("Tool panel", app.W - tpw, 0, tpw, app.H) then
			ui:layoutRow("static", 25*global_scale, 100*global_scale, 2)
			if ui:selectable("Brush", app.tool == "brush") then app.tool = "brush" end
			if ui:selectable("Rectangle", app.tool == "rectangle") then app.tool = "rectangle" end
			ui:layoutRow("static", 25*global_scale, 100*global_scale, 1)
			if ui:selectable("Select", app.tool == "select") then app.tool = "select" end
			
			for j = 0, app.showGarbageTiles and 15 or 7 do
				ui:layoutRow("static", 8*tms, 8*tms, 16)
				for i = 0, 15 do
					local n = i + j*16
					if tileButton(n, app.currentTile == n and not app.autotile) then
						app.currentTile = n
						app.autotile = nil
					end
				end
			end
			
			ui:layoutRow("dynamic", 25*global_scale, 1)
            ui:label("Autotiles:")
            ui:layoutRow("static", 8*tms, 8*tms, #autotiles)
			for k, auto in ipairs(autotiles) do
				if tileButton(auto[5], app.currentTile == auto[15] and app.autotile) then
					app.currentTile = auto[15]
					app.autotile = k
				end
			end
		end
		ui:windowEnd()
	end
    
    if app.renameRoom then
        local room = app.renameRoom
        
        local w, h = 200*global_scale, 88*global_scale
        if ui:windowBegin("Rename room", app.W/2 - w/2, app.H/2 - h/2, w, h, {"title", "border", "closable", "movable"}) then
            ui:layoutRow("dynamic", 25*global_scale, 1)
            
            local state, changed
            ui:editFocus()
            state, changed = ui:edit("simple", app.renameRoomVTable)
            
            if ui:button("OK") or app.enterPressed then
                room.title = app.renameRoomVTable.value
                app.renameRoom = nil
            end
        else
            app.renameRoom = nil
        end
        ui:windowEnd()
    end
    
    app.enterPressed = false
    
    app.anyWindowHovered = ui:windowIsAnyHovered()
    
    ui:stylePop()
    
    local hov = ui:windowIsAnyHovered()
    
    ui:frameEnd()

    if app.brushing and not hov and not love.keyboard.isDown("lalt") and (love.mouse.isDown(1) or love.mouse.isDown(2)) then
        if app.tool == "brush" then
            local n = app.currentTile
            if love.mouse.isDown(2) then
                n = 0
            end
            
            local ti, tj = mouseOverTile()
            if ti then
                local room = activeRoom()
                
                activeRoom().data[ti][tj] = n
                
                if app.autotile then
                    autotileWithNeighbors(activeRoom(), ti, tj, app.autotile)
                end
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
    
    local ox, oy = toScreen(0, 0)
    love.graphics.translate(math.floor(ox), math.floor(oy))
    love.graphics.scale(app.camScale)
    
    love.graphics.setColor(0.28, 0.28, 0.28)
    love.graphics.setLineWidth(2)
    for i = 0, 7 do
        for j = 0, 3 do
            love.graphics.rectangle("line", i*128, j*128, 128, 128)
        end
    end
    
    for _, room in ipairs(project.rooms) do
		if room ~= activeRoom() then
			drawRoom(room, p8data)
            love.graphics.setColor(0.5, 0.5, 0.5, 0.4)
            love.graphics.rectangle("fill", room.x, room.y, room.w*8, room.h*8)
        end
    end
    if activeRoom() then
		drawRoom(activeRoom(), p8data)
	end
    if project.selection then
        drawRoom(project.selection, p8data, true)
        love.graphics.setColor(0, 1, 0.5)
        love.graphics.setLineWidth(1 / app.camScale)
        love.graphics.rectangle("line", project.selection.x + 0.5 / app.camScale, project.selection.y + 0.5 / app.camScale, project.selection.w*8, project.selection.h*8)
    end
    
    local ti, tj = mouseOverTile()
    
    if app.tool == "brush" or (app.tool == "rectangle" and not app.rectangleI) then
        if ti and not app.toolMenuX then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(p8data.spritesheet, p8data.quads[app.currentTile], activeRoom().x + ti*8, activeRoom().y + tj*8)
            
            love.graphics.setColor(0, 1, 0.5)
            love.graphics.setLineWidth(1 / app.camScale)
            love.graphics.rectangle("line", activeRoom().x + ti*8 + 0.5 / app.camScale, 
                                            activeRoom().y + tj*8 + 0.5 / app.camScale, 8, 8)
        end
    elseif (app.tool == "rectangle" and app.rectangleI) or app.tool == "select" then
		local i1, j1 = app.rectangleI or app.selectTileI, app.rectangleJ or app.selectTileJ
        if i1 and ti then
            local i, j, w, h = rectCont2Tiles(ti, tj, i1, j1)
            love.graphics.setColor(0, 1, 0.5)
            love.graphics.setLineWidth(1 / app.camScale)
            love.graphics.rectangle("line", activeRoom().x + i*8 + 0.5 / app.camScale, 
                                            activeRoom().y + j*8 + 0.5 / app.camScale,
                                            w*8, h*8)
        end
    end
    
    love.graphics.reset()
    love.graphics.setColor(1, 1, 1)
    love.graphics.translate(app.left, app.top)
    love.graphics.setFont(app.font)
		
    if app.message then
        love.graphics.print(app.message, 4, app.H - app.font:getHeight() - 4)
    end
    
    if app.playtesting then
        local s = app.playtesting == 1 and "[playtesting]" or "[playtesting, 2 dashes]"
        love.graphics.print(s, 4, 4)
    end
    ui:draw()
end
