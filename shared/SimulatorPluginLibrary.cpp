// ----------------------------------------------------------------------------
// 
// SimulatorPluginLibrary.cpp
// 
// ----------------------------------------------------------------------------

#include "SimulatorPluginLibrary.h"

#include <CoronaAssert.h>
#include <CoronaLibrary.h>

// ----------------------------------------------------------------------------

// This corresponds to the name of the Lua file (simulator_plugin_library.lua)
// where the prefix 'CoronaPluginLuaLoad' is prepended.
CORONA_EXPORT int CoronaPluginLuaLoad_simulator_plugin_library( lua_State * );

// ----------------------------------------------------------------------------

CORONA_EXPORT
int luaopen_plugin_library( lua_State *L )
{
	using namespace Corona;

	lua_CFunction factory = Corona::Lua::Open< CoronaPluginLuaLoad_simulator_plugin_library >;
	int result = CoronaLibraryNewWithFactory( L, factory, NULL, NULL );

	return result;
}

// ----------------------------------------------------------------------------
