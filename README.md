# Grid Status for Garmin

A Connect IQ watch app for the Forerunner 255 Music (`fr255m`). It shows the current load, net load, hub price and primary fuel for each ISO, using `isos_latest` from the Grid Status API.

Each person uses their own API key, which they paste into the app's settings in Garmin Connect.

## Controls

- **UP / DOWN:** previous or next ISO
- **START:** refresh
- **BACK:** exit

The time beside each value is the age of that value, and the bottom line shows when the app last fetched data.

Each fetch counts against the user's API quota, so the app reuses the last response for 5 minutes. Opening the app or pressing START in that window doesn't send a request. Changing the API key always fetches.

## Setup

```bash
brew install --cask connectiq connectiq-sdk-manager
```

Open the SDK Manager, sign in, and download the Forerunner 255 Music device files.

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

| Command | Output | API key |
|---|---|---|
| `scripts/build.sh` | `bin/GridStatus.prg` | None; read from the app setting |
| `scripts/build_sideload.sh` | `bin/GridStatusSideload.prg` | Compiled in |

Settings can't be edited on a sideloaded app, so use the sideload build on your own watch. **Never share or publish that build, or the `bin/GridStatusSideload-settings.json` written beside it.** The key comes from `GRIDSTATUS_API_KEY`, falling back to the gitignored `.env` in the repository root, and is also written to the gitignored `resources-local/properties.xml`.

To target another device, add it to `manifest.xml` and set `GRIDSTATUS_DEVICE`.

## Test

Open the simulator, then run the unit tests:

```bash
open -a /Applications/ConnectIQ.app
scripts/test.sh
```

To run the app in the simulator:

```bash
monkeydo bin/GridStatusSideload.prg fr255m
```

The simulator keeps settings between builds, so after running a keyless build the sideload build also shows "Add your API key". Clear it with **File > Reset All App Data**. To try a key in the keyless build, use **File > Edit Persistent Storage > Edit Application.Properties data**.

## Install on your own watch

Connect the watch by USB and set **Settings > System > USB Mode** to **MTP**. Quit Garmin Express and OpenMTP if they're running. Then find the ID of the `GARMIN/Apps` folder and send the app using that ID, because `mtp-sendfile` can't resolve the folder by path:

```bash
brew install libmtp
mtp-folders 2>/dev/null | grep Apps
mtp-sendfile bin/GridStatusSideload.prg <Apps folder ID>/GridStatus.prg
```

Unplug the watch to finish the install. The watch fetches data through the Garmin Connect app, so your phone must be connected.
