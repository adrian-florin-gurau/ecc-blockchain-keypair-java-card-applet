# ECC Blockchain Keypair Java Card Applet

Implementation for a Java Card 3.2+ blockchain wallet demo.

The project contains:

- Java Card applet source code that creates and stores an EC private/public key pair inside the card.
- A standalone Java host application using `javax.smartcardio` for PC/SC cards and a local mock simulator mode.
- Build, run, and packaging scripts.
- APDU protocol and assignment notes.

## Project structure

```text
src/applet/   Java Card applet
src/host/     Standalone Java host application
scripts/      Build, run, and ZIP packaging scripts
docs/         APDU protocol and assignment notes
```

## Quick run with local mock mode

Mock mode is useful when the Oracle Java Card simulator or a physical card is not available.

```powershell
.\scripts\run-mock.ps1
```

Expected output includes:

- selected mode
- transaction text
- SHA-256 transaction hash
- uncompressed EC public key
- DER-encoded ECDSA signature

## Compile host application

```powershell
.\scripts\build.ps1
```

## Compile applet source

Install the Oracle Java Card 3.2 SDK or an equivalent Java Card SDK and set `JAVACARD_HOME` to its root directory:

```powershell
$env:JAVACARD_HOME = "C:\path\to\java_card_sdk-3_2_0"
.\scripts\build.ps1 -Applet
```

The script looks for `api_classic*.jar` under `JAVACARD_HOME` and compiles the applet classes. CAP conversion/loading is simulator-vendor-specific, so the APDU protocol is documented separately in `docs\APDU_PROTOCOL.md`.

## Run against a card or simulator exposed through PC/SC

Load/install the applet with AID `F0010203040506`, then run:

```powershell
.\scripts\run-card.ps1
```

You can also pass a custom transaction string:

```powershell
.\scripts\run-card.ps1 -Transaction "ethereum:to=0x001122;value=1;nonce=7"
```

For Oracle Java Card simulator setup on Windows, see `docs\SIMULATOR_SETUP.md`.

## Package for Moodle/Sakai

```powershell
.\scripts\package-assignment.ps1 -LastName POPESCU -FirstName ION
```

This creates:

```text
POPESCUIONSPCEQ2026ASSIGNMENT6.zip
```

## Notes

The applet uses ECDSA over secp256k1 parameters. The host mock first tries `secp256k1` and falls back to `secp256r1` if the local JDK provider does not expose secp256k1. This keeps the demo runnable while preserving the Java Card applet design for Bitcoin/Ethereum-style curves.
