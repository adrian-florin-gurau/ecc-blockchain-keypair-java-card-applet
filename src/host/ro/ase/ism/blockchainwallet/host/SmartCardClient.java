package ro.ase.ism.blockchainwallet.host;

import java.util.List;
import javax.smartcardio.Card;
import javax.smartcardio.CardChannel;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;
import javax.smartcardio.TerminalFactory;
import javax.smartcardio.CardTerminal;

final class SmartCardClient implements ApduClient {
    private final Card card;
    private final CardChannel channel;

    SmartCardClient() throws Exception {
        TerminalFactory factory = TerminalFactory.getDefault();
        List<CardTerminal> terminals = factory.terminals().list();
        if (terminals.isEmpty()) {
            throw new IllegalStateException("No PC/SC card terminal found");
        }
        CardTerminal terminal = terminals.get(0);
        card = terminal.connect("*");
        channel = card.getBasicChannel();
    }

    public byte[] transmit(byte[] command) throws Exception {
        ResponseAPDU response = channel.transmit(new CommandAPDU(command));
        if (response.getSW() != 0x9000) {
            throw new IllegalStateException(String.format("Card returned SW=%04X", response.getSW()));
        }
        return response.getData();
    }

    public void close() {
        try {
            card.disconnect(false);
        } catch (Exception ignored) {
            // Best effort close for command-line demo.
        }
    }
}
