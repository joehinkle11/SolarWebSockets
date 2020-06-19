//
//  Websocket.h
//  Plugin
//
//  Created by Joseph Hinkle on 6/16/20.
//

#ifndef Websocket_h
#define Websocket_h

//int socket_main(int argc, char *argv[]);
int socket_main(int port);
void sigint_handler(int sig);
void kickClient(int socket_id);
void sendMessageToClient(int socket_id, char *msg);
void sendMessageToAll(char *msg);

#endif /* Websocket_h */
