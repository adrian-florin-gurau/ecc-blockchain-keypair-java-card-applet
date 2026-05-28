package ro.ase.ism.blockchainwallet.host;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;

public final class HostApp {
    private static final byte[] APPLET_AID = Hex.decode("F0010203040506");

    private static final byte CLA = (byte) 0x80;
    private static final byte INS_GENERATE_KEYPAIR = (byte) 0x10;
    private static final byte INS_GET_PUBLIC_KEY = (byte) 0x20;
    private static final byte INS_SIGN_HASH = (byte) 0x30;

    private HostApp() {
    }

    public static void main(String[] args) throws Exception {
        boolean mock = args.length == 0 || "--mock".equals(args[0]);
        String transaction = args.length > 1
                ? args[1]
                : "bitcoin:from=alice;to=bob;amount=0.01000000;nonce=1";

        try (ApduClient card = mock ? new MockCardClient() : new SmartCardClient()) {
            if (!mock) {
                selectApplet(card);
            }

            transmit(card, apdu(INS_GENERATE_KEYPAIR));
            byte[] publicKey = transmit(card, apdu(INS_GET_PUBLIC_KEY));
            byte[] hash = sha256(transaction.getBytes(StandardCharsets.UTF_8));
            byte[] signature = transmit(card, apdu(INS_SIGN_HASH, hash));

            System.out.println("Mode: " + (mock ? "mock simulator" : "PC/SC card"));
            System.out.println("Transaction: " + transaction);
            System.out.println("SHA-256 transaction hash: " + Hex.encode(hash));
            System.out.println("Uncompressed EC public key: " + Hex.encode(publicKey));
            System.out.println("ECDSA signature DER: " + Hex.encode(signature));
        }
    }

    private static void selectApplet(ApduClient card) throws Exception {
        byte[] command = new byte[5 + APPLET_AID.length];
        command[0] = 0x00;
        command[1] = (byte) 0xA4;
        command[2] = 0x04;
        command[3] = 0x00;
        command[4] = (byte) APPLET_AID.length;
        System.arraycopy(APPLET_AID, 0, command, 5, APPLET_AID.length);
        transmit(card, command);
    }

    private static byte[] transmit(ApduClient card, byte[] command) throws Exception {
        return card.transmit(command);
    }

    private static byte[] apdu(byte ins) {
        return new byte[]{CLA, ins, 0x00, 0x00, 0x00};
    }

    private static byte[] apdu(byte ins, byte[] data) {
        byte[] command = Arrays.copyOf(apdu(ins), 5 + data.length);
        command[4] = (byte) data.length;
        System.arraycopy(data, 0, command, 5, data.length);
        return command;
    }

    private static byte[] sha256(byte[] data) throws Exception {
        return MessageDigest.getInstance("SHA-256").digest(data);
    }
}
