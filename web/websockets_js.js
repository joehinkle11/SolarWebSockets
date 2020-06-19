//-----------------------------------------------------------------------------
// Corona HTML5 Websockets Plugin
// (c)2018 C. Byerley (develephant)
//-----------------------------------------------------------------------------
window.websockets_js = {
  ONOPEN: 'OnOpen0',
  ONMESSAGE: 'OnMessage0',
  ONCLOSE: 'OnClose0',
  ONERROR: 'OnError0',

  connect: function(uri) {

    websockets_js.ws = new WebSocket(uri);

    websockets_js.ws.onopen = function() {
      websockets_js.dispatcher({type: websockets_js.ONOPEN});
    };

    websockets_js.ws.onclose = function(err) {
      websockets_js.dispatcher({type: websockets_js.ONCLOSE});
    };

    websockets_js.ws.onerror = function(err) {
      websockets_js.dispatcher({type: websockets_js.ONERROR, reason: err});
    };

    websockets_js.ws.onmessage = function(message) {
      websockets_js.dispatcher({type: websockets_js.ONMESSAGE, data: message.data});
    };

  },

  disconnect: function() {
    websockets_js.ws.close();
    websockets_js.ws = null;
    websockets_js.dispatcher({type: websockets_js.ONCLOSE});
  },

  send: function(data) {
    if (websockets_js.ws) {
      websockets_js.ws.send(data);
    }
  },

  addEventListener: function(listener) {
    websockets_js.dispatcher = LuaCreateFunction(listener);
  },

  removeEventListener: function() {
    LuaReleaseFunction(websockets_js.dispatcher);
    websockets_js.dispatcher = null;
  }
};