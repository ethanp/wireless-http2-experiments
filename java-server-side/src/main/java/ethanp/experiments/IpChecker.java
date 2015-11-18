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
        URL whatismyip = new URL("http://checkip.amazonaws.com");
        BufferedReader in = null;
        try {
            in = new BufferedReader(new InputStreamReader(
                whatismyip.openStream()));
            return in.readLine();
        }
        finally {
            if (in != null) {
                try {
                    in.close();
                }
                catch (IOException e) {
                    e.printStackTrace();
                }
            }
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
        try {
            for (int i = 0; i < 5; i++) {
                int curPort = FIRST_PORT+i;
                Socket socket = new Socket(ipv6Addr, curPort);
                InputStream is = socket.getInputStream();
                System.out.println("rcvd: "+is.read()+" "+is.read()+" "+is.read()+" from "+curPort);
                is.close();
                socket.close();
            }
        }
        catch (IOException e) {
            System.err.println("couldn't connect via external IP address");
            e.printStackTrace();
            System.exit(6);
        }
        System.out.println("external connection was successful on all 5 ports");
    }
}
