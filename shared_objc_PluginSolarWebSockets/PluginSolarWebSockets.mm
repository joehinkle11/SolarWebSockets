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
#include "Jetfire.h"
//#include "Client.h"
//// Define variable or field for socket handle
JFRWebSocket *client_socket = NULL;
//Client *client = [[Client alloc] init];


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


// [Lua] library.connect( url )
int
PluginSolarWebSockets::connect( lua_State *L )
{
    
    const char *url = lua_tostring( L, 1 );
    if ( !url )
    {
        return 0;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        client_socket = [[JFRWebSocket alloc] initWithURL:[NSURL URLWithString: @(url)] protocols:@[]];
//        protocols:@[@"chat",@"superchat"]];
        client_socket.onConnect = ^{
            NSLog(@"websocket is connected");
            dispatch_async(dispatch_get_main_queue(), ^{
                CoronaLuaNewEvent( server_L, PluginSolarWebSockets::kEvent );
                lua_pushboolean(server_L, true );
                lua_setfield( server_L, -2, "isClient" );
                lua_pushboolean(server_L, false );
                lua_setfield( server_L, -2, "isServer" );
        
                lua_pushstring( server_L, "join" );
                lua_setfield( server_L, -2, "name" );
        
                // Dispatch event to library's listener
                CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
            });
        };
        //websocketDidDisconnect
        client_socket.onDisconnect = ^(NSError *error) {
            NSLog(@"websocket is disconnected: %@",[error localizedDescription]);
            // forget about this socket object, due to next disconnection sequence
            client_socket = NULL;
        
            // send event on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                CoronaLuaNewEvent( server_L, PluginSolarWebSockets::kEvent );
                lua_pushboolean(server_L, true );
                lua_setfield( server_L, -2, "isClient" );
                lua_pushboolean(server_L, false );
                lua_setfield( server_L, -2, "isServer" );
        
                lua_pushstring( server_L, "leave" );
                lua_setfield( server_L, -2, "name" );
        
                lua_pushinteger( server_L, [error code] );
                lua_setfield( server_L, -2, "errorCode" );
                lua_pushstring( server_L, [[error localizedDescription] UTF8String] );
                lua_setfield( server_L, -2, "errorMessage" );
                // Dispatch event to library's listener
                CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
            });
        };
        //websocketDidReceiveMessage
        client_socket.onText = ^(NSString *text) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CoronaLuaNewEvent( server_L, PluginSolarWebSockets::kEvent );
                lua_pushboolean(server_L, true );
                lua_setfield( server_L, -2, "isClient" );
                lua_pushboolean(server_L, false );
                lua_setfield( server_L, -2, "isServer" );
        
                lua_pushstring( server_L, "message" );
                lua_setfield( server_L, -2, "name" );
        
                lua_pushstring( server_L, [text UTF8String] );
                lua_setfield( server_L, -2, "message" );
                // Dispatch event to library's listener
                CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
            });
        };
        //websocketDidReceiveData
        client_socket.onData = ^(NSData *data) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 CoronaLuaNewEvent( server_L, PluginSolarWebSockets::kEvent );
                 lua_pushboolean(server_L, true );
                 lua_setfield( server_L, -2, "isClient" );
                 lua_pushboolean(server_L, false );
                 lua_setfield( server_L, -2, "isServer" );
         
                 lua_pushstring( server_L, "message" );
                 lua_setfield( server_L, -2, "name" );
         
                 lua_pushstring( server_L, [data UTF8String] );
                 lua_setfield( server_L, -2, "message" );
                 // Dispatch event to library's listener
                 CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
             });
        };
        [client_socket connect];
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
            [client_socket writeString:@(message)];
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
            [client_socket disconnect];
            client_socket = NULL;
        }
    });
    return 0;
}

// ----------------------------------------------------------------------------

CORONA_EXPORT int luaopen_plugin_solarwebsockets( lua_State *L )
{
	return PluginSolarWebSockets::Open( L );
}
