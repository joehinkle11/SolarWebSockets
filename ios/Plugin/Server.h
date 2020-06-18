//
//  Server2.h
//  plugin_library
//
//  Created by Joseph Hinkle on 6/17/20.
//

#ifndef Server2_h
#define Server2_h

#include <stdio.h>
#include <CoronaLua.h>
#include <CoronaMacros.h>
#include "Datastructures.h"

CORONA_EXPORT CoronaLuaRef server_fListener;
CORONA_EXPORT lua_State *server_L;
CORONA_EXPORT int testttt234(void);
CORONA_EXPORT void server_startServer(void);
CORONA_EXPORT void server_killServer(void);
CORONA_EXPORT void server_send(int,const char*);

void server_onJoin(ws_list *l, char *joinerIp, int joinerId);
void server_onLeave(ws_list *l, char *leaverIp, int leaveId);
void server_onMessage(ws_client *n, char *message);

#endif /* Server2_h */
