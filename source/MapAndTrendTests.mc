import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

(:test)
function formatsUtcHours(logger as Logger) as Boolean {
    Test.assertEqual(Trend.formatUtcHour(REFERENCE_EPOCH_SECONDS - 300), "2026-11-07T00:00:00Z");
    Test.assertEqual(Trend.formatUtcHour(REFERENCE_EPOCH_SECONDS - 300 - Trend.HOUR_SECONDS), "2026-11-06T23:00:00Z");
    return true;
}

(:test)
function endsTheChartAtTheStartOfTheHour(logger as Logger) as Boolean {
    Test.assertEqual(Trend.windowEndSeconds(REFERENCE_EPOCH_SECONDS), REFERENCE_EPOCH_SECONDS - 300);
    Test.assertEqual(Trend.windowEndSeconds(REFERENCE_EPOCH_SECONDS - 300), REFERENCE_EPOCH_SECONDS - 300);
    return true;
}

(:test)
function keepsHoursThatHaveValues(logger as Logger) as Boolean {
    var points = Trend.toPoints([
        {"interval_start_utc" => "2026-11-07T00:00:00+00:00", "lmp" => 21.5},
        {"interval_start_utc" => "2026-11-07T01:00:00+00:00", "lmp" => null},
        {"interval_start_utc" => "2026-11-07T02:00:00+00:00", "lmp" => -3}
    ] as Array<Dictionary>, "lmp");
    Test.assertEqual(points.size(), 2);
    Test.assertEqual(points[0][Trend.TIME_KEY], REFERENCE_EPOCH_SECONDS - 300);
    Test.assertEqual(points[0][Trend.VALUE_KEY], 21.5);
    Test.assertEqual(points[1][Trend.VALUE_KEY], -3.0);
    return true;
}

(:test)
function colorsPricesByBand(logger as Logger) as Boolean {
    Test.assertEqual(PriceMap.colorForPrice(null), Graphics.COLOR_LT_GRAY);
    Test.assertEqual(PriceMap.colorForPrice(-0.5), 0x0055FF);
    Test.assertEqual(PriceMap.colorForPrice(0), 0x00AA00);
    Test.assertEqual(PriceMap.colorForPrice(24.99), 0x00AA00);
    Test.assertEqual(PriceMap.colorForPrice(25), 0xAAAA00);
    Test.assertEqual(PriceMap.colorForPrice(99.9), 0xFFAA00);
    Test.assertEqual(PriceMap.colorForPrice(100), 0xFF5500);
    Test.assertEqual(PriceMap.colorForPrice(250), 0xFF0000);
    return true;
}

// Connect IQ fills polygons of at most 64 points, so a regenerated map must stay within that.
(:test)
function mapPolygonsFitTheDrawingLimit(logger as Logger) as Boolean {
    var map = WatchUi.loadResource(Rez.JsonData.MapShapes) as Dictionary;
    var regions = map["regions"] as Array<Dictionary>;
    var labeledIsos = [] as Array<String>;
    for (var index = 0; index < regions.size(); index++) {
        var rings = regions[index]["rings"] as Array<Array<Number>>;
        for (var ringIndex = 0; ringIndex < rings.size(); ringIndex++) {
            Test.assertEqual(rings[ringIndex].size() % 2, 0);
            Test.assert(rings[ringIndex].size() / 2 >= 3);
            Test.assert(rings[ringIndex].size() / 2 <= 64);
        }
        if (regions[index]["label"] != null) {
            labeledIsos.add(regions[index]["iso"] as String);
        }
    }
    var isos = ["caiso", "ercot", "ieso", "isone", "miso", "nyiso", "pjm", "spp"];
    for (var index = 0; index < isos.size(); index++) {
        Test.assert(labeledIsos.indexOf(isos[index]) >= 0);
    }
    return true;
}
