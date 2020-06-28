//-----------------------------------------------------------------------------
// Corona HTML5 Websockets Plugin
// (c)2018 C. Byerley (develephant)
//
// Modified by Joe under Apache License 2.0
// (c)2020 Joe Hinkle
//-----------------------------------------------------------------------------
window.plugin_solarwebsockets_js = {
  ONOPEN: 'OnOpen0',
  ONMESSAGE: 'OnMessage0',
  ONCLOSE: 'OnClose0',
  ONERROR: 'OnError0',

  connect: function(uri) {

    plugin_solarwebsockets_js.ws = new WebSocket(uri);

    plugin_solarwebsockets_js.ws.onopen = function() {
      plugin_solarwebsockets_js.dispatcher({type: plugin_solarwebsockets_js.ONOPEN});
    };

    plugin_solarwebsockets_js.ws.onclose = function(err) {
      plugin_solarwebsockets_js.dispatcher({type: plugin_solarwebsockets_js.ONCLOSE});
    };

    plugin_solarwebsockets_js.ws.onerror = function(err) {
      plugin_solarwebsockets_js.dispatcher({type: plugin_solarwebsockets_js.ONERROR, reason: err});
    };

    plugin_solarwebsockets_js.ws.onmessage = function(message) {
      plugin_solarwebsockets_js.dispatcher({type: plugin_solarwebsockets_js.ONMESSAGE, data: message.data});
    };

  },

  disconnect: function() {
    plugin_solarwebsockets_js.ws.close();
    plugin_solarwebsockets_js.ws = null;
    plugin_solarwebsockets_js.dispatcher({type: plugin_solarwebsockets_js.ONCLOSE});
  },

  send: function(data) {
    if (plugin_solarwebsockets_js.ws) {
      plugin_solarwebsockets_js.ws.send(data);
    }
  },

  addEventListener: function(listener) {
    plugin_solarwebsockets_js.dispatcher = LuaCreateFunction(listener);
  },

  removeEventListener: function() {
    LuaReleaseFunction(plugin_solarwebsockets_js.dispatcher);
    plugin_solarwebsockets_js.dispatcher = null;
  }
};