package ro.ase.ism.blockchainwallet.host;

import java.io.Closeable;

interface ApduClient extends Closeable {
    byte[] transmit(byte[] command) throws Exception;
}
