//
//  Client.h
//  plugin_library
//
//  Created by Joseph Hinkle on 6/19/20.
//

#import <Foundation/Foundation.h>
#import "SOXWebSocket.h"
#include <CoronaLua.h>
#include <CoronaMacros.h>

NS_ASSUME_NONNULL_BEGIN

CORONA_EXPORT CoronaLuaRef client_fListener;
CORONA_EXPORT lua_State *client_L;
CORONA_EXPORT char client_kEvent[];

@interface Client : NSObject <SOXWebSocketDelegate>

@end

NS_ASSUME_NONNULL_END
