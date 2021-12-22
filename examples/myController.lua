package.cpath = "luaclib/?.so;luaclib/?.dll;"
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local lfs = require "lfs"
require "skynet.manager"	-- import skynet.register

local CMD = {}
local tasks = {}
local lastTaskId = 0
local workers = {}


--执行添加任务命令，在任务列表中增加一条任务
function CMD.addtask(srcFile)
    --do convert task
	lastTaskId = lastTaskId + 1
	local newtask = {}
	newtask.taskid = lastTaskId
	newtask.srcFile = srcFile
	table.insert(tasks,newtask)
	skynet.error("myController:addtask:",newtask.taskid,newtask.srcFile )
    return newtask.taskid
end

function CMD.GETWORKERLIST()

end

-- local srcDir = "./SrcFiles"
-- local tarDir = "./OutFiles"
-- local srcFiles = {}

-- local function getFileList()
-- 	local ret = {}
-- 	for f in lfs.dir(srcDir) do
-- 		if f ~= "." and f ~= ".." then
-- 			table.insert(ret,f)
-- 			--print(f)
-- 			--skynet.error("file:", f)
-- 		end
-- 	end
-- 	return ret
-- end
local serverSession = 1

--找到空闲的远程转换服务，向其中增加一条转换任务
local function sendDoTask()
	if #tasks>0 then
		serverSession = serverSession + 1
		local curtask = tasks[1]
		skynet.error("myController:sendDoTask:taskid:"..curtask.taskid,"srcFile:"..curtask.srcFile)
		--send_package(send_request("dotask",{taskid=curtask.taskid,srcFile=curtask.srcFile},serverSession))
		local proxy1 = cluster.proxy("worker1", ".myWorker")
		skynet.call(proxy1, "lua", "dotask", {taskid=curtask.taskid,srcFile=curtask.srcFile})
		table.remove(tasks,1)
	end
end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		skynet.error(cmd)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(subcmd, ...)))
	end)

	--任务处理线程
	skynet.fork(function()
		while true do
			sendDoTask()
			skynet.sleep(500)
		end
	end)

	skynet.register "myController"
end)


