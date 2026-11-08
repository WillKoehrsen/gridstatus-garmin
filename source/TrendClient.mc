import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Fetches one value for the last 24 hours as hourly averages, and keeps only each hour's start and value.
class TrendClient extends DatasetClient {
    private var _valueColumn as String;
    private var _location as String?;

    // Load comes from each ISO's hourly standardized dataset, which is already one row per hour.
    static function forLoad(iso as String) as TrendClient {
        return new TrendClient(iso + "_standardized_hourly", "load.load", null);
    }

    // The price is the real-time price at the hub the current conditions report, averaged over each hour.
    static function forPrice(iso as String, location as String) as TrendClient {
        var datasetId = iso + "_lmp_real_time_5_min";
        if (iso.equals("ercot")) {
            datasetId = "ercot_lmp_by_settlement_point";
        } else if (iso.equals("ieso")) {
            datasetId = "ieso_lmp_real_time_5_min_ontario_zonal";
        }
        return new TrendClient(datasetId, "lmp", location);
    }

    function initialize(datasetId as String, valueColumn as String, location as String?) {
        DatasetClient.initialize(datasetId, null);
        _valueColumn = valueColumn;
        _location = location;
    }

    protected function requestParameters() as Dictionary<Object, Object>? {
        var windowEnd = Trend.windowEndSeconds(Time.now().value());
        var parameters = {
            "start_time" => Trend.formatUtcHour(windowEnd - Trend.WINDOW_SECONDS),
            // The end is exclusive, so it reaches past the start of the current hour to include that hour.
            "end_time" => Trend.formatUtcHour(windowEnd + Trend.HOUR_SECONDS),
            "columns" => "interval_start_utc," + _valueColumn
        } as Dictionary<Object, Object>;
        if (_location != null) {
            parameters["filter_column"] = "location";
            parameters["filter_value"] = _location;
            parameters["resample_frequency"] = "1 hour";
            parameters["resample_function"] = "mean";
        }
        return parameters;
    }

    protected function keepRows(rows as Array<Dictionary>) as Array<Dictionary> {
        return Trend.toPoints(rows, _valueColumn);
    }
}

module Trend {
    const HOUR_SECONDS = 3600;
    const WINDOW_SECONDS = 24 * HOUR_SECONDS;
    const TIME_KEY = "t";
    const VALUE_KEY = "v";

    // The start of the current hour, where the chart's time axis ends.
    function windowEndSeconds(nowSeconds as Number) as Number {
        return nowSeconds - nowSeconds % HOUR_SECONDS;
    }

    // The API's time format, for example 2026-11-07T13:00:00Z.
    function formatUtcHour(seconds as Number) as String {
        var info = Gregorian.utcInfo(new Time.Moment(seconds), Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$T$4$:00:00Z", [
            info.year.format("%04d"),
            (info.month as Number).format("%02d"),
            info.day.format("%02d"),
            info.hour.format("%02d")
        ]);
    }

    // Each hour's start in seconds and its value, skipping hours without one.
    function toPoints(rows as Array<Dictionary>, valueColumn as String) as Array<Dictionary> {
        var points = [] as Array<Dictionary>;
        for (var index = 0; index < rows.size(); index++) {
            var start = Formatting.parseUtcTimestamp(rows[index]["interval_start_utc"] as String?);
            var value = rows[index][valueColumn];
            if (start != null && (value instanceof Number || value instanceof Float || value instanceof Double || value instanceof Long)) {
                points.add({TIME_KEY => start.value(), VALUE_KEY => (value as Numeric).toFloat()});
            }
        }
        return points;
    }
}
