package ro.ase.ism.blockchainwallet.host;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.security.Signature;
import java.security.interfaces.ECPublicKey;
import java.security.spec.ECGenParameterSpec;
import java.security.spec.ECPoint;
import java.util.Arrays;

final class MockCardClient implements ApduClient {
    private static final byte CLA = (byte) 0x80;
    private static final byte INS_GENERATE_KEYPAIR = (byte) 0x10;
    private static final byte INS_GET_PUBLIC_KEY = (byte) 0x20;
    private static final byte INS_SIGN_HASH = (byte) 0x30;

    private KeyPair keyPair;

    public byte[] transmit(byte[] command) throws Exception {
        if (command.length < 5 || command[0] != CLA) {
            throw new IllegalArgumentException("Unsupported APDU");
        }

        switch (command[1]) {
            case INS_GENERATE_KEYPAIR:
                generate();
                return new byte[0];
            case INS_GET_PUBLIC_KEY:
                requireKey();
                return publicKeyBytes();
            case INS_SIGN_HASH:
                requireKey();
                byte[] hash = Arrays.copyOfRange(command, 5, command.length);
                if (hash.length != 32) {
                    throw new IllegalArgumentException("SIGN_HASH expects 32 bytes");
                }
                return sign(hash);
            default:
                throw new IllegalArgumentException("Unsupported INS");
        }
    }

    public void close() {
    }

    private void generate() throws Exception {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("EC");
        try {
            generator.initialize(new ECGenParameterSpec("secp256k1"));
        } catch (Exception unsupportedByJdk) {
            generator.initialize(new ECGenParameterSpec("secp256r1"));
        }
        keyPair = generator.generateKeyPair();
    }

    private byte[] sign(byte[] hash) throws Exception {
        Signature ecdsa = Signature.getInstance("SHA256withECDSA");
        ecdsa.initSign(keyPair.getPrivate());
        ecdsa.update(hash);
        return ecdsa.sign();
    }

    private byte[] publicKeyBytes() {
        ECPublicKey publicKey = (ECPublicKey) keyPair.getPublic();
        ECPoint point = publicKey.getW();
        ByteArrayOutputStream out = new ByteArrayOutputStream(65);
        out.write(0x04);
        writeFixed(out, point.getAffineX());
        writeFixed(out, point.getAffineY());
        return out.toByteArray();
    }

    private void requireKey() {
        if (keyPair == null) {
            throw new IllegalStateException("Generate the wallet key pair first");
        }
    }

    private static void writeFixed(ByteArrayOutputStream out, BigInteger value) {
        byte[] raw = value.toByteArray();
        byte[] fixed = new byte[32];
        int copyLength = Math.min(raw.length, fixed.length);
        System.arraycopy(raw, raw.length - copyLength, fixed, fixed.length - copyLength, copyLength);
        out.write(fixed, 0, fixed.length);
    }
}
