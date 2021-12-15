package.cpath = "luaclib/?.so;luaclib/?.dll;"
local skynet = require "skynet"
local lfs = require "lfs"

local CMD = {}

local out = io.popen('find /v "" > con', "w")
function print(s)
  out:write(s.."\r\n") --\r because windows
  out:flush()
end

function CMD.CONVERT(source,target)
    local t = io.popen('.\\sview\\convert.exe'..source.." "..target)
    local a = t:read("*all")

    return a
end

local srcDir = "./SrcFiles"
local tarDir = "./OutFiles"
local srcFiles = {}

local function getFileList()
	local ret = {}
	for f in lfs.dir(srcDir) do
		if f ~= "." and f ~= ".." then
			table.insert(ret,f)
			--print(f)
			--skynet.error("file:", f)
		end
	end
	return ret
end


skynet.start(function()
	srcFiles = getFileList()
	skynet.error("srcFiles:", #srcFiles)
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
	end)
end)


