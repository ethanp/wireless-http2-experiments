package ethanp.experiments;

import org.eclipse.jetty.client.HttpClient;
import org.eclipse.jetty.client.api.Result;
import org.eclipse.jetty.client.util.BufferingResponseListener;
import org.eclipse.jetty.http2.client.HTTP2Client;
import org.eclipse.jetty.http2.client.http.HttpClientTransportOverHTTP2;
import org.eclipse.jetty.util.ssl.SslContextFactory;

import java.util.Arrays;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Ethan Petuchowski 11/21/15
 * <p/>
 * This is modified from https://github.com/oneam/test-http2-jetty/tree/master/src/main/java/test/jetty
 */
public class H2ClientTry2 {

    static boolean failed = false;

    public static void main(String[] args) throws Exception {
        boolean http2 = true;
        String targetUri = "https://localhost:8443/index.html";

        HttpClient client;

        //noinspection ConstantConditions
        if (http2) {
            System.out.println("Client using HTTP/2 protocol");
            HTTP2Client http2Client = new HTTP2Client();
            HttpClientTransportOverHTTP2 clientTransport = new HttpClientTransportOverHTTP2(http2Client);

            // ECP: I had to add the sslContextFactory bc otw I
            SslContextFactory sslContextFactory = new SslContextFactory(true);
            client = new HttpClient(clientTransport, sslContextFactory);
        }
        else {
            System.out.println("Client using HTTP/1.1 protocol");
            client = new HttpClient();
        }

        client.start();

        Metrics metrics = new Metrics();
        metrics.start();

        // Limits the number of concurrent requests
        Semaphore throttle = new Semaphore(200);

        while (!failed) {
            throttle.acquire();
            long start = System.nanoTime();
            metrics.incrementActiveRequests();
            client.newRequest(targetUri)
                .send(new BufferingResponseListener() {

                    @Override
                    public void onComplete(Result result) {
                        try {
                            if (result.isFailed()) {
                                throw result.getFailure();
                            }

                            System.out.println("VERSION: "+result.getResponse().getVersion());
                            String content = getContentAsString();
                            assert (content.equals("<h1>Hello World</h1>"));

                            long end = System.nanoTime();
                            metrics.recordLatency(end-start);
                            metrics.decrementActiveRequests();

                            throttle.release();
                        }
                        catch (Throwable e) {
                            e.printStackTrace();
                        }
                    }
                });
        }

    }

    static class Metrics {

        AtomicInteger activeRequestCounter = new AtomicInteger();

        final Object latencySync = new Object();
        int latencyStorageCapacity = 10000;
        long[] latencyStorage = new long[10000];
        int latencyCounter = 0;

        AtomicLong lastUpdateTimer = new AtomicLong();
        Timer displayTimer = new Timer();
        TimerTask timerTask = new TimerTask() {

            @Override
            public void run() {
                displayUpdate();
            }
        };

        public void start() {
            long now = System.nanoTime();
            lastUpdateTimer.set(now);
            displayTimer.schedule(timerTask, 1000, 1000);
        }

        public void stop() {
            displayTimer.cancel();
        }

        public void incrementActiveRequests() {
            activeRequestCounter.getAndIncrement();
        }

        public void decrementActiveRequests() {
            activeRequestCounter.getAndDecrement();
        }

        public void recordLatency(long latencyInNanos) {
            synchronized (latencySync) {
                if (latencyCounter >= latencyStorageCapacity) {
                    latencyStorageCapacity *= 2;
                    latencyStorage = Arrays.copyOf(latencyStorage, latencyStorageCapacity);
                }
                latencyStorage[latencyCounter] = latencyInNanos;
                latencyCounter++;
            }
        }

        private void displayUpdate() {
            long now = System.nanoTime();
            long lastUpdateTime = lastUpdateTimer.getAndSet(now);
            long activeRequests = activeRequestCounter.get();

            long[] latencies;
            int latencyCount;
            synchronized (latencySync) {
                latencyCount = latencyCounter;
                latencyCounter = 0;

                latencies = latencyStorage;
                latencyStorage = new long[latencyStorageCapacity];
            }
            Arrays.sort(latencies, 0, latencyCount);

            double timeInSeconds = (double) (now-lastUpdateTime)*1e-9;

            double latencyP50 = latencyCount == 0 ? 0 : (double) latencies[latencyCount/2]*1e-6;
            double latencyP90 = latencyCount == 0 ? 0 : (double) latencies[latencyCount*9/10]*1e-6;
            double responseRate = timeInSeconds == 0 ? 0 : (double) latencyCount/timeInSeconds;
            System.out
                .printf(
                    "Active Requests: %d, Response rate: %.0f/s, Latency: P50 %.3fms P90 %.3fms\n",
                    activeRequests,
                    responseRate,
                    latencyP50,
                    latencyP90);
        }
    }
}
