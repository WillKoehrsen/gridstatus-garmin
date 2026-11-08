# Connect IQ Store listing

Text and steps for publishing the app. Garmin's [App Review Guidelines](https://developer.garmin.com/connect-iq/app-review-guidelines/) require the description to list every dependency and limitation.

## Before submitting

1. Check that a Free plan API key can read `isos_latest`, the `{iso}_fuel_mix` and `{iso}_standardized_hourly` datasets, and the real-time price datasets the price chart uses (`{iso}_lmp_real_time_5_min`, `ercot_lmp_by_settlement_point` and `ieso_lmp_real_time_5_min_ontario_zonal`). If it can't, say in the description which plan is required.
2. Run `scripts/package.sh --beta` and upload `bin/GridStatusBeta.iq` with **Beta App** checked. Only your account can see a beta. Install it, enter a key in Garmin Connect, and check the app loads.
3. Run `scripts/package.sh` and upload `bin/GridStatus.iq` without the beta box checked.

## Name

Grid Status

## Description

Current electricity grid conditions for CAISO, ERCOT, IESO, ISO-NE, MISO, NYISO, PJM and SPP, from the Grid Status API.

- Overview: load and hub price for every grid operator on one screen.
- Price map: each grid operator colored by its hub price, with the price on the map.
- Grid operator pages: load, net load, hub price and primary fuel, with the age of each value.
- Fuel mix: the largest sources of generation, as a colored bar with percentages. Press START on a grid operator's page to open it.
- Charts: load and hub price over the last 24 hours. Press DOWN from the fuel mix to reach them.
- Glance: the last grid operator you viewed, without using any API quota.

Requirements:

- A Grid Status API key. Create one at https://www.gridstatus.io/settings/api, then paste it into the app's settings in Garmin Connect.
- A phone connected to your watch. The watch fetches data through Garmin Connect.
- API quota. The overview, price map, grid operator pages and glance share one request, and each fuel mix, load chart and price chart is one more. The app reuses each response for 5 minutes. The Free plan allows 250 requests a month.

Privacy: https://github.com/WillKoehrsen/gridstatus-garmin/blob/main/PRIVACY.md

Support and source code: https://github.com/WillKoehrsen/gridstatus-garmin/issues

## Screenshots

`docs/screenshots/overview.png`, `iso.png` and `fuel_mix.png`, taken on a Forerunner 255 Music.

## Category

Tools
