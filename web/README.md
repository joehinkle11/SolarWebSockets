# Corona HTML5 WebSockets Plugin

__WebSockets for Corona HTML5 builds.__

_Looking for a WebSockets plugin that supports device builds? __[Click here](https://marketplace.coronalabs.com/corona-plugins/websockets)__._

## Install

Add __websockets_js.js__ and __websockets.lua__ to the ___root___ of your project.

## Require

```lua
local ws = require("websockets")
```

## Setup

```lua
local function WsListener(event)
  if event.type == ws.ONOPEN then
    print('connected')
  elseif event.type == ws.ONMESSAGE then
    print('message', event.data)
  elseif event.type == ws.ONCLOSE then
    print('disconnected')
  elseif event.type == ws.ONERROR then
    print('error', event.reason)
  end
end

ws.addEventListener(WsListener)
ws.connect('ws://<websocket-url>')

--OR (for secure websockets)
--ws.connect('wss://<websocket-url>')
```

## API

### connect

Connect the WebSocket object to a WebSocket endpoint.

```lua
ws.connect( ws_url )
```

_Make sure your WebSocket event handler is set up before calling this method. See __[addEventListener](#addeventlistener)__._

### disconnect

Disconnect the WebSocket object from the endpoint.

```lua
ws.disconnect()
```

### send

Send a message over the WebSocket connection.

```lua
ws.send( data )
```

__Example__

```lua
ws.send("Hello WebSocket server")
```

### addEventListener

Add the WebSocket event handler. See __[Setup](#setup)__ above.

```lua
ws.addEventListener( WsListener )
```

### removeEventListener

Remove the WebSocket event handler.

```lua
ws.removeEventListener()
```

## Event Constants

The following event constants are used in the WebSocket event listener. Some events will include addtional data that can be accessed from the `event` object. See also: __[addEventListener](#addeventlistener)__.

### ONOPEN

The WebSocket connection is open and ready.

```lua
ws.ONOPEN
```

__Event Keys__

_This event contains no event keys._

### ONMESSAGE

A WebSocket message has been received.

```lua
ws.ONMESSAGE
```

__Event Keys__

 - `data`

 __Example__

 ```lua
...

local function WsListener(event)
  if event.type == ws.ONMESSAGE then
    print(event.data) --> message data
  end
end

...
 ```

### ONCLOSE

The WebSocket connection has closed and is no longer available.

```lua
ws.ONCLOSE
```

__Event Keys__

_This event contains no event keys._

### ONERROR

A WebSocket error has occurred. This will generally close the connection.

```lua
ws.ONERROR
```

__Event Keys__

  - `reason`

__Example__

```lua
...

local function WsListener(event)
  if event.type == ws.ONERROR then
    print(event.reason) --> error reason
  end
end

...
```

## Echo Example

```lua
local ws = require("websockets")

local function WsListener(event)
  if event.type == ws.ONOPEN then
    print('connected')
    -- send a message
    ws.send("Hello")
  elseif event.type == ws.ONMESSAGE then
    print('message', event.data)
  elseif event.type == ws.ONCLOSE then
    print('disconnected')
  elseif event.type == ws.ONERROR then
    print('error', event.reason)
  end
end

--connection
ws.addEventListener(WsListener)
ws.connect('ws://demos.kaazing.com/echo')

--disconnection
timer.performWithDelay(5000, function()
  ws.disconnect()
  ws.removeEventListener(WsListener)
end)
```

---

&copy;2018 C. Byerley ([develephant](https://develephant.com))