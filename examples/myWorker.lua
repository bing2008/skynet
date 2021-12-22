package.cpath = "luaclib/?.so;luaclib/?.dll;"
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local lfs = require "lfs"
require "skynet.manager"	-- import skynet.register

local CMD = {}
local tasks = {}
local lastTaskId = 0
local workers = {}

local function convertFile(source,target)
    local exe = "F:\\source\\SView\\convert\\CadConverter\\CADConverter.exe"
	local opt = "F:\\source\\SView\\convert\\CadConverter\\CADConverter.cfg"
    local t = io.popen(exe.." "..source.." "..target .. " " .. opt)
    local a = t:read("*all")
    return a
end

function CMD.CONVERT(srcFile)
    --do convert task
	local covRet = convertFile("SrcFiles\\"..srcFile, "TarFiles\\")
    return covRet
end


skynet.start(function()

	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
	end)
	skynet.register(".myWorker")
	cluster.open "worker1"

end)


