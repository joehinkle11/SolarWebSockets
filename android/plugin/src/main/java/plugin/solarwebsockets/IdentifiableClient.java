package plugin.solarwebsockets;

import org.java_websocket.WebSocket;

public class IdentifiableClient {
    public WebSocket conn;
    public Integer id;
    public String ip;

    public IdentifiableClient(WebSocket conn) {
        this.conn = conn;
        id = conn.getRemoteSocketAddress().getPort();
        ip = conn.getRemoteSocketAddress().getAddress().getHostAddress();
    }
}
