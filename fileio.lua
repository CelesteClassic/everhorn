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
