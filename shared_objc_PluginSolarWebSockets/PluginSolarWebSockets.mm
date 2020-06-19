//
//  PluginSolarWebSockets.mm
//  TemplateApp
//
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PluginSolarWebSockets.h"

#include <CoronaRuntime.h>
#include <dispatch/dispatch.h>

// server stuff
#include "Server.h"

// client stuff
#include "SOXWebSocket.h"
#include "Client.h"
// Define variable or field for socket handle
SOXWebSocket *client_socket = NULL;
Client *client = [[Client alloc] init];


// ----------------------------------------------------------------------------

class PluginSolarWebSockets
{
	public:
		typedef PluginSolarWebSockets Self;

	public:
		static const char kName[];
		static const char kEvent[];

	protected:
		PluginSolarWebSockets();

	public:
		bool Initialize( CoronaLuaRef listener );

	public:
		CoronaLuaRef GetListener() const { return fListener; }

	public:
		static int Open( lua_State *L );

	protected:
		static int Finalizer( lua_State *L );

	public:
		static Self *ToLibrary( lua_State *L );

	public:
        // shared
		static int init( lua_State *L );
        // server
        static int startServer( lua_State *L );
        static int killServer( lua_State *L );
        static int kick( lua_State *L );
        static int sendClient( lua_State *L );
        static int sendAllClients( lua_State *L );
        // client
        static int connect( lua_State *L );
        static int sendServer( lua_State *L );
        static int disconnect( lua_State *L );

	private:
		CoronaLuaRef fListener;
};

// ----------------------------------------------------------------------------

// This corresponds to the name of the library, e.g. [Lua] require "plugin.solarwebsockets"
const char PluginSolarWebSockets::kName[] = "plugin.solarwebsockets";

// This corresponds to the event name, e.g. [Lua] event.name
const char PluginSolarWebSockets::kEvent[] = "pluginsolarwebsockets";

PluginSolarWebSockets::PluginSolarWebSockets()
:	fListener( NULL )
{
}

bool
PluginSolarWebSockets::Initialize( CoronaLuaRef listener )
{
	// Can only initialize listener once
	bool result = ( NULL == fListener );

	if ( result )
	{
		fListener = listener;
        server_fListener = fListener;
	}

	return result;
}

int
PluginSolarWebSockets::Open( lua_State *L )
{
	// Register __gc callback
	const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
	CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );

	// Functions in library
	const luaL_Reg kVTable[] =
	{
        // shared
		{ "init", init },
        // server
        { "startServer", startServer },
        { "killServer", killServer },
        { "kick", kick },
        { "sendClient", sendClient },
        { "sendAllClients", sendAllClients },
        // client
        { "connect", connect },
        { "sendServer", sendServer },
        { "disconnect", disconnect },

		{ NULL, NULL }
	};
    
    server_L = L;

	// Set library as upvalue for each library function
	Self *library = new Self;
	CoronaLuaPushUserdata( L, library, kMetatableName );

	luaL_openlib( L, kName, kVTable, 1 ); // leave "library" on top of stack

	return 1;
}

int
PluginSolarWebSockets::Finalizer( lua_State *L )
{
	Self *library = (Self *)CoronaLuaToUserdata( L, 1 );

	CoronaLuaDeleteRef( L, library->GetListener() );

	delete library;

	return 0;
}

PluginSolarWebSockets *
PluginSolarWebSockets::ToLibrary( lua_State *L )
{
	// library is pushed as part of the closure
	Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
	return library;
}

// [Lua] library.init( listener )
int
PluginSolarWebSockets::init( lua_State *L )
{
	int listenerIndex = 1;

	if ( CoronaLuaIsListener( L, listenerIndex, kEvent ) )
	{
		Self *library = ToLibrary( L );

		CoronaLuaRef listener = CoronaLuaNewRef( L, listenerIndex );
		library->Initialize( listener );
	}

	return 0;
}

// [Lua] library.startServer()
int
PluginSolarWebSockets::startServer( lua_State *L )
{
    int port = lua_tointeger( L, 1 );
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        server_startServer(port);
    });
    return 0;
}


// [Lua] library.killServer()
int
PluginSolarWebSockets::killServer( lua_State *L )
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        server_killServer();
    });
    return 0;
}

// [Lua] library.kick( clientId, message )
int
PluginSolarWebSockets::kick( lua_State *L )
{
    
    int clientId = lua_tointeger( L, 1 );
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        server_kick(clientId);
    });
    return 0;
}

// [Lua] library.send( clientId, message )
int
PluginSolarWebSockets::sendClient( lua_State *L )
{
    
    int clientId = lua_tointeger( L, 1 );
    const char *message = lua_tostring( L, 2 );
    if ( !message )
    {
        return 0;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        server_send(clientId, message);
    });
    return 0;
}

// [Lua] library.sendAllClients( message )
int
PluginSolarWebSockets::sendAllClients( lua_State *L )
{
    
    const char *message = lua_tostring( L, 1 );
    if ( !message )
    {
        return 0;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        server_sendAll(message);
    });
    return 0;
}


//
// client callbacks
//
// callback trigered on socket disconnected with/without error
//static void on_client_socket_disconnected(rws_socket socket) {
//    // process error
//    rws_error error = rws_socket_get_error(socket);
//    int errorCode = -1;
//    char *errorMessage = NULL;
//    if (error) {
//        printf("\nSocket disconnect with code, error: %i, %s", rws_error_get_code(error), rws_error_get_description(error));
//        errorCode = rws_error_get_code(error);
//        const char *errorMessageTmp = rws_error_get_description(error);
//        const size_t messageLen = strlen(errorMessageTmp) + 1;
//        errorMessage = (char*)calloc(messageLen, sizeof(char));
//        strncpy(errorMessage, errorMessageTmp, messageLen);
//    }
//    // forget about this socket object, due to next disconnection sequence
//    client_socket = NULL;
//
//    // send event on main thread
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CoronaLuaNewEvent( server_L, PluginSolarWebSockets::kEvent );
//        lua_pushboolean(server_L, true );
//        lua_setfield( server_L, -2, "isClient" );
//        lua_pushboolean(server_L, false );
//        lua_setfield( server_L, -2, "isServer" );
//
//        lua_pushstring( server_L, "leave" );
//        lua_setfield( server_L, -2, "name" );
//
//        if (errorCode != -1) {
//            lua_pushinteger( server_L, errorCode );
//            lua_setfield( server_L, -2, "errorCode" );
//        }
//        if (errorMessage != NULL) {
//            lua_pushstring( server_L, errorMessage );
//            lua_setfield( server_L, -2, "errorMessage" );
//        }
//        // Dispatch event to library's listener
//        CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
//
//        // free memory
//        free(errorMessage);
//    });
//}
//// callback trigered on socket connected and handshake done
//static void on_client_socket_connected(rws_socket socket) {
//    printf("\nSocket connected");
//    // send event on main thread
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CoronaLuaNewEvent( server_L, PluginSolarWebSockets::kEvent );
//        lua_pushboolean(server_L, true );
//        lua_setfield( server_L, -2, "isClient" );
//        lua_pushboolean(server_L, false );
//        lua_setfield( server_L, -2, "isServer" );
//
//        lua_pushstring( server_L, "join" );
//        lua_setfield( server_L, -2, "name" );
//
//        // Dispatch event to library's listener
//        CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
//    });
//}




// [Lua] library.connect( scheme, host, port, path )
int
PluginSolarWebSockets::connect( lua_State *L )
{
    
    const char *scheme = lua_tostring( L, 1 );
    const char *host = lua_tostring( L, 2 );
    const int port = lua_tointeger( L, 3 );
    const char *path = lua_tostring( L, 4 );
    if ( !scheme || !host || !path )
    {
        return 0;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        
        client_socket = [[SOXWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"ws://echo.websocket.org"]]];
        [client_socket setDelegate:client];
        // disconnect if already exists
//        if (client_socket != NULL) {
//            rws_socket_disconnect_and_release(client_socket);
//            client_socket = NULL;
//        }
//        
//        //create socket object
//        client_socket = rws_socket_create();
//        
//        
//        // Set socket callbacks
//        rws_socket_set_on_disconnected(client_socket, &on_client_socket_disconnected); // required
//        rws_socket_set_on_connected(client_socket, &on_client_socket_connected);
//        rws_socket_set_on_received_text(client_socket, &on_client_socket_received_text);
//        
//        // connect
//        rws_socket_set_scheme(client_socket, scheme);
//        rws_socket_set_host(client_socket, host);
//        rws_socket_set_port(client_socket, port);
//        rws_socket_set_path(client_socket, path);
//        rws_socket_connect(client_socket);
    });
    return 0;
}

// [Lua] library.sendServer( message )
int
PluginSolarWebSockets::sendServer( lua_State *L )
{
    
    const char *message = lua_tostring( L, 1 );
    if ( !message )
    {
        return 0;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        if (client_socket != NULL) {
            NSString *name = @(message);
            id data = name;
            [client_socket send:data];
        }
    });
    return 0;
}


// [Lua] library.disconnect()
int
PluginSolarWebSockets::disconnect( lua_State *L )
{
    
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        if (client_socket != NULL) {
//            rws_socket_disconnect_and_release(client_socket);
//            client_socket = NULL;
        }
    });
    return 0;
}

// ----------------------------------------------------------------------------

CORONA_EXPORT int luaopen_plugin_solarwebsockets( lua_State *L )
{
	return PluginSolarWebSockets::Open( L );
}
