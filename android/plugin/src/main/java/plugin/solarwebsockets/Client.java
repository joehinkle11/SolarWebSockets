package plugin.solarwebsockets;


import com.ansca.corona.CoronaEnvironment;
import com.ansca.corona.CoronaLua;
import com.ansca.corona.CoronaRuntime;
import com.ansca.corona.CoronaRuntimeTask;
import com.naef.jnlua.LuaState;

import org.java_websocket.WebSocket;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.handshake.ServerHandshake;
import org.java_websocket.server.WebSocketServer;

import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Map;


public class Client extends WebSocketClient {

    public Client( URI serverURI ) {
        super( serverURI );
    }

    @Override
    public void onOpen( ServerHandshake handshakedata ) {
        send("Hello, it is me. Mario :)");
        System.out.println( "opened connection" );
        // if you plan to refuse connection based on ip or httpfields overload: onWebsocketHandshakeReceivedAsClient
        CoronaEnvironment.getCoronaActivity().getRuntimeTaskDispatcher().send(new CoronaRuntimeTask() {
            @Override
            public void executeUsing(CoronaRuntime runtime) {
                LuaState L = runtime.getLuaState();

                CoronaLua.newEvent( L, LuaLoader.EVENT_NAME );
                L.pushBoolean(true);
                L.setField(-2, "isClient");
                L.pushBoolean(false);
                L.setField(-2, "isServer");

                L.pushString("join");
                L.setField(-2, "name");

                try {
                    CoronaLua.dispatchEvent( L, LuaLoader.fListener, 0 );
                } catch (Exception ignored) {
                }
            }
        } );
    }

    @Override
    public void onMessage(final String message ) {
        System.out.println( "received: " + message );
        CoronaEnvironment.getCoronaActivity().getRuntimeTaskDispatcher().send(new CoronaRuntimeTask() {
            @Override
            public void executeUsing(CoronaRuntime runtime) {
                LuaState L = runtime.getLuaState();

                CoronaLua.newEvent( L, LuaLoader.EVENT_NAME );
                L.pushBoolean(true);
                L.setField(-2, "isClient");
                L.pushBoolean(false);
                L.setField(-2, "isServer");

                L.pushString("message");
                L.setField(-2, "name");


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
    public void onClose(final int code, final String reason, boolean remote ) {
        // The codecodes are documented in class org.java_websocket.framing.CloseFrame
        System.out.println( "Connection closed by " + ( remote ? "remote peer" : "us" ) + " Code: " + code + " Reason: " + reason );
        CoronaEnvironment.getCoronaActivity().getRuntimeTaskDispatcher().send(new CoronaRuntimeTask() {
        @Override
            public void executeUsing(CoronaRuntime runtime) {
                LuaState L = runtime.getLuaState();

                CoronaLua.newEvent( L, LuaLoader.EVENT_NAME );
                L.pushBoolean(true);
                L.setField(-2, "isClient");
                L.pushBoolean(false);
                L.setField(-2, "isServer");

                L.pushString(reason);
                L.setField(-2, "errorMessage");

                L.pushInteger(code);
                L.setField(-2, "errorCode");

                L.pushString("leave");
                L.setField(-2, "name");

                try {
                    CoronaLua.dispatchEvent( L, LuaLoader.fListener, 0 );
                } catch (Exception ignored) {
                }
            }
        } );
    }

    @Override
    public void onError( Exception ex ) {
        ex.printStackTrace();
        // if the error is fatal then onClose will be called additionally
    }

    public static Client connect( String url ) throws URISyntaxException {
        Client c = new Client( new URI( url )); // more about drafts here: http://github.com/TooTallNate/Java-WebSocket/wiki/Drafts
        c.connect();
        return c;
    }

}
//public class Client extends WebSocketClient {
//    public ArrayList<IdentifiableClient> clients = new ArrayList<IdentifiableClient>();
//    public Client(int port ) {
//        super( new InetSocketAddress( port ) );
//    }
//
//    @Override
//    public void onOpen( final WebSocket conn, ClientHandshake handshake ) {
//        System.out.println( conn.getRemoteSocketAddress().getAddress().getHostAddress() + " entered the room!" );
//        clients.add(new IdentifiableClient(conn));
//
//
//        final Client dis = this;
//        CoronaEnvironment.getCoronaActivity().getRuntimeTaskDispatcher().send(new CoronaRuntimeTask() {
//            @Override
//            public void executeUsing(CoronaRuntime runtime) {
//                LuaState L = runtime.getLuaState();
//
//                CoronaLua.newEvent( L, LuaLoader.EVENT_NAME );
//
//                L.pushString("join");
//                L.setField(-2, "name");
//
//                dis.buildClientList(L);
//
//                L.pushInteger(conn.getRemoteSocketAddress().getPort());
//                L.setField(-2, "clientId");
//
//
//                L.pushString(conn.getRemoteSocketAddress().getAddress().getHostAddress());
//                L.setField(-2, "clientIp");
//
//                try {
//                    CoronaLua.dispatchEvent( L, LuaLoader.fListener, 0 );
//                } catch (Exception ignored) {
//                }
//            }
//        } );
//    }
//
//    @Override
//    public void onClose( final WebSocket conn, int code, String reason, boolean remote ) {
//        System.out.println( conn + " has left the room!" );
//        for (int i = 0; i < clients.size(); i++) {
//            if (clients.get(i).id == conn.getRemoteSocketAddress().getPort()) {
//                clients.remove(i);
//                break;
//            }
//        }
//        final Integer clientId = conn.getRemoteSocketAddress().getPort();
//        final String clientIp = conn.getRemoteSocketAddress().getAddress().getHostAddress();
//        final Client dis = this;

//    }
//
//    @Override
//    public void onMessage(final WebSocket conn, final String message ) {
////        broadcast( message );
//        System.out.println( conn + ": " + message );
//        CoronaEnvironment.getCoronaActivity().getRuntimeTaskDispatcher().send(new CoronaRuntimeTask() {
//            @Override
//            public void executeUsing(CoronaRuntime runtime) {
//                LuaState L = runtime.getLuaState();
//
//                CoronaLua.newEvent( L, LuaLoader.EVENT_NAME );
//
//                L.pushString("message");
//                L.setField(-2, "name");
//
//
//                L.pushInteger(conn.getRemoteSocketAddress().getPort());
//                L.setField(-2, "clientId");
//
//
//                L.pushString(conn.getRemoteSocketAddress().getAddress().getHostAddress());
//                L.setField(-2, "clientIp");
//
//
//                L.pushString(message);
//                L.setField(-2, "message");
//
//                try {
//                    CoronaLua.dispatchEvent( L, LuaLoader.fListener, 0 );
//                } catch (Exception ignored) {
//                }
//            }
//        } );
//    }
//    @Override
//    public void onMessage( WebSocket conn, ByteBuffer message ) {
//        // not supported yet...just convert it to a string and move on
//        this.onMessage(conn,message.toString());
//    }
//
//
//    public static Client start(Integer port ) {
//        if (port == null ) {
//            port = 4567;
//        }
//        Client s = new Client( port );
//        s.start();
//        System.out.println( "ChatServer started on port: " + s.getPort() );
//
//        return s;
//    }
//    @Override
//    public void onError( WebSocket conn, Exception ex ) {
//        ex.printStackTrace();
//        if( conn != null ) {
//            // some errors like port binding failed may not be assignable to a specific websocket
//        }
//    }
//
//    @Override
//    public void onStart() {
//        System.out.println("Server started!");
//        setConnectionLostTimeout(0);
//        setConnectionLostTimeout(100);
//    }
//
//    private void buildClientList(LuaState L) {
//        L.newTable(); /* ==> stack: ..., {} */
//
//        // loop through clients to create a lua table
//        for (int j = 0; j < clients.size(); j++) {
//            IdentifiableClient client = clients.get(j);
//            L.pushInteger(j+1); // index starts at 1 for lua, so add 1 from java index
//            L.newTable(); /* ==> stack: ..., {} */
//            L.pushString("clientId");  /* ==> stack: ..., {}, "b" */
//            L.pushInteger(client.id);  /* ==> stack: ..., {}, 1, "hello" */
//            L.setTable(-3); /* ==> stack: ..., {} */
//            L.pushString("clientIp"); /* ==> stack: ..., {}, "b" */
//            L.pushString(client.ip); /* ==> stack: ..., {}, 1, "hello" */
//            L.setTable(-3); /* ==> stack: ..., {} */
//            L.setTable(-3); /* ==> stack: ..., {} */
//        }
//
//        // save to a table/array called clients
//        L.setField(-2, "clients");  /* ==> stack: ... */
//    }

