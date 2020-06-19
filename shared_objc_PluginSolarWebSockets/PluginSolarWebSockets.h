//
//  PluginSolarWebSockets.h
//  TemplateApp
//
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef _PluginSolarWebSockets_H__
#define _PluginSolarWebSockets_H__

#include <CoronaLua.h>
#include <CoronaMacros.h>

// This corresponds to the name of the library, e.g. [Lua] require "plugin.solarwebsockets"
// where the '.' is replaced with '_'
CORONA_EXPORT int luaopen_plugin_solarwebsockets( lua_State *L );

#endif // _PluginSolarWebSockets_H__
