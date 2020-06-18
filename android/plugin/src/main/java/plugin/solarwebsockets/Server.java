package plugin.solarwebsockets;
/*
 * Copyright (c) 2010-2020 Nathan Rajlich
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 */

import com.ansca.corona.CoronaEnvironment;
import com.ansca.corona.CoronaLua;
import com.ansca.corona.CoronaRuntime;
import com.ansca.corona.CoronaRuntimeTask;
import com.naef.jnlua.LuaState;

import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collection;

import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;


/**
 * A simple WebSocketServer implementation. Keeps track of a "chatroom".
 */
public class Server extends WebSocketServer {
    public ArrayList<IdentifiableClient> clients = new ArrayList<IdentifiableClient>();
    public Server(int port ) {
        super( new InetSocketAddress( port ) );
    }

    @Override
    public void onOpen( WebSocket conn, ClientHandshake handshake ) {
        System.out.println( conn.getRemoteSocketAddress().getAddress().getHostAddress() + " entered the room!" );
        clients.add(new IdentifiableClient(conn));
    }

    @Override
    public void onClose( WebSocket conn, int code, String reason, boolean remote ) {
        System.out.println( conn + " has left the room!" );
        for (int i = 0; i < clients.size(); i++) {
            if (clients.get(i).id == conn.getRemoteSocketAddress().getPort()) {
                clients.remove(i);
                break;
            }
        }
    }

    @Override
    public void onMessage(final WebSocket conn, final String message ) {
//        broadcast( message );
        System.out.println( conn + ": " + message );
        CoronaEnvironment.getCoronaActivity().getRuntimeTaskDispatcher().send(new CoronaRuntimeTask() {
            @Override
            public void executeUsing(CoronaRuntime runtime) {
                LuaState L = runtime.getLuaState();

                CoronaLua.newEvent( L, LuaLoader.EVENT_NAME );

                L.pushString("message");
                L.setField(-2, "name");


                L.pushInteger(conn.getRemoteSocketAddress().getPort());
                L.setField(-2, "clientId");


                L.pushString(conn.getRemoteSocketAddress().getAddress().getHostAddress());
                L.setField(-2, "clientIp");


                L.pushString(message);
                L.setField(-2, "message");

                try {
                    CoronaLua.dispatchEvent( L, LuaLoader.fListener, 0 );
                } catch (Exception ignored) {
                }
            }
        } );
    }
    @Override
    public void onMessage( WebSocket conn, ByteBuffer message ) {
        // not supported yet...just convert it to a string and move on
        this.onMessage(conn,message.toString());
    }


    public static Server start( Integer port ) {
        if (port == null ) {
            port = 4567;
        }
        Server s = new Server( port );
        s.start();
        System.out.println( "ChatServer started on port: " + s.getPort() );

        return s;
    }
    @Override
    public void onError( WebSocket conn, Exception ex ) {
        ex.printStackTrace();
        if( conn != null ) {
            // some errors like port binding failed may not be assignable to a specific websocket
        }
    }

    @Override
    public void onStart() {
        System.out.println("Server started!");
        setConnectionLostTimeout(0);
        setConnectionLostTimeout(100);
    }

}