local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

get 2 {
	request {
		what 0 : string
	}
	response {
		result 0 : string
	}
}

set 3 {
	request {
		what 0 : string
		value 1 : string
	}
}

quit 4 {}

addtask 5 {
	request {
		srcFile 0 : string
	}
	response {
		result 0: integer #enum: >0=success and return taskid -1=error
	}
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {
	request {
		what 0 : string
	}
	response {
		status 0: integer #enum: 0=Ready 1=busy
	}
}

dotask 2 {
	request {
		taskid 0 :integer
		srcFile 1 : string
	}
	response {
		result 0: integer #enum: 0=success 1=error
		error 1: string
	}
}
]]

return proto
