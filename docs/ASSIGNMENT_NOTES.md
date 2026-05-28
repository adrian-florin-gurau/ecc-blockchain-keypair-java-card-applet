# Assignment notes

This project implements a Java Card blockchain wallet proof of concept aligned with the assignment requirements:

- Java Card is used as the secure element/root of trust.
- The private EC key is generated inside the card applet and never exported.
- The host application sends only a blockchain transaction hash to be signed.
- The applet returns the public key and an ECDSA signature that a blockchain gateway flow can use.

The demo transaction is Bitcoin-like text for readability:

```text
bitcoin:from=alice;to=bob;amount=0.01000000;nonce=1
```

The host hashes that transaction with SHA-256 and asks the card to sign the 32-byte digest. For Ethereum, the same APDU design can be reused by sending a Keccak-256 transaction digest prepared by the host before the `SIGN_HASH` command.

The applet configures secp256k1 domain parameters, matching Bitcoin/Ethereum style wallets. Some Java Card simulators or JDK providers do not support secp256k1. The host mock mode therefore falls back to secp256r1 only to keep the compilation/run phase demonstrable on a normal workstation; the applet source remains secp256k1-oriented.