local filedialog = {}

local nfd = require 'nfd'

function filedialog.open()
    local r = nfd.open("p8")
    print(r)
    return r
end

function filedialog.save()
    return nfd.save("p8")
end

return filedialog
