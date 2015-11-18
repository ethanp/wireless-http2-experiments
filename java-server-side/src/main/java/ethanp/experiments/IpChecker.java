package ethanp.experiments;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.Socket;
import java.net.URL;

/**
 * Ethan Petuchowski 11/18/15
 */
class IpChecker {

    static final int FIRST_PORT = 12345;

    // http://stackoverflow.com/a/14541376/1959155
    public static String getIp() throws Exception {
        URL checkIp = new URL("http://checkip.amazonaws.com");
        try (BufferedReader in = new BufferedReader(new InputStreamReader(checkIp.openStream()))) {
            return in.readLine();
        }
    }

    static void testExternallyAvbl() {
        String ipv6Addr = null;
        try {
            ipv6Addr = IpChecker.getIp();
        }
        catch (Exception e) {
            System.err.println("Couldn't get external IP address");
            e.printStackTrace();
            System.exit(7);
        }
        System.out.println("External IP is : "+ipv6Addr);
        for (int i = 0; i < 5; i++) {
            int port = FIRST_PORT+i;
            try (
                Socket socket = new Socket(ipv6Addr, port);
                InputStream is = socket.getInputStream()
            ) {
                System.out.printf("rcvd: %d %d %d from %d\n", is.read(), is.read(), is.read(), port);
            }
            catch (IOException e) {
                System.err.println("couldn't connect to port "+port+" via external IP address");
                e.printStackTrace();
                System.exit(6);
            }
        }
        System.out.println("external connection was successful on all 5 ports");
    }
}
