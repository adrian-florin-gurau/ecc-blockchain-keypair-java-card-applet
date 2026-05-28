package ro.ase.ism.blockchainwallet.host;

import com.oracle.javacard.ams.AMService;
import com.oracle.javacard.ams.AMServiceFactory;
import com.oracle.javacard.ams.AMSession;
import com.oracle.javacard.ams.config.CAPFile;

import java.io.FileInputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.List;
import java.util.Properties;
import javax.smartcardio.Card;
import javax.smartcardio.CardChannel;
import javax.smartcardio.CardTerminal;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;
import javax.smartcardio.TerminalFactory;

public final class SimulatorDeployAndRun {
    private static final String ISD_AID = "A000000151000000";
    private static final String PACKAGE_AID = "F00102030405";
    private static final String APPLET_AID = "F0010203040506";

    private static final byte CLA = (byte) 0x80;
    private static final byte INS_GENERATE_KEYPAIR = (byte) 0x10;
    private static final byte INS_GET_PUBLIC_KEY = (byte) 0x20;
    private static final byte INS_SIGN_HASH = (byte) 0x30;

    private SimulatorDeployAndRun() {
    }

    public static void main(String[] args) throws Exception {
        String capPath = arg(args, "cap", "build/applet-deliverables/ro/ase/ism/blockchainwallet/javacard/blockchainwallet.cap");
        String propsPath = arg(args, "props", null);
        String host = arg(args, "host", "localhost");
        int port = Integer.parseInt(arg(args, "port", "9025"));
        String transaction = arg(args, "tx", "bitcoin:from=alice;to=bob;amount=0.01000000;nonce=1");

        deploy(capPath, propsPath, host, port);

        CardTerminal terminal = socketTerminal(host, port);
        if (!terminal.waitForCardPresent(10000)) {
            throw new IllegalStateException("Simulator socket is not ready");
        }

        Card card = terminal.connect("*");
        try {
            CardChannel channel = card.getBasicChannel();
            transmit(channel, select(Hex.decode(APPLET_AID)));
            transmit(channel, apdu(INS_GENERATE_KEYPAIR));
            byte[] publicKey = transmit(channel, apdu(INS_GET_PUBLIC_KEY));
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(transaction.getBytes(StandardCharsets.UTF_8));
            byte[] signature = transmit(channel, apdu(INS_SIGN_HASH, hash));

            System.out.println("Mode: Oracle Java Card simulator");
            System.out.println("Transaction: " + transaction);
            System.out.println("SHA-256 transaction hash: " + Hex.encode(hash));
            System.out.println("Uncompressed EC public key: " + Hex.encode(publicKey));
            System.out.println("ECDSA signature DER: " + Hex.encode(signature));
        } finally {
            card.disconnect(true);
        }
    }

    private static void deploy(String capPath, String propsPath, String host, int port) throws Exception {
        AMService ams = AMServiceFactory.getInstance("GP2.2");
        if (propsPath != null) {
            Properties props = new Properties();
            props.load(new FileInputStream(propsPath));
            ams.setProperties(props);
        }

        CAPFile cap = CAPFile.from(capPath);
        AMSession deploy = ams.openSession("aid:" + ISD_AID)
                .load("aid:" + PACKAGE_AID, cap.getBytes())
                .install("aid:" + PACKAGE_AID, "aid:" + APPLET_AID, "aid:" + APPLET_AID)
                .close();

        CardTerminal terminal = socketTerminal(host, port);
        if (!terminal.waitForCardPresent(10000)) {
            throw new IllegalStateException("Simulator socket is not ready for deployment");
        }
        Card card = terminal.connect("*");
        try {
            deploy.run(card.getBasicChannel());
        } finally {
            card.disconnect(true);
        }
    }

    private static CardTerminal socketTerminal(String host, int port) throws Exception {
        TerminalFactory factory = TerminalFactory.getInstance(
                "SocketCardTerminalFactoryType",
                List.of(new InetSocketAddress(host, port)),
                "SocketCardTerminalProvider");
        return factory.terminals().list().get(0);
    }

    private static byte[] transmit(CardChannel channel, byte[] command) throws Exception {
        ResponseAPDU response = channel.transmit(new CommandAPDU(command));
        if (response.getSW() != 0x9000) {
            throw new IllegalStateException(String.format("APDU failed with SW=%04X", response.getSW()));
        }
        return response.getData();
    }

    private static byte[] select(byte[] aid) {
        byte[] command = new byte[5 + aid.length];
        command[0] = 0x00;
        command[1] = (byte) 0xA4;
        command[2] = 0x04;
        command[3] = 0x00;
        command[4] = (byte) aid.length;
        System.arraycopy(aid, 0, command, 5, aid.length);
        return command;
    }

    private static byte[] apdu(byte ins) {
        return new byte[]{CLA, ins, 0x00, 0x00, 0x00};
    }

    private static byte[] apdu(byte ins, byte[] data) {
        byte[] command = new byte[5 + data.length];
        command[0] = CLA;
        command[1] = ins;
        command[2] = 0x00;
        command[3] = 0x00;
        command[4] = (byte) data.length;
        System.arraycopy(data, 0, command, 5, data.length);
        return command;
    }

    private static String arg(String[] args, String name, String defaultValue) {
        String prefix = "--" + name + "=";
        for (String arg : args) {
            if (arg.startsWith(prefix)) {
                return arg.substring(prefix.length());
            }
        }
        return defaultValue;
    }
}
