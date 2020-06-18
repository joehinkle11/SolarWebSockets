local SolarWebSockets = require "plugin.solarwebsockets"

-- This event is dispatched to the global Runtime object
-- by `didLoadMain:` in MyCoronaDelegate.mm
local function delegateListener( event )
	native.showAlert(
		"Event dispatched from `didLoadMain:`",
		"of type: " .. tostring( event.name ),
		{ "OK" } )
end
Runtime:addEventListener( "delegate", delegateListener )

-- This event is dispatched to the following Lua function
-- by PluginLibrary::show() in PluginLibrary.mm
local function wsListener( event )
    if event.message ~= nil then
        print("have message", event.message)
    end
    if event.name == "join" then
        print("join", "clients #", #event.clients)
        for i=1, #event.clients do
            print(
                "client "..tostring(i),
                tostring(event.clients[i]),
                tostring(event.clients[i].clientId),
                tostring(event.clients[i].clientIp)
            )
        end
    end
    if event.name == "message" then
        print("got message")
        print(event.clientId)
        print(event.clientIp)
        print(event.message)
        SolarWebSockets.send(event.clientId,"echo "..event.message)
        SolarWebSockets.sendAll("some said "..event.message)
    end
    if event.name == "leave" then
        print("leave","clients #", #event.clients)
        for i=1, #event.clients do
            print(
                "client "..tostring(i),
                tostring(event.clients[i]),
                tostring(event.clients[i].clientId),
                tostring(event.clients[i].clientIp)
            )
        end
    end
end

SolarWebSockets.init( wsListener )




local widget = require("widget")

local button = widget.newButton({
   left = 100,
   top = 100,
   label = "Start Server",
   shape = "rect",
   onRelease = function()
       SolarWebSockets.startServer()
   end,
   fillColor = { default={ 1, 1, 1 }, over={ .2, 0.2, 0.2 } }
})
