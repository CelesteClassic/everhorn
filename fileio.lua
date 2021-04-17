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
			local b = fromhex(s)
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
			data.map[i][j] = fromhex(s)
		end
		for j = 32, 63 do
			local i_ = i%64
			local j_ = i <= 63 and j*2 or j*2 + 1
			local line = sections["gfx"][j_ + 1] or "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
			local s = string.sub(line, 1 + 2*i_, 2 + 2*i_)
			data.map[i][j] = fromhex_swapnibbles(s)
		end
	end
	
	data.rooms = {}
	data.roomBounds = {}
	
	-- code: look for the magic comment
	local code = table.concat(sections["lua"])
	local evh = string.match(code, "%-%-@everhorn_begin([^@]+)%-%-@everhorn_end")
	local levels, mapdata
	if evh then
		local chunk, err = loadstring(evh)
		if not err then
			local t = {}
			chunk = setfenv(chunk, t)
			chunk()
			
			levels, mapdata = t.levels, t.mapdata
		end
	end
	
	if levels then
		for n, s in pairs(levels) do
			local x, y, w, h, title = string.match(s, "^([^,]*),([^,]*),([^,]*),([^,]*),?([^,]*)$")
			x, y, w, h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
			if x and y and w and h then -- this confirms they're there and they're numbers
				data.roomBounds[n] = {x=x*128, y=y*128, w=w*16, h=h*16}
			else
				print("wat", s)
			end
		end
	else
		for I = 0, 7 do
			for J = 0, 3 do
				local b = {x = I*128, y = J*128, w = 16, h = 16}
				table.insert(data.roomBounds, b)
			end
		end
	end
	
	if mapdata then
		for n, levelstr in pairs(mapdata) do
			local b = data.roomBounds[n]
			if b then
				local room = newRoom(b.x, b.y, b.w, b.h)
				for i = 0, b.w - 1 do
					for j = 0, b.h - 1 do
						local k = i + j*b.w 
						room.data[i][j] = fromhex(string.sub(levelstr, 1 + 2*k, 2 + 2*k))
					end
				end
				data.rooms[n] = room
			end
		end
	end
	
	-- fill rooms with no mapdata from p8 map
	for n, b in ipairs(data.roomBounds) do
		if not data.rooms[n] then
			local room = newRoom(b.x, b.y, b.w, b.h)
			
			for i = 0, b.w - 1 do
				for j = 0, b.h - 1 do
					local i1, j1 = div8(b.x) + i, div8(b.y) + j
					if i1 >= 0 and i1 < 128 and j1 >= 0 and j1 < 64 then
						room.data[i][j] = data.map[i1][j1]
					else
						room.data[i][j] = 0
					end
				end
			end
			
			data.rooms[n] = room
		end
	end
	return data
end

function openPico8(filename)
	local p8data = loadpico8(filename)
	
	newProject()
	project.rooms = p8data.rooms
	
	app.openFileName = filename
	
	return true
end

function savePico8(filename)
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
	if not file and app.openFileName then
		file = io.open(app.openFileName, "r")
	end
	if not file then
		return false
	end
	
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
	
	-- no __map__ and __gfx__ rn
	--for j = 0, 31 do
		--local line = ""
		--for i = 0, 127 do
			--line = line .. tohex(map[i][j])
		--end
		--out[mapstart+j+1] = line
	--end
	--for j = 32, 63 do
		--local line = ""
		--for i = 0, 127 do
			--line = line .. tohex_swapnibbles(map[i][j])
		--end
		--out[gfxstart+(j-32)*2+65] = string.sub(line, 1, 128)
		--out[gfxstart+(j-32)*2+66] = string.sub(line, 129, 256)
	--end
	
	-- code updates
	for k = 1, #out do
		if out[k] == "--@everhorn_begin" then
			while #out >= k+1 and out[k+1] ~= "--@everhorn_end" do
				if #out >= k+1 then
					table.remove(out, k+1)
				else
					return false
				end
			end
			
			local levels, mapdata = {}, {}
			for n = 1, #project.rooms do
				local room = project.rooms[n]
				levels[n] = string.format("%d,%d,%d,%d,(title)", room.x/128, room.y/128, room.w/16, room.h/16)
				
				local s = ""
				for j = 0, room.h - 1 do
					for i = 0, room.w - 1 do
						s = s .. tohex(room.data[i][j])
					end
				end
				mapdata[n] = s
			end
			
			table.insert(out, k+1, "levels = "..dumplua(levels))
			table.insert(out, k+2, "mapdata = "..dumplua(mapdata))
		end
	end
	
	file:close()
	
	file = io.open(filename, "w")
	file:write(table.concat(out, "\n"))
	file:close()
	
	app.saveFileName = filename
	
	return true
end
