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
