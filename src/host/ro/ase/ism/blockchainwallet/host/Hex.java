package ro.ase.ism.blockchainwallet.host;

final class Hex {
    private static final char[] DIGITS = "0123456789abcdef".toCharArray();

    private Hex() {
    }

    static String encode(byte[] data) {
        char[] out = new char[data.length * 2];
        for (int i = 0; i < data.length; i++) {
            int value = data[i] & 0xff;
            out[i * 2] = DIGITS[value >>> 4];
            out[i * 2 + 1] = DIGITS[value & 0x0f];
        }
        return new String(out);
    }

    static byte[] decode(String text) {
        String hex = text.startsWith("0x") || text.startsWith("0X") ? text.substring(2) : text;
        if ((hex.length() & 1) != 0) {
            throw new IllegalArgumentException("Hex value must contain an even number of characters");
        }
        byte[] out = new byte[hex.length() / 2];
        for (int i = 0; i < out.length; i++) {
            int high = Character.digit(hex.charAt(i * 2), 16);
            int low = Character.digit(hex.charAt(i * 2 + 1), 16);
            if (high < 0 || low < 0) {
                throw new IllegalArgumentException("Invalid hex value");
            }
            out[i] = (byte) ((high << 4) | low);
        }
        return out;
    }
}
