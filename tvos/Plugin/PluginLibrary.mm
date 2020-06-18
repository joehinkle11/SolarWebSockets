//
//  PluginLibrary.mm
//  TemplateApp
//

#import "PluginLibrary.h"
#import <UIKit/UIKit.h>
#include <CoronaCards/CoronaRuntime.h>

// ----------------------------------------------------------------------------

class PluginLibrary
{
	public:
		typedef PluginLibrary Self;

	public:
		static const char kName[];
		static const char kEvent[];

	protected:
		PluginLibrary();

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
		static int init( lua_State *L );
		static int show( lua_State *L );

	private:
		CoronaLuaRef fListener;
};

// ----------------------------------------------------------------------------

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
const char PluginLibrary::kName[] = "plugin.library";

// This corresponds to the event name, e.g. [Lua] event.name
const char PluginLibrary::kEvent[] = "pluginlibraryevent";

PluginLibrary::PluginLibrary()
:	fListener( NULL )
{
}

bool
PluginLibrary::Initialize( CoronaLuaRef listener )
{
	// Can only initialize listener once
	bool result = ( NULL == fListener );

	if ( result )
	{
		fListener = listener;
	}

	return result;
}

int
PluginLibrary::Open( lua_State *L )
{
	// Register __gc callback
	const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
	CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );

	// Functions in library
	const luaL_Reg kVTable[] =
	{
		{ "init", init },
		{ "show", show },

		{ NULL, NULL }
	};

	// Set library as upvalue for each library function
	Self *library = new Self;
	CoronaLuaPushUserdata( L, library, kMetatableName );

	luaL_openlib( L, kName, kVTable, 1 ); // leave "library" on top of stack

	return 1;
}

int
PluginLibrary::Finalizer( lua_State *L )
{
	Self *library = (Self *)CoronaLuaToUserdata( L, 1 );

	CoronaLuaDeleteRef( L, library->GetListener() );

	delete library;

	return 0;
}

PluginLibrary *
PluginLibrary::ToLibrary( lua_State *L )
{
	// library is pushed as part of the closure
	Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
	return library;
}

// [Lua] library.init( listener )
int
PluginLibrary::init( lua_State *L )
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

// [Lua] library.show( word )
int
PluginLibrary::show( lua_State *L )
{
	const char *word = "<nil>";
	if(lua_isstring(L, 1))
	{
		word = lua_tostring(L, 1);
	}

	NSString *message = [NSString stringWithFormat:@"Hello from Corona Native for tvOS!\nYour word is: %s", word];

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Corona"
																   message:message
															preferredStyle:UIAlertControllerStyleAlert];


	UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * action) {}];

	[alert addAction:defaultAction];

	id<CoronaRuntime> runtime = (id<CoronaRuntime>)CoronaLuaGetContext( L );
	[runtime.appViewController presentViewController:alert animated:YES completion:nil];


	Self *library = ToLibrary( L );

	// Create event and add message to it
	CoronaLuaNewEvent( L, kEvent );
	lua_pushstring( L, [message UTF8String] );
	lua_setfield( L, -2, "message" );

	// Dispatch event to library's listener
	CoronaLuaDispatchEvent( L, library->GetListener(), 0 );

	return 0;
}

// ----------------------------------------------------------------------------

CORONA_EXPORT int luaopen_plugin_library( lua_State *L )
{
	return PluginLibrary::Open( L );
}
