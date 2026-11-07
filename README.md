# Grid Status for Garmin

A personal Connect IQ watch app for the Forerunner 255. It shows the current load, net load, hub price and primary fuel for each ISO, using `isos_latest` from the Grid Status API.

**Don't share `bin/GridStatus.prg`.** The build compiles your API key into it, and API keys have no scopes.

## Controls

- **UP / DOWN:** previous or next ISO
- **START:** refresh
- **BACK:** exit

Data refreshes when the app opens and when you press START, and each request counts against your API quota. The time beside each value is the age of that value.

## Setup

```bash
brew install --cask connectiq connectiq-sdk-manager
```

Open the SDK Manager, sign in, and download the Forerunner 255 device files.

The cask moves `ConnectIQ.app` to `/Applications`, but the simulator reads `version.txt` from the app's folder. Without this link it shows `can't open file '/Applications/version.txt'` and stalls until the dialog is dismissed. Run this again after upgrading the SDK:

```bash
ln -sf "$(dirname "$(readlink -f "$(which monkeyc)")")/version.txt" /Applications/version.txt
```

Generate a developer key:

```bash
mkdir -p ~/.connectiq
openssl genrsa -out ~/.connectiq/developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in ~/.connectiq/developer_key.pem -out ~/.connectiq/developer_key.der -nocrypt
```

## Build

```bash
scripts/build.sh
```

The API key comes from `GRIDSTATUS_API_KEY`, falling back to the gitignored `.env` in the repository root. It is written to the gitignored `resources-local/api_key.xml`.

To target another device, add it to `manifest.xml` and set `GRIDSTATUS_DEVICE`.

## Test

Open the simulator, then run the unit tests:

```bash
open -a /Applications/ConnectIQ.app
scripts/test.sh
```

To run the app in the simulator:

```bash
monkeydo bin/GridStatus.prg fr255
```

## Install on the watch

Connect the watch by USB and copy `bin/GridStatus.prg` to `GARMIN/APPS`. On a Mac this needs an MTP app such as OpenMTP, and you may need to quit Garmin Express first.

The watch fetches data through the Garmin Connect app, so your phone must be connected.
