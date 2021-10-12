local skynet = require "skynet"

local CMD = {}
function CMD.CONVERT(source,target)
    local t = io.popen('.\\sview\\convert.exe'..source.." "..target)
    local a = t:read("*all")
    return a
end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
	end)
end)


