local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name='solarwebsockets', publisherId='io.joehinkle' }

-------------------------------------------------------------------------------
-- BEGIN (Insert your implementation starting here)
-------------------------------------------------------------------------------

lib.init = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

lib.startServer = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

lib.killServer = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

lib.sendClient = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

lib.sendAllClients = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

lib.kick = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

lib.connect = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

lib.disconnect = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

lib.sendServer = function()
	print( "WARNING: The '" .. lib.name .. "' library is not available on this platform." )
end

-------------------------------------------------------------------------------
-- END
-------------------------------------------------------------------------------

-- Return an instance
return lib
