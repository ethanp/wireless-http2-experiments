package ethanp.experiments;

import java.util.Arrays;
import java.util.Vector;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Ethan Petuchowski 11/25/15
 *
 * This is modified from https://github.com/oneam/test-http2-jetty/tree/master/src/main/java/test/jetty
 *
 * It uses `Vector[Long]` instead of `long[]`,
 * and `ScheduledExecutor` with a lambda instead of `Timer` and `TimerTask`
 */
class Metrics {

    final Object latencySync = new Object();
    /* In general, Java may employ efficient machine-level atomic instructions available
     * on contemporary processors to implement "Atomic" data types. The main point seems
     * to be to provide the capability to "atomically" (i.e. without the intervening
     * interleaving of actions taken by another thread) both read the variable's current
     * value, AND set it to something new. This means we needn't lock access to the object
     * if all we want to do is update the Atomic value.
     */
    AtomicInteger activeRequestCounter = new AtomicInteger();
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
     * The Metrics class executes this method every second in a background thread. I.e. the relevant
     * variables are still being updated as this executes. That's why we have to be careful to
     * synchronize the reset. We don't synchronize the whole method because sorting the array of
     * collected data could take a significant amount of time and we'd have HOL blocking.
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
            latencies = latencyStorage.toArray(new Long[latencyStorage.size()]);
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
