package ro.ase.ism.blockchainwallet;

import javacard.framework.APDU;
import javacard.framework.Applet;
import javacard.framework.ISO7816;
import javacard.framework.ISOException;
import javacard.framework.Util;
import javacard.security.ECPrivateKey;
import javacard.security.ECPublicKey;
import javacard.security.KeyBuilder;
import javacard.security.KeyPair;
import javacard.security.Signature;

/**
 * Minimal Java Card blockchain wallet applet.
 *
 * APDU protocol:
 *   80 10 00 00 00       generate a secp256k1 key pair
 *   80 20 00 00 00       return uncompressed public key, 65 bytes
 *   80 30 00 00 20 hash  sign a 32-byte blockchain transaction hash
 */
public final class BlockchainWalletApplet extends Applet {
    private static final byte WALLET_CLA = (byte) 0x80;

    private static final byte INS_GENERATE_KEYPAIR = (byte) 0x10;
    private static final byte INS_GET_PUBLIC_KEY = (byte) 0x20;
    private static final byte INS_SIGN_HASH = (byte) 0x30;

    private static final short KEY_LENGTH_BITS = (short) 256;
    private static final short HASH_LENGTH = (short) 32;
    private static final short PUBLIC_KEY_LENGTH = (short) 65;

    private static final short SW_KEY_NOT_GENERATED = (short) 0x6A88;
    private static final short SW_WRONG_HASH_LENGTH = (short) 0x6A80;

    private static final byte[] SECP256K1_P = {
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFE,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFC, (byte) 0x2F
    };

    private static final byte[] SECP256K1_A = {
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00
    };

    private static final byte[] SECP256K1_B = {
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x07
    };

    private static final byte[] SECP256K1_G = {
            0x04,
            0x79, (byte) 0xBE, 0x66, 0x7E, (byte) 0xF9, (byte) 0xDC, (byte) 0xBB, (byte) 0xAC,
            0x55, (byte) 0xA0, 0x62, (byte) 0x95, (byte) 0xCE, (byte) 0x87, 0x0B, 0x07,
            0x02, (byte) 0x9B, (byte) 0xFC, (byte) 0xDB, 0x2D, (byte) 0xCE, 0x28, (byte) 0xD9,
            0x59, (byte) 0xF2, (byte) 0x81, 0x5B, 0x16, (byte) 0xF8, 0x17, (byte) 0x98,
            0x48, 0x3A, (byte) 0xDA, 0x77, 0x26, (byte) 0xA3, (byte) 0xC4, 0x65,
            0x5D, (byte) 0xA4, (byte) 0xFB, (byte) 0xFC, 0x0E, 0x11, 0x08, (byte) 0xA8,
            (byte) 0xFD, 0x17, (byte) 0xB4, 0x48, (byte) 0xA6, (byte) 0x85, 0x54, 0x19,
            (byte) 0x9C, 0x47, (byte) 0xD0, (byte) 0x8F, (byte) 0xFB, 0x10, (byte) 0xD4, (byte) 0xB8
    };

    private static final byte[] SECP256K1_R = {
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFF,
            (byte) 0xFF, (byte) 0xFF, (byte) 0xFF, (byte) 0xFE,
            (byte) 0xBA, (byte) 0xAE, (byte) 0xDC, (byte) 0xE6,
            (byte) 0xAF, 0x48, (byte) 0xA0, 0x3B,
            (byte) 0xBF, (byte) 0xD2, 0x5E, (byte) 0x8C,
            (byte) 0xD0, 0x36, 0x41, 0x41
    };

    private final KeyPair keyPair;
    private final Signature signature;
    private boolean keyGenerated;

    private BlockchainWalletApplet() {
        ECPublicKey publicKey = (ECPublicKey) KeyBuilder.buildKey(
                KeyBuilder.TYPE_EC_FP_PUBLIC, KEY_LENGTH_BITS, false);
        ECPrivateKey privateKey = (ECPrivateKey) KeyBuilder.buildKey(
                KeyBuilder.TYPE_EC_FP_PRIVATE, KEY_LENGTH_BITS, false);

        setSecp256k1Domain(publicKey);
        setSecp256k1Domain(privateKey);

        keyPair = new KeyPair(publicKey, privateKey);
        signature = Signature.getInstance(Signature.ALG_ECDSA_SHA_256, false);
        keyGenerated = false;
    }

    public static void install(byte[] bArray, short bOffset, byte bLength) {
        new BlockchainWalletApplet().register(bArray, (short) (bOffset + 1), bArray[bOffset]);
    }

    public void process(APDU apdu) {
        if (selectingApplet()) {
            return;
        }

        byte[] buffer = apdu.getBuffer();
        if (buffer[ISO7816.OFFSET_CLA] != WALLET_CLA) {
            ISOException.throwIt(ISO7816.SW_CLA_NOT_SUPPORTED);
        }

        switch (buffer[ISO7816.OFFSET_INS]) {
            case INS_GENERATE_KEYPAIR:
                generateKeyPair();
                return;
            case INS_GET_PUBLIC_KEY:
                getPublicKey(apdu);
                return;
            case INS_SIGN_HASH:
                signHash(apdu);
                return;
            default:
                ISOException.throwIt(ISO7816.SW_INS_NOT_SUPPORTED);
        }
    }

    private void generateKeyPair() {
        keyPair.genKeyPair();
        keyGenerated = true;
    }

    private void getPublicKey(APDU apdu) {
        requireKey();
        byte[] buffer = apdu.getBuffer();
        short length = ((ECPublicKey) keyPair.getPublic()).getW(buffer, (short) 0);
        if (length != PUBLIC_KEY_LENGTH) {
            ISOException.throwIt(ISO7816.SW_UNKNOWN);
        }
        apdu.setOutgoingAndSend((short) 0, PUBLIC_KEY_LENGTH);
    }

    private void signHash(APDU apdu) {
        requireKey();
        byte[] buffer = apdu.getBuffer();
        short length = apdu.setIncomingAndReceive();
        if (length != HASH_LENGTH || buffer[ISO7816.OFFSET_LC] != HASH_LENGTH) {
            ISOException.throwIt(SW_WRONG_HASH_LENGTH);
        }

        signature.init(keyPair.getPrivate(), Signature.MODE_SIGN);
        short signatureLength = signature.sign(
                buffer,
                ISO7816.OFFSET_CDATA,
                HASH_LENGTH,
                buffer,
                (short) 0);
        apdu.setOutgoingAndSend((short) 0, signatureLength);
    }

    private void requireKey() {
        if (!keyGenerated) {
            ISOException.throwIt(SW_KEY_NOT_GENERATED);
        }
    }

    private static void setSecp256k1Domain(ECPublicKey key) {
        key.setFieldFP(SECP256K1_P, (short) 0, (short) SECP256K1_P.length);
        key.setA(SECP256K1_A, (short) 0, (short) SECP256K1_A.length);
        key.setB(SECP256K1_B, (short) 0, (short) SECP256K1_B.length);
        key.setG(SECP256K1_G, (short) 0, (short) SECP256K1_G.length);
        key.setR(SECP256K1_R, (short) 0, (short) SECP256K1_R.length);
        key.setK((short) 1);
    }

    private static void setSecp256k1Domain(ECPrivateKey key) {
        key.setFieldFP(SECP256K1_P, (short) 0, (short) SECP256K1_P.length);
        key.setA(SECP256K1_A, (short) 0, (short) SECP256K1_A.length);
        key.setB(SECP256K1_B, (short) 0, (short) SECP256K1_B.length);
        key.setG(SECP256K1_G, (short) 0, (short) SECP256K1_G.length);
        key.setR(SECP256K1_R, (short) 0, (short) SECP256K1_R.length);
        key.setK((short) 1);
    }
}
