//
//  PluginLibrary.h
//  TemplateApp
//

#ifndef _PluginLibrary_H__
#define _PluginLibrary_H__

#include <CoronaLua.h>
#include <CoronaMacros.h>

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
// where the '.' is replaced with '_'
CORONA_EXPORT int luaopen_plugin_library( lua_State *L );

#endif // _PluginLibrary_H__
