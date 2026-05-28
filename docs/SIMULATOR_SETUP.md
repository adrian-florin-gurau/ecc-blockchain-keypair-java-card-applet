# Oracle Java Card simulator setup on Windows

This project can run in three modes:

- `run-mock.ps1`: local Java cryptographic mock, no Java Card SDK needed.
- `run-card.ps1`: PC/SC smart-card connection, physical or simulated.
- Oracle Java Card simulator: official Java Card 3.2 runtime simulator exposed through PC/SC.

## 1. Download the SDK components

Download both current Java Card Development Kit components from Oracle:

- Java Card Development Kit Tools 26.0
- Java Card Development Kit Simulator 26.0 for Windows

Oracle download page:

```text
https://www.oracle.com/java/technologies/javacard-downloads.html
```

Unzip them somewhere simple, for example:

```text
C:\JavaCard\tools
C:\JavaCard\simulator
```

Then set environment variables:

```powershell
$env:JC_HOME_TOOLS = "C:\JavaCard\tools"
$env:JC_HOME_SIMULATOR = "C:\JavaCard\simulator"
$env:JAVACARD_HOME = $env:JC_HOME_TOOLS
```

For permanent user variables:

```powershell
[Environment]::SetEnvironmentVariable("JC_HOME_TOOLS", "C:\JavaCard\tools", "User")
[Environment]::SetEnvironmentVariable("JC_HOME_SIMULATOR", "C:\JavaCard\simulator", "User")
[Environment]::SetEnvironmentVariable("JAVACARD_HOME", "C:\JavaCard\tools", "User")
```

Open a new PowerShell window after setting permanent variables.

## 2. Install the Oracle PC/SC simulated reader

Open PowerShell as Administrator and run:

```powershell
cd $env:JC_HOME_SIMULATOR\drivers\PCSC
.\jcdkPCSCCtrl.exe install
.\jcdkPCSCCtrl.exe add 0
```

Check that Windows sees the simulated reader:

```powershell
Get-PnpDevice -Class SmartCardReader
```

You should see `Oracle Java Card PCSC Reader`.

## 3. Start the simulator

Before the first run, configure demo SCP03 keys in the simulator binary. Stop the simulator if it is already running, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\configure-oracle-simulator.ps1
```

This project uses key version number `01` with zero SCP03 keys for a local academic simulator only. Do not use these keys for a real card.

In a normal PowerShell window:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-oracle-simulator.ps1
```

Keep that window open.

## 4. Compile the applet

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Applet
```

This validates the applet source against the Java Card API jar.

## 5. Load/install the applet

The applet AID is:

```text
F0010203040506
```

The package/class is:

```text
ro.ase.ism.blockchainwallet.BlockchainWalletApplet
```

Oracle simulator applet loading uses the Java Card Tools converter plus the simulator application-management client. The exact command depends on the extracted SDK layout, so use the Oracle sample applet install scripts as the template and replace the sample package/class/AID with the values above.

For this project, the helper below builds, converts, deploys, and runs a signing test through the simulator socket:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-oracle-simulator.ps1
```

## 6. Test through PC/SC

Once the applet is installed and the simulator is still running:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-card.ps1
```

If `run-card.ps1` still says no PC/SC terminal was found, the simulated reader was not installed or the PowerShell session needs to be restarted.
