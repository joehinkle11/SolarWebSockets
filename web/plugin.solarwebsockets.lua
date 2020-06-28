--#############################################################################
--# Corona HTML5 Websockets Plugin
--# (c)2018 C. Byerley (develephant)

--# Modified by Joe under Apache License 2.0
--# (c)2020 Joe Hinkle
--#############################################################################
local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name='solarwebsockets', publisherId='io.joehinkle' }

-------------------------------------------------------------------------------
-- BEGIN (Insert your implementation starting here)
-------------------------------------------------------------------------------

local develephantSockets = require("plugin_solarwebsockets_js")

lib.init = function(callback)
  local function WsListener(event)
    event.isClient = true
    event.isServer = false
    if event.type == develephantSockets.ONOPEN then
      event.name = "join"
    elseif event.type == develephantSockets.ONMESSAGE then
      event.name = "message"
      event.message = event.data
    elseif event.type == develephantSockets.ONCLOSE then
      event.name = "leave"
    elseif event.type == develephantSockets.ONERROR then
      event.name = "leave"
      event.errorMessage = event.reason
    end
    callback(event)
  end
  develephantSockets.addEventListener(WsListener)
end

lib.startServer = function()
	print( "WARNING: The '" .. lib.name .. "' library does not support servers this platform (because browsers cannot run servers)." )
end

lib.killServer = function()
	print( "WARNING: The '" .. lib.name .. "' library does not support servers this platform (because browsers cannot run servers)." )
end

lib.sendClient = function()
	print( "WARNING: The '" .. lib.name .. "' library does not support servers this platform (because browsers cannot run servers)." )
end

lib.sendAllClients = function()
	print( "WARNING: The '" .. lib.name .. "' library does not support servers this platform (because browsers cannot run servers)." )
end

lib.kick = function()
	print( "WARNING: The '" .. lib.name .. "' library does not support servers this platform (because browsers cannot run servers)." )
end

lib.connect = function(url)
	develephantSockets.connect(url)
end

lib.disconnect = function()
	develephantSockets.disconnect()
end

lib.sendServer = function(message)
	develephantSockets.send( message )
end
-------------------------------------------------------------------------------
-- END
-------------------------------------------------------------------------------

-- Return an instance
return lib
