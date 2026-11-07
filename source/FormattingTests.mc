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
    Test.assertEqual(Formatting.describeFailure(Communications.BLE_CONNECTION_UNAVAILABLE), "Phone not connected");
    Test.assertEqual(Formatting.describeFailure(400), "API key rejected");
    Test.assertEqual(Formatting.describeFailure(401), "API key rejected");
    Test.assertEqual(Formatting.describeFailure(403), "API key rejected");
    Test.assertEqual(Formatting.describeFailure(429), "Limit reached");
    Test.assertEqual(Formatting.describeFailure(200), "No data returned");
    Test.assertEqual(Formatting.describeFailure(500), "Error 500");
    return true;
}
