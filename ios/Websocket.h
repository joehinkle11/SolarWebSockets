//
//  Websocket.h
//  Plugin
//
//  Created by Joseph Hinkle on 6/16/20.
//

#ifndef Websocket_h
#define Websocket_h

//int socket_main(int argc, char *argv[]);
int socket_main();
void sigint_handler(int sig);
void sendMessageToClient(int socket_id, char *msg);

#endif /* Websocket_h */
