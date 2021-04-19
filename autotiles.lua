--  8
--2 O 1
--  4

autotiles = {
    -- snow
    [1] = {
        [0]  = 32,
        [1]  = 52,
        [2]  = 54,
        [3]  = 53,
        [4]  = 39,
        [5]  = 33,
        [6]  = 35,
        [7]  = 34,
        [8]  = 55,
        [9]  = 49,
        [10] = 51,
        [11] = 50,
        [12] = 48,
        [13] = 36,
        [14] = 38,
        [15] = 37,
        -- indexes beyond 15 can be used to allow connecting to extra tiles
        [16] = 72,
    },
    -- ice
    [2] = {
        [0]  = 117,
        [1]  = 114,
        [2]  = 116,
        [3]  = 115,
        [4]  = 69,
        [5]  = 66,
        [6]  = 68,
        [7]  = 67,
        [8]  = 101,
        [9]  = 98,
        [10] = 100,
        [11] = 99,
        [12] = 85,
        [13] = 82,
        [14] = 84,
        [15] = 83,
    },
    -- bg dirt (simplistic - only 
    [3] = {
		[0]  = 40,
		[1]  = 40,
		[2]  = 40,
		[3]  = 40,
		[4]  = 40,
		[5]  = 58,
		[6]  = 57,
		[7]  = 40,
		[8]  = 40,
		[9]  = 42,
		[10] = 41,
		[11] = 40,
		[12] = 40,
		[13] = 40,
		[14] = 40,
		[15] = 40,
	},
}

autotilet, autotilet_strict = {}, {}
-- n => autotile n belongs to, if any
-- strict excludes extra autotiles (>=16)

for k, auto in ipairs(autotiles) do
    for nb, n in pairs(auto) do
        autotilet[n] = k
        if nb >= 0 and nb < 16 then
            autotilet_strict[n] = k
        end
    end
end

local function isAutotile(room, i, j, strict)
    if i >= 0 and i < room.w and j >= 0 and j < room.h then
        local t = strict and autotilet_strict or autotilet
        return t[room.data[i][j]]
    else
        return 0 -- out-of-bounds is considered autotile 0, which connects to any other autotile
    end
end

local function b1(b) -- converts truthy to 1, falsy to 0
    return b and 1 or 0
end

local function matches(x, k)
    return x == 0 and true or x == k
end

function autotile(room, i, j)
    local k = isAutotile(room, i, j, true)
    if k and k ~= 0 and autotiles[k] then
        local nb = b1(matches(isAutotile(room, i + 1, j), k))
                 + b1(matches(isAutotile(room, i - 1, j), k)) * 2
                 + b1(matches(isAutotile(room, i, j + 1), k)) * 4
                 + b1(matches(isAutotile(room, i, j - 1), k)) * 8
        room.data[i][j] = autotiles[k][nb]
    end
end

function autotileWithNeighbors(room, i, j)
	autotile(room, i, j)
	autotile(room, i + 1, j)
	autotile(room, i - 1, j)
	autotile(room, i, j + 1)
	autotile(room, i, j - 1)
end
