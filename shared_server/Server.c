//
//  Server.c
//  plugin_library
//
//  Created by Joseph Hinkle on 6/17/20.
//

#include "Server.h"
#include <CoronaLua.h>
#include <CoronaMacros.h>
#include "Websocket.h"
#include <signal.h>
#include <unistd.h>
#include "Datastructures.h"
#include <dispatch/dispatch.h>

CoronaLuaRef server_fListener;
lua_State *server_L = NULL;
char kEvent[] = "pluginsolarwebsockets";


int isLocked = 0;
void server_startServer(int port) {
    if (isLocked == 0) {
        isLocked = 1;
        sigint_handler(SIGINT);
        sleep(1);
        isLocked = 0;
        socket_main(port);
    }


}

void server_killServer() {
    sigint_handler(SIGINT);
}

void buildClientList(ws_list *l) {
    lua_createtable( server_L, 0, 0 );  /* ==> stack: ..., {} */
    
    // loop through clients to create a lua table
    int i = 1; // index starts at 1 for lua
    if (l != NULL) {
        ws_client *p;
        p = l->first;
        while (p != NULL) {
            // do something with client
            lua_pushinteger( server_L, i ); /* ==> stack: ..., {}, "b" */
            lua_createtable( server_L, 0, 0 );  /* ==> stack: ..., {} */
            lua_pushstring( server_L, "clientId" ); /* ==> stack: ..., {}, "b" */
            lua_pushinteger( server_L, p->socket_id ); /* ==> stack: ..., {}, 1, "hello" */
            lua_settable( server_L, -3 ); /* ==> stack: ..., {} */
            lua_pushstring( server_L, "clientIp" ); /* ==> stack: ..., {}, "b" */
            lua_pushstring( server_L, p->client_ip ); /* ==> stack: ..., {}, 1, "hello" */
            lua_settable( server_L, -3 ); /* ==> stack: ..., {} */
            lua_settable( server_L, -3 ); /* ==> stack: ..., {} */
            i++;
            p = p->next;
        };
    }
    
    // save to a table/array called clients
    lua_setfield( server_L, -2, "clients" ); /* ==> stack: ... */
}

void server_onJoin(ws_list *l, char *joinerIp, int joinerId) {
    if ((server_fListener != NULL) && (server_L != NULL)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CoronaLuaNewEvent( server_L, kEvent );
            lua_pushstring( server_L, "join" );
            lua_setfield( server_L, -2, "name" );
            
            buildClientList(l);
            
            lua_pushinteger( server_L, joinerId );
            lua_setfield( server_L, -2, "clientId" );

            lua_pushstring( server_L, joinerIp );
            lua_setfield( server_L, -2, "clientIp" );
            
            // Dispatch event to library's listener
            CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
        });
    }
}

void server_onLeave(ws_list *l, char *leaverIp, int leaveId) {
    if ((server_fListener != NULL) && (server_L != NULL)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CoronaLuaNewEvent( server_L, kEvent );
            lua_pushstring( server_L, "leave" );
            lua_setfield( server_L, -2, "name" );
            
            buildClientList(l);

            lua_pushinteger( server_L, leaveId );
            lua_setfield( server_L, -2, "clientId" );

            lua_pushstring( server_L, leaverIp );
            lua_setfield( server_L, -2, "clientIp" );
            
            // Dispatch event to library's listener
            CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
            
            // free memory
            free(leaverIp);
        });
    }
}

void server_onMessage(ws_client *n, char *message) {
    if ((server_fListener != NULL) && (server_L != NULL)) {
        // make a copy of this string, because it will be removed from memory
        const size_t messageLen = strlen(message) + 1;
        char * messageCopy = malloc(messageLen);
        strncpy(messageCopy, message, messageLen);
        
        // send event on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            CoronaLuaNewEvent( server_L, kEvent );
            lua_pushstring( server_L, "message" );
            lua_setfield( server_L, -2, "name" );

            lua_pushinteger( server_L, n->socket_id );
            lua_setfield( server_L, -2, "clientId" );

            lua_pushstring( server_L, n->client_ip );
            lua_setfield( server_L, -2, "clientIp" );

            lua_pushstring( server_L, messageCopy );
            lua_setfield( server_L, -2, "message" );

            // Dispatch event to library's listener
            CoronaLuaDispatchEvent( server_L, server_fListener, 0 );
            
            // free memory
            free(messageCopy);
        });
    }
}

void server_send(int clientId, const char *message) {
    sendMessageToClient(clientId, message);
}

void server_sendAll(const char *message) {
    sendMessageToAll(message);
}
