package ethanp.util;

import ethanp.experiments.KTCPs;

/**
 * Ethan Petuchowski 11/13/15
 */
public class KTCPsBuilder {
    int numServers;
    int firstPort;
    int bytesSentPerConn;

    public KTCPsBuilder servers(int n) {
        this.numServers = n;
        return this;
    }

    public KTCPsBuilder firstPort(int p) {
        this.firstPort = p;
        return this;
    }

    public KTCPsBuilder bytesPerConn(int b) {
        this.bytesSentPerConn = b;
        return this;
    }

    public KTCPs build() {
        return new KTCPs(numServers, firstPort, bytesSentPerConn);
    }
}
