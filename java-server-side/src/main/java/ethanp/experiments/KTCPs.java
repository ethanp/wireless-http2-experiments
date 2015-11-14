package ethanp.experiments;


import org.apache.commons.lang3.RandomUtils;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Ethan Petuchowski 11/2/15
 *
 * The point of this class is to provide an interface to send a large file via "k" concurrent
 * TCP connections, for any given value of "k".
 *
 * NOTA BENE: the first time each of the constructed servers gets hit, it takes ~50x LONGER (!)
 *            to respond (pero por qué?)
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

    // TODO this doesn't work
    public void cancel() {
        System.out.println("KTCPs cancelled");
        // calls interrupt() on all the constituent threads
        threadPool.shutdownNow();
    }

    /**
     * start a server
     * wait for a client to connect
     * on connect, send data immediately
     * time how long this takes (server side time taken)
     */
    static class NonPersistent extends Thread {

        int numBytes;
        int port;

        NonPersistent(int port, int numBytes) {
            this.port = port;
            this.numBytes = numBytes;
        }

        /**
         * we enforce "crash failure semantics" so that there are no little
         * errors that screw up my data without much notification to me.
         */
        @Override public void run() {
            try (ServerSocket serverSocket = new ServerSocket(port)) {
                System.out.println("serving "+numBytes+" bytes at port "+port);
                while (!this.isInterrupted()) {
                    Socket clientSocket = serverSocket.accept();
                    long start = System.nanoTime();
                    try (OutputStream os = clientSocket.getOutputStream()) {
                        os.write(RandomUtils.nextBytes(numBytes));
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
            .firstPort(12345)
            .bytesPerConn(FOUR_MEGS)
            .build();

        Thread.sleep(30000);
        a.cancel();
    }
}
