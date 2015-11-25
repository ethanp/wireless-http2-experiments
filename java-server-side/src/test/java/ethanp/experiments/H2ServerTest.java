package ethanp.experiments;

import org.eclipse.jetty.client.HttpClient;
import org.eclipse.jetty.client.api.Result;
import org.eclipse.jetty.client.util.BufferingResponseListener;
import org.eclipse.jetty.http.HttpVersion;
import org.eclipse.jetty.http2.client.HTTP2Client;
import org.eclipse.jetty.http2.client.http.HttpClientTransportOverHTTP2;
import org.eclipse.jetty.util.ssl.SslContextFactory;
import org.junit.Test;

import java.util.concurrent.Semaphore;

/**
 * Ethan Petuchowski 11/25/15
 *
 * This is modified from https://github.com/oneam/test-http2-jetty/tree/master/src/main/java/test/jetty
 */
@SuppressWarnings("ConstantConditions")
public class H2ServerTest {
    static final String protocol = "https";
    static final String ipAddr = "localhost";
    static final String h1port = "8444";
    static final String h2port = "8443";
    static final String path = "index.html";
    static final String h1uri = String.format("%s://%s:%s/%s", protocol, ipAddr, h1port, path);
    static final String h2uri = String.format("%s://%s:%s/%s", protocol, ipAddr, h2port, path);
    static boolean failed = false;
    static boolean versionPrinted = false;

    @Test public void testH2ServerSpeed() throws Exception {
        HttpClient client;
        System.out.println("Client using HTTP/2 protocol");
        HTTP2Client http2Client = new HTTP2Client();
        client = new HttpClient(
            new HttpClientTransportOverHTTP2(http2Client),
            new SslContextFactory(true)
        );
        client.start();
        Metrics metrics = new Metrics();
        metrics.start();

        // Limits the number of concurrent requests
        Semaphore throttle = new Semaphore(200);

        while (!failed) {
            throttle.acquire();
            long start = System.nanoTime();
            metrics.incrementActiveRequests();
            client.newRequest(h2uri).send(new BufferingResponseListener(/*2MB*/) {
                @Override public void onComplete(Result result) {
                    if (result.isFailed()) {
                        //noinspection ThrowableResultOfMethodCallIgnored
                        System.err.println(result.getFailure().getMessage());
                        failed = true;
                    }
                    String content = getContentAsString();
                    if (!versionPrinted) {
                        HttpVersion version = result.getResponse().getVersion();
                        System.out.println("VERSION: "+version);
                        if (content != null) {
                            System.out.println(content.substring(0, Math.min(50, content.length())));
                        }
                        else {
                            System.err.println("content was null");
                            failed = true;
                        }
                        versionPrinted = true;
                    }
                    metrics.recordLatency(System.nanoTime()-start);
                    throttle.release();
                }
            });
        }
    }

    @Test public void testBoth() throws Exception {
        HttpClient h1 = new HttpClient(new SslContextFactory(true));
        HttpClient h2 = new HttpClient(
            new HttpClientTransportOverHTTP2(new HTTP2Client()),
            new SslContextFactory(true)
        );
        h1.start();
        h2.start();
        h1.newRequest(h1uri).send(
            new BufferingResponseListener() {
                @Override public void onComplete(Result result) {
                    System.out.println("h1: "+result.getResponse().getVersion());
                }
            }
        );
        h2.newRequest(h2uri).send(
            new BufferingResponseListener() {
                @Override public void onComplete(Result result) {
                    System.out.println("h2: "+result.getResponse().getVersion());
                }
            }
        );
        Thread.sleep(5000);
    }

}
