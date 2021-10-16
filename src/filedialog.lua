local filedialog = {}

if love.system.getOS()~="OS X" then 
    local nfd = require 'nfd'

    function filedialog.open()
        local r = nfd.open("p8")
        print(r)
        return r
    end

    function filedialog.save()
        return nfd.save("p8")
    end
else
    local io=require 'io'
    local function run_python(arg)
        local handle=io.popen("python filedialog.py "..arg)
        local return_code=handle:read("*n")
        local ret
        if return_code==0 then
            ret=false
        else
            ret=handle:read("*l"):gsub("^%s*(.-)%s*$", "%1")
        end 
        handle:close()
        return ret
    end 


    function filedialog.open()
        return run_python('open')
    end 
    function filedialog.save()
        return run_python('save')
    end
end

return filedialog
