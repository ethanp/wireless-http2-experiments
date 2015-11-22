package ethanp.experiments;

import org.eclipse.jetty.client.HttpClient;
import org.eclipse.jetty.client.api.Result;
import org.eclipse.jetty.client.util.BufferingResponseListener;
import org.eclipse.jetty.http2.client.HTTP2Client;
import org.eclipse.jetty.http2.client.http.HttpClientTransportOverHTTP2;
import org.eclipse.jetty.util.ssl.SslContextFactory;

import java.util.Arrays;
import java.util.Vector;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
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

        String protocol = "https";
        String ipAddr   = "localhost";
        String port     = "8443";
        String path     = "index.html";

        String targetUri = String.format("%s://%s:%s/%s", protocol, ipAddr, port, path);

        HttpClient client;

        //noinspection ConstantConditions
        if (http2) {
            System.out.println("Client using HTTP/2 protocol");
            HTTP2Client http2Client = new HTTP2Client();
            client = new HttpClient(
                new HttpClientTransportOverHTTP2(http2Client),
                new SslContextFactory(true)
            );
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
                .send(new BufferingResponseListener(/* default 2MB buffer */) {

                    @Override
                    public void onComplete(Result result) {
                        try {
                            if (result.isFailed()) throw result.getFailure();

//                            String content = getContentAsString();
//                            System.out.println("VERSION: "+result.getResponse().getVersion());

                            long end = System.nanoTime();
                            metrics.recordLatency(end-start);
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

        /* In general, Java may employ efficient machine-level atomic instructions available
         * on contemporary processors to implement "Atomic" data types. The main point seems
         * to be to provide the capability to "atomically" (i.e. without the intervening
         * interleaving of actions taken by another thread) both read the variable's current
         * value, AND set it to something new. This means we needn't lock access to the object
         * if all we want to do is update the Atomic value.
         */
        AtomicInteger activeRequestCounter = new AtomicInteger();

        final Object latencySync = new Object();
        int latencyStorageCapacity = 10000;
        Vector<Long> latencyStorage = new Vector<>(latencyStorageCapacity);

        AtomicLong lastUpdateTimer = new AtomicLong();

        ScheduledThreadPoolExecutor displayTimer = new ScheduledThreadPoolExecutor(1);

        public void start() {
            long now = System.nanoTime();
            lastUpdateTimer.set(now);
            displayTimer.scheduleAtFixedRate(this::displayUpdate, 1, 1, TimeUnit.SECONDS);
        }

        public void stop() {
            /* Attempts to stop all actively executing tasks, halts the processing of waiting
             * tasks, and returns a list of the tasks that were awaiting execution. */
            displayTimer.shutdownNow();
        }

        public void incrementActiveRequests() {
            activeRequestCounter.getAndIncrement();
        }

        public void recordLatency(long latencyInNanos) {
            latencyStorage.add(latencyInNanos);
            activeRequestCounter.getAndDecrement();
        }

        /**
         * The Metrics class executes this method every second in a background thread.
         * I.e. the relevant variables are still being updated as this executes.
         * That's why we have to be careful to synchronize the reset.
         * We don't synchronize the whole method because sorting the array of collected data
         * could take a significant amount of time and we'd have HOL blocking.
         */
        private void displayUpdate() {
            long now, lastUpdateTime, activeRequests;
            Long[] latencies;
            synchronized (latencySync) {
                now = System.nanoTime();
                lastUpdateTime = lastUpdateTimer.getAndSet(now);
                activeRequests = activeRequestCounter.get();

                // The length of the returned array is equal to the number of elements
                // returned by the collection's iterator
                latencies = latencyStorage.toArray(new Long[]{});
                latencyStorage.removeAllElements();
            }

            int latencyCount = latencies.length;

            // default Long compareTo is a.value <?> b.value, as we need here
            Arrays.sort(latencies);

            double elapsedSeconds = (double) (now-lastUpdateTime)*1e-9;

            double latencyP50 = latencyCount == 0 ? 0 : (double) latencies[latencyCount/2]*1e-6;
            double latencyP90 = latencyCount == 0 ? 0 : (double) latencies[latencyCount*9/10]*1e-6;
            double responseRate = elapsedSeconds == 0 ? 0 : (double) latencyCount/elapsedSeconds;
            System.out.printf(
                "Active Requests: %d, Response rate: %.0f/s, Latency: P50 %.3fms P90 %.3fms\n",
                activeRequests, responseRate, latencyP50, latencyP90);
        }
    }
}
