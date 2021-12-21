package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;examples/?.lua"

if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

local socket = require "client.socket"
local proto = require "proto"
local sproto = require "sproto"

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

local fd = assert(socket.connect("127.0.0.1", 8888))

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)--再次用2字节长度和包内容格式打包发送数据
	socket.send(fd, package)
end

--解压数据包
local function unpack_package(text)
	local size = #text
	if size < 2 then--size小于2说明连包长也没有
		return nil, text
	end

	--前两个字节作为包长
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then--size小于s+2说明当前包坏
		return nil, text
	end

	--lua的sub是(开始索引、结束索引)：
	--text:sub(3,2+s)即从第3个字节到包长结束的索引，即获取整个包内容，丢弃包长
	--text:sub(3+s) 即从第3+s个字节开始取值到最后，即获取剩下的内容
	return text:sub(3,2+s), text:sub(3+s)
end

--收取数据包
local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then--如果有解开的包则返回
		return result, last
	end
	--如果没有解开的包则接收socket
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end

	--如果有接收内容则解包返回
	return unpack_package(last .. r)
end

local session = 0

local function send_request(name, args)
	session = session + 1--每个客户端请求一个sessionID
	local str = request(name, args, session)--使用sproto的c2s节打包请求内容
	send_package(fd, str)--发送请求
	print("Request:", session,name)--Pascal命名法的输出是客户端向服务端发送的
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local last = ""

local function print_request(name, args)
	print("REQUEST", name)--大写的输出是服务端向客户端发送的
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_response(session, args)
	print("RESPONSE", session)--大写的输出是服务端向客户端发送的
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_package(t, ...)
	if t == "REQUEST" then
		print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end

		print_package(host:dispatch(v))--使用sproto的c2s解包函数，解成3部分，
		--"REQUEST",消息类型名,消息内容
		--"RESPONSE",session,消息内容。
		--见https://github.com/cloudwu/skynet/wiki/Sproto
	end
end

local function mysplit (inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

send_request("handshake")
send_request("set", { what = "hello", value = "world" })
while true do
	--分发数据包
	dispatch_package()

	--根据命令行输入内容发送请求
	local cmd = socket.readstdin()
	if cmd then
		if cmd == "quit" then
			send_request("quit")
		--test 增加设置kv的命令
		elseif string.len(cmd) > 4 and string.sub(cmd,1,3)=="set" then
			local strArray = mysplit(cmd, " ")
			send_request("set", { what = strArray[2], value = strArray[3]})
		else
			send_request("get", { what = cmd })
		end
	else
		socket.usleep(100)
	end
end
