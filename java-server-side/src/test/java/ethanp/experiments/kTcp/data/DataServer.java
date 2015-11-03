package ethanp.experiments.kTcp.data;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.text.SimpleDateFormat;
import java.util.Calendar;

/**
 * Ethan Petuchowski 11/2/15
 *
 * This thing just excepts JSON blobs of data as UTF-8 strings,
 * and timestamps them then dumps them out to an appropriate
 * location in the file system.
 *
 * TODO it currently just dumps to "dataFile.txt"
 */
public class DataServer implements Runnable {

    static DataServer _instance;
    static Thread _instanceThread;

    SimpleDateFormat dateFormat = new SimpleDateFormat("MM:dd_HH:mm:ss");
    ServerSocket serverSocket;
    Calendar calendar = Calendar.getInstance();

    private DataServer(int port) {
        try {
            serverSocket = new ServerSocket(port);
        }
        catch (IOException e) {
            e.printStackTrace();
            System.exit(6);
        }
    }

    public static DataServer start() {
        if (_instance == null) {
            _instance = new DataServer(12345);
            _instanceThread = new Thread(_instance);
            _instanceThread.start();
        }
        return _instance;
    }

    @Override public void run() {
        System.out.println("data server listening on port 12345");
        //noinspection InfiniteLoopStatement
        while (true) {
            try (Socket dataSocket = serverSocket.accept()) {
                try (BufferedReader is =
                    new BufferedReader(
                        new InputStreamReader(
                            dataSocket.getInputStream())))
                {
                    String jsonData = is.readLine();
                    if (jsonData.equals("stop")) return;

                    String timeStamp = dateFormat.format(calendar.getTime());
                    String timestampedData =
                        "{ \"timestamp\": \""+timeStamp+"\", \"data\":"+jsonData+" }";

                    System.out.println("received: "+timestampedData);
                    File outFile = new File("dataFile.txt");
                    try (FileOutputStream appendStream = new FileOutputStream(outFile, true)) {
                        PrintStream flushingWriter = new PrintStream(appendStream, true);
                        flushingWriter.println(timestampedData);
                    }
                }
            }
            catch (IOException e) {
                e.printStackTrace();
                System.exit(7);
            }
        }
    }

    public static void main(String[] args) {
        DataServer.start();
    }
}
