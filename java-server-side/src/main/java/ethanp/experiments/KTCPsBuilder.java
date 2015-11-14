package ethanp.experiments;

/**
 * Ethan Petuchowski 11/13/15
 */
class KTCPsBuilder {
    int numServers;
    int firstPort;
    int bytesSentPerConn;

    KTCPsBuilder servers(int n) {
        this.numServers = n;
        return this;
    }

    KTCPsBuilder firstPort(int p) {
        this.firstPort = p;
        return this;
    }

    KTCPsBuilder bytesPerConn(int b) {
        this.bytesSentPerConn = b;
        return this;
    }

    KTCPs build() {
        return new KTCPs(numServers, firstPort, bytesSentPerConn);
    }
}
