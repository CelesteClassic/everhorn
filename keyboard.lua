function love.keypressed(key, scancode, isrepeat)
    local x, y = love.mouse.getPosition()
    local mx, my = fromScreen(x, y)

    if key == "return" then
        app.enterPressed = true
    end
    
    -- first handle actions that are allowed to repeat when holding key
    
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
    
    if (key == "down" or key == "up") and love.keyboard.isDown("lctrl") then
        if app.room then
            local n1 = app.room
            local n2 = key == "down" and app.room + 1 or app.room - 1
            if project.rooms[n1] and project.rooms[n2] then
                local tmp = project.rooms[n1]
                project.rooms[n1] = project.rooms[n2]
                project.rooms[n2] = tmp
                
                app.room = n2
            end
        end
    end
    
    if isrepeat then
        return
    end
    
    -- non-repeatable global shortcuts
    
    if love.keyboard.isDown("lctrl") then
        -- Ctrl+O
        if key == "o" then
            local filename = filedialog.open()
            if filename then
                local openOk = false
                
                local ext = string.match(filename, ".(%w+)$")
                if ext == "ahm" then
                    openOk = openMap(filename)
                elseif ext == "p8" then
                    openOk = openPico8(filename)
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
            if app.saveFileName and not love.keyboard.isDown("lshift") then
                filename = app.saveFileName
            else
                filename = filedialog.save()
            end
            
            if filename and savePico8(filename) then
                showMessage("Saved "..string.match(filename, "\\([^\\]*)$"))
            else
                showMessage("Failed to save cart")
            end
        -- Ctrl+X
        elseif key == "x" then
            if love.keyboard.isDown("lshift") then
                -- cut entire room
                if activeRoom() then
                    local s = dumplua {"room", activeRoom()}
                    love.system.setClipboardText(s)
                    table.remove(project.rooms, app.room)
                    app.room = nil
                    
                    showMessage("Cut room")
                end
            else
                -- cut selection
                if project.selection then
                    local s = dumplua {"selection", project.selection}
                    love.system.setClipboardText(s)
                    project.selection = nil
                    
                    showMessage("Cut")
                end
            end
        -- Ctrl+C
        elseif key == "c" then
            if love.keyboard.isDown("lshift") then
                -- copy entire room
                if activeRoom() then
                    local s = dumplua {"room", activeRoom()}
                    love.system.setClipboardText(s)
                    
                    showMessage("Copied room")
                end
            else
                -- copy selection
                if project.selection then
                    local s = dumplua {"selection", project.selection}
                    love.system.setClipboardText(s)
                    placeSelection()
                    
                    showMessage("Copied")
                end
            end
        -- Ctrl+V
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
                    elseif t[1] == "room" then
                        local r = t[2]
                        r.x = roundto8(mx - r.w*4)
                        r.y = roundto8(my - r.h*4)
                        table.insert(project.rooms, r)
                        app.room = #project.rooms
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
        elseif key == "a" then
            if activeRoom() then
                app.tool = "select"
                select(0, 0, activeRoom().w - 1, activeRoom().h - 1)
            end
        end
    end
    
    -- now pass to nuklear and return if consumed
    
    if ui:keypressed(key, scancode, isrepeat) then
        return
    end
    
    -- another fucking hack: the shit above doesnt consume inputs when editing text for some fucking reason
    if app.renameRoom then
        return
    end
    
    -- now editing things (that shouldn't happen if you have a nuklear window focused or something)
    
    if key == "n" then
        local room = newRoom(roundto8(mx-64), roundto8(my-64), 16, 16)
        
        -- generate alphabetic room title
        local n, title = 0, nil
        while true do
			title = b26(n)
			local exists = false
			for _, otherRoom in ipairs(project.rooms) do
				if otherRoom.title == title then
					exists = true
				end
			end
			if not exists then
				break
			end
			n = n + 1
		end
		room.title = title
        
        table.insert(project.rooms, room)
        app.room = #project.rooms
        app.roomAdded = true
    elseif key == "delete" and love.keyboard.isDown("lshift") then
        if app.room then
            table.remove(project.rooms, app.room)
            if not activeRoom() then app.room = nil end
        end
    elseif key == "space" then
        -- open tile menu
        if app.toolMenuX then
            app.toolMenuX, app.toolMenuY = nil, nil
        else
            if app.tool == "brush" then
                if not app.autotile then
                    local i, j = app.currentTile%16, math.floor(app.currentTile/16)
                    app.toolMenuX = x - (i + 0.5)*8*tms - i - 1
                    app.toolMenuY = y - (j + 0.5)*8*tms - j - 1
                elseif app.autotile then
                    local i = app.autotile - 1
                    app.toolMenuX = x - (i + 0.5)*8*tms - i - 1
                    app.toolMenuY = y - (8 + 0.5)*8*tms - 8 - 1 - 25
                end
            else
                app.toolMenuX, app.toolMenuY = x, y
            end
        end
    elseif key == "return" then
        placeSelection()
    elseif key == "tab" then
        app.playtesting = not app.playtesting
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
