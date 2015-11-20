package ethanp.experiments;


import org.apache.commons.lang3.RandomUtils;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Ethan Petuchowski 11/2/15
 * <p/>
 * Setup 5 concurrent TCP servers on ports [12345, 12345+k)
 */
public class KTCPs {

    final ExecutorService threadPool;
    final int firstPort;
    final int numServers;
    final int bytesSentPerConn;

    public KTCPs(int numServers, int firstPort, int bytesSentPerConn) {
        assert numServers > 0 : "require at least one concurrent connection";
        assert bytesSentPerConn > 0 : "must send > 0 bytes";

        this.numServers = numServers;
        this.firstPort = firstPort;
        this.bytesSentPerConn = bytesSentPerConn;

        this.threadPool = Executors.newFixedThreadPool(numServers);
        for (int i = 0; i < numServers; i++) {
            NonPersistent np = new NonPersistent(firstPort+i, bytesSentPerConn);
            threadPool.execute(np);
        }
    }


    /**
     * start a server wait for a client to connect on connect, send data immediately time how long
     * this takes (server side time taken)
     */
    static class NonPersistent extends Thread {

        int numBytes;
        int port;

        NonPersistent(int port, int numBytes) {
            this.port = port;
            this.numBytes = numBytes;
        }

        /**
         * we enforce "crash failure semantics" so that there are no little errors that screw up my
         * data without much notification to me.
         */
        @Override public void run() {
            try (ServerSocket serverSocket = new ServerSocket(port)) {
                System.out.println("serving up to "+numBytes+" bytes at port "+port);
                while (!this.isInterrupted()) {

                    // generate the byte buffer before the client even connects
                    byte[] bytes = RandomUtils.nextBytes(numBytes);

                    Socket clientSocket = serverSocket.accept();
                    long start = System.nanoTime();
                    try (OutputStream os = clientSocket.getOutputStream()) {
                        os.write(bytes);
                    }
                    catch (SocketException e) {
                        System.out.println("xmt on port "+port+" ended");
                    }
                    catch (IOException e) {
                        e.printStackTrace();
                        System.exit(3);
                    }
                    long end = System.nanoTime();
                    System.out.println("server at "+port+" took "+(end-start)+" ns");
                }
                System.out.println("server at "+port+" was interrupted");
            }
            catch (IOException e) {
                e.printStackTrace();
                System.exit(2);
            }
        }
    }

    public static void main(String[] args) throws InterruptedException {
        final int FOUR_MEGS = 1 << 22;
        KTCPs a = new KTCPsBuilder()
            .servers(5)
            .firstPort(IpChecker.FIRST_PORT)
            .bytesPerConn(FOUR_MEGS)
            .build();

        IpChecker.testExternallyAvbl();
//        Thread.sleep(30000);
//        a.cancel();
    }

}
