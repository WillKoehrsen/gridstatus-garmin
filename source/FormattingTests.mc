import Toybox.Communications;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

// 2026-11-07T00:05:00Z
const REFERENCE_EPOCH_SECONDS = 1794009900;

(:test)
function parsesTimestampAsUtc(logger as Logger) as Boolean {
    var moment = Formatting.parseUtcTimestamp("2026-11-07T00:05:00+00:00");
    Test.assert(moment != null);
    Test.assertEqual((moment as Moment).value(), REFERENCE_EPOCH_SECONDS);
    return true;
}

(:test)
function rejectsUnreadableTimestamps(logger as Logger) as Boolean {
    Test.assert(Formatting.parseUtcTimestamp(null) == null);
    Test.assert(Formatting.parseUtcTimestamp("2026-11-07") == null);
    Test.assert(Formatting.parseUtcTimestamp("not-a-timestamp-at-all") == null);
    return true;
}

(:test)
function formatsAges(logger as Logger) as Boolean {
    var timestamp = "2026-11-07T00:05:00+00:00";
    Test.assertEqual(Formatting.formatAge(timestamp, new Moment(REFERENCE_EPOCH_SECONDS - 600)), "now");
    Test.assertEqual(Formatting.formatAge(timestamp, new Moment(REFERENCE_EPOCH_SECONDS + 59)), "now");
    Test.assertEqual(Formatting.formatAge(timestamp, new Moment(REFERENCE_EPOCH_SECONDS + 300)), "5m");
    Test.assertEqual(Formatting.formatAge(timestamp, new Moment(REFERENCE_EPOCH_SECONDS + 3900)), "1h");
    Test.assertEqual(Formatting.formatAge(timestamp, new Moment(REFERENCE_EPOCH_SECONDS + 259200)), "3d");
    Test.assertEqual(Formatting.formatAge(null, new Moment(REFERENCE_EPOCH_SECONDS)), "--");
    return true;
}

(:test)
function formatsGigawatts(logger as Logger) as Boolean {
    Test.assertEqual(Formatting.formatGigawatts(55953.0), "55.95 GW");
    Test.assertEqual(Formatting.formatGigawatts(93277), "93.28 GW");
    Test.assertEqual(Formatting.formatGigawatts(null), "--");
    return true;
}

(:test)
function formatsPrices(logger as Logger) as Boolean {
    Test.assertEqual(Formatting.formatPrice(57.0), "$57.00/MWh");
    Test.assertEqual(Formatting.formatPrice(-3.2), "-$3.20/MWh");
    Test.assertEqual(Formatting.formatPrice(0), "$0.00/MWh");
    Test.assertEqual(Formatting.formatPrice(null), "--");
    return true;
}

(:test)
function formatsFuels(logger as Logger) as Boolean {
    Test.assertEqual(Formatting.formatFuel("natural_gas"), "Natural Gas");
    Test.assertEqual(Formatting.formatFuel("gas"), "Gas");
    Test.assertEqual(Formatting.formatFuel("dual_fuel"), "Dual Fuel");
    Test.assertEqual(Formatting.formatFuel(null), "--");
    return true;
}

(:test)
function formatsOverviewValues(logger as Logger) as Boolean {
    Test.assertEqual(Formatting.formatLoadNumber(91520.0), "91.5");
    Test.assertEqual(Formatting.formatLoadNumber(null), "--");
    Test.assertEqual(Formatting.formatWholePrice(278.23), "$278");
    Test.assertEqual(Formatting.formatWholePrice(-3.7), "-$4");
    Test.assertEqual(Formatting.formatWholePrice(null), "--");
    return true;
}

// Values from caiso_fuel_mix on 2026-11-07, including a negative solar value.
(:test)
function summarizesFuelMixIgnoringNegativeValues(logger as Logger) as Boolean {
    var displayRows = FuelMix.summarize({
        "interval_start_utc" => "2026-11-07T01:50:00+00:00",
        "interval_end_utc" => "2026-11-07T01:55:00+00:00",
        "solar" => -73,
        "wind" => 970,
        "geothermal" => 794,
        "biomass" => 163,
        "biogas" => 155,
        "small_hydro" => 124,
        "coal" => 4,
        "nuclear" => 1099,
        "natural_gas" => 11467,
        "large_hydro" => 1886,
        "batteries" => 6409,
        "imports" => 3838,
        "other" => 0
    });
    Test.assertEqual(displayRows.size(), 5);
    Test.assertEqual(displayRows[0][:label], "Natural Gas");
    Test.assertEqual(FuelMix.formatShare(displayRows[0][:share] as Float), "43%");
    Test.assertEqual(displayRows[1][:label], "Batteries");
    Test.assertEqual(displayRows[2][:label], "Imports");
    Test.assertEqual(displayRows[3][:label], "Large Hydro");
    Test.assertEqual(displayRows[4][:label], "Others");
    Test.assertEqual(FuelMix.formatShare(displayRows[4][:share] as Float), "12%");
    return true;
}

// Values from isone_fuel_mix on 2026-11-07, including a null coal value.
(:test)
function summarizesFuelMixIgnoringNulls(logger as Logger) as Boolean {
    var displayRows = FuelMix.summarize({
        "coal" => null,
        "natural_gas" => 7352.0,
        "nuclear" => 2109.0,
        "wind" => 1215.0
    });
    Test.assertEqual(displayRows.size(), 3);
    Test.assertEqual(displayRows[2][:label], "Wind");
    Test.assertEqual(FuelMix.formatShare(displayRows[2][:share] as Float), "11%");
    return true;
}

(:test)
function shortensLongFuelLabels(logger as Logger) as Boolean {
    Test.assertEqual(FuelMix.shorten("Waste Disposal Services"), "Waste Disposal Ser");
    Test.assertEqual(FuelMix.shorten("Wind"), "Wind");
    return true;
}

(:test)
function decidesFreshness(logger as Logger) as Boolean {
    Test.assert(Formatting.isFresh(1000, 1299));
    Test.assert(!Formatting.isFresh(1000, 1300));
    Test.assert(!Formatting.isFresh(1000, 999));
    Test.assert(!Formatting.isFresh(null, 1000));
    return true;
}

(:test)
function trimsWhitespace(logger as Logger) as Boolean {
    Test.assertEqual(Formatting.trim("abc123"), "abc123");
    Test.assertEqual(Formatting.trim(" abc123\n"), "abc123");
    Test.assertEqual(Formatting.trim("\t abc 123 \r\n"), "abc 123");
    Test.assertEqual(Formatting.trim("   "), "");
    Test.assertEqual(Formatting.trim(""), "");
    return true;
}

(:test)
function describesFailures(logger as Logger) as Boolean {
    Test.assertEqual(Formatting.describeFailure(Communications.BLE_CONNECTION_UNAVAILABLE), "Phone offline");
    Test.assertEqual(Formatting.describeFailure(400), "Bad API key");
    Test.assertEqual(Formatting.describeFailure(401), "Bad API key");
    Test.assertEqual(Formatting.describeFailure(403), "Bad API key");
    Test.assertEqual(Formatting.describeFailure(429), "Limit reached");
    Test.assertEqual(Formatting.describeFailure(200), "No data");
    Test.assertEqual(Formatting.describeFailure(500), "Error 500");
    return true;
}
