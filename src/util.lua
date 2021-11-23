function fromhex(s)
    return tonumber(s, 16)
end

function fromhex_swapnibbles(s)
    local x = fromhex(s)
    return math.floor(x/16) + 16*(x%16)
end

local hext = { [0] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'a', 'b', 'c', 'd', 'e', 'f'}

function tohex(b)
    return hext[math.floor(b/16)]..hext[b%16]
end

function tohex_swapnibbles(b)
    return hext[b%16]..hext[math.floor(b/16)]
end

function roundto8(x)
    return 8*math.floor(x/8 + 1/2)
end

function sign(x)
    return x > 0 and 1 or -1
end

function fill2d0s(w, h)
    local a = {}
    for i = 0, w - 1 do
        a[i] = {}
        for j = 0, h - 1 do
            a[i][j] = 0
        end
    end
    return a
end

function rectCont2Tiles(i, j, i_, j_)
    return math.min(i, i_), math.min(j, j_), math.abs(i - i_) + 1, math.abs(j - j_) + 1
end

function div8(x)
    return math.floor(x/8)
end

function dumplua(t)
    return serpent.block(t, {comment = false})
end

function loadlua(s)
    f, err = loadstring("return "..s)
    if err then
        return nil, err
    else
        return f()
    end
end

local alph_ = "abcdefghijklmnopqrstuvwxyz"
local alph = {[0] = " "}
for i = 1, 26 do
	alph[i] = string.sub(alph_, i, i)
end

function b26(n)
	local m, n = math.floor(n / 26), n % 26
	if m > 0 then
		return b26(m - 1) .. alph[n + 1]
	else
		return alph[n + 1]
	end
end

function loadroomdata(room, levelstr)
	for i = 0, room.w - 1 do
		for j = 0, room.h - 1 do
			local k = i + j*room.w 
			room.data[i][j] = fromhex(string.sub(levelstr, 1 + 2*k, 2 + 2*k))
		end
	end
end

function dumproomdata(room)
	local s = ""
	for j = 0, room.h - 1 do
		for i = 0, room.w - 1 do
			s = s .. tohex(room.data[i][j])
		end
	end
	return s
end

function roomMakeStr(room)
	if room then
		room.str = dumproomdata(room)
	end
end

function roomMakeData(room)
	if room then
		room.data = fill2d0s(room.w, room.h)
		loadroomdata(room, room.str)
	end
end

function loadproject(str)
	local proj = loadlua(str)
	for n, room in pairs(proj.rooms) do
		roomMakeData(room)
	end
	roomMakeData(proj.selection)
	
	return proj
end

function dumpproject(proj)
	for n, room in pairs(proj.rooms) do
		roomMakeStr(room)
	end
	roomMakeStr(proj.selection)
	
	return serpent.line(proj, {compact = true, comment = false, keyignore = {["data"] = true}})
end
