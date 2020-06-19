//
//  Client.m
//  plugin_library
//
//  Created by Joseph Hinkle on 6/19/20.
//

#import "Client.h"
#import "SOXWebSocket.h"
#include <CoronaLua.h>

lua_State *client_L;
CoronaLuaRef client_fListener;
char client_kEvent[] = "pluginsolarwebsockets";

@implementation Client 

- (void)webSocket:(SOXWebSocket *)webSocket didReceiveMessage:(id)message { 
    // callback trigered on socket received text
    // make a copy of this string, because it will be removed from memory
    const size_t messageLen = strlen(message) + 1;
    char * messageCopy = (char*)calloc(messageLen, sizeof(char));
    strncpy(messageCopy, message, messageLen);
    // send event on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        CoronaLuaNewEvent( client_L, client_kEvent );
        lua_pushboolean(client_L, true );
        lua_setfield( client_L, -2, "isClient" );
        lua_pushboolean(client_L, false );
        lua_setfield( client_L, -2, "isServer" );

        lua_pushstring( client_L, "message" );
        lua_setfield( client_L, -2, "name" );

        lua_pushstring( client_L, messageCopy );
        lua_setfield( client_L, -2, "message" );

        // Dispatch event to library's listener
        CoronaLuaDispatchEvent( client_L, client_fListener, 0 );

        // free memory
        free(messageCopy);
    });
}

@end
