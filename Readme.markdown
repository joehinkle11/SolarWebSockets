# Solar2d WebSockets (Server/Client)

Notice: I'm waiting to get this repository published in the Solar2d Plugin directory (https://plugins.solar2d.com), and so I recommend you wait for it to appear there before trying to use it in my project. It works for me great locally, but I think it's too difficult to integrate it into the Solar simulator before it's available as a public plugin.

## Overview

I'm made a full websocket client and server plugin for Solar2d.


## Support

| Platform | Details |
| ------------------- | -------- |
| iOS | client (ws, wss), server (ws) |
| iOS Simulator | client (ws, wss), server (ws) |
| Android | client (ws, wss), server (ws) |
| Web/HTML5 | client (ws, wss) |
| TVOS | client (ws, wss), server (ws) |
| TVOS Simulator | client (ws, wss), server (ws) |
| Corona Simulator (Mac) | client (ws, wss), server (ws) |
| Corona Simulator (Windows) | todo |

## TODO

SLL for servers

Windows

Documenation

## Example Use

```lua
local SolarWebSockets = require "plugin.solarwebsockets"

local message = display.newText("debug messages here", 120, 320, nil, 6)

local clients = {}
local json = require("json")
local function wsListener( event )
    message.text = json.encode(event)
    if event.isServer then
        if event.name == "join" then
            print("join", "clients #", #event.clients)
            print(event.clientId)
            print(event.clientIp)
            clients = event.clients
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
            SolarWebSockets.sendClient(event.clientId,"echo "..event.message)
            SolarWebSockets.sendAllClients("someone said "..event.message)
            if event.message == "kick" then
                local clientToKick = clients[1]
                if clientToKick then
                    print("going to kick "..tostring(clientToKick.clientId))
                    SolarWebSockets.kick(clientToKick.clientId)
                end
            end
        end
        if event.name == "leave" then
            print("leave","clients #", #event.clients)
            print(event.clientId)
            print(event.clientIp)
            clients = event.clients
            for i=1, #event.clients do
                print(
                    "client "..tostring(i),
                    tostring(event.clients[i]),
                    tostring(event.clients[i].clientId),
                    tostring(event.clients[i].clientIp)
                )
            end
        end
    elseif event.isClient then
        if event.name == "join" then
            -- connected
        end
        if event.name == "message" then
            print("got message from server")
            print(event.message)
            -- send reply
            -- SolarWebSockets.sendServer("reply "..event.message)
        end
        if event.name == "leave" then
            -- not connected anymore
            print("left server")
            print("error code: ",tostring(event.errorCode))
            print("error message: ",tostring(event.errorMessage))
        end
    end
end

SolarWebSockets.init( wsListener )

local widget = require("widget")

widget.newButton({
   left = 50,
   width = 100,
   top = 50,
   label = "Start Server",
   shape = "rect",
   onRelease = function()
       SolarWebSockets.startServer()
   end,
   fillColor = { default={ 1, 1, 1 }, over={ .2, 0.2, 0.2 } }
})
SolarWebSockets.startServer()

widget.newButton({
    left = 50,
    width = 100,
    top = 150,
    label = "Kill Server",
    shape = "rect",
    onRelease = function()
        SolarWebSockets.killServer()
    end,
    fillColor = { default={ 1, 1, 1 }, over={ .2, 0.2, 0.2 } }
})

widget.newButton({
   left = 50,
   width = 100,
   top = 250,
   label = "Kick someone",
   shape = "rect",
   onRelease = function()
       local clientToKick = clients[1]
       if clientToKick then
           print("going to kick "..tostring(clientToKick.clientId))
           SolarWebSockets.kick(clientToKick.clientId)
       end
   end,
   fillColor = { default={ 1, 1, 1 }, over={ .2, 0.2, 0.2 } }
})


-- client
widget.newButton({
    left = 150,
    width = 100,
    top = 50,
    label = "Connect to Server",
    shape = "rect",
    onRelease = function()
        -- wss not supported on iOS...yet
        SolarWebSockets.connect("wss://echo.websocket.org")
    end,
    fillColor = { default={ 1, 1, 1 }, over={ .2, 0.2, 0.2 } }
 })
 
widget.newButton({
    left = 150,
    width = 100,
    top = 150,
    label = "SendMessage",
    shape = "rect",
    onRelease = function()
       SolarWebSockets.sendServer("sample message")
    end,
    fillColor = { default={ 1, 1, 1 }, over={ .2, 0.2, 0.2 } }
})
 
widget.newButton({
    left = 150,
    width = 100,
    top = 250,
    label = "Disconnect",
    shape = "rect",
    onRelease = function()
       SolarWebSockets.disconnect()
    end,
    fillColor = { default={ 1, 1, 1 }, over={ .2, 0.2, 0.2 } }
})
```

## Sources
 
 - https://github.com/TooTallNate/Java-WebSocket (MIT)
 - https://github.com/mortzdk/Websocket (MIT)
 - https://github.com/develephant/corona-html5-websockets-plugin (Apache-2.0)
 - https://github.com/acmacalister/jetfire (Apache-2.0)


## Links 

- Form post: https://forums.solar2d.com/t/i-created-a-websocket-server-plug-in/351648/3
