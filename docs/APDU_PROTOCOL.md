# APDU protocol

Applet AID: `F0010203040506`

The applet is selected with a standard ISO `SELECT by name` command:

```text
00 A4 04 00 07 F0 01 02 03 04 05 06
```

Application commands use CLA `80`.

| Command | APDU | Response |
| --- | --- | --- |
| Generate EC key pair | `80 10 00 00 00` | `9000` |
| Read public key | `80 20 00 00 00` | uncompressed EC point, 65 bytes |
| Sign transaction hash | `80 30 00 00 20 <32-byte hash>` | DER ECDSA signature |

Status words:

| SW | Meaning |
| --- | --- |
| `9000` | Success |
| `6A80` | Wrong hash length |
| `6A88` | Key pair has not been generated |
| `6D00` | Unsupported instruction |
| `6E00` | Unsupported class |
