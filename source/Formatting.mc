import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

module Formatting {
    const NO_VALUE = "--";

    function formatGigawatts(megawatts as Numeric?) as String {
        if (megawatts == null) {
            return NO_VALUE;
        }
        return (megawatts.toFloat() / 1000.0).format("%.2f") + " GW";
    }

    function formatPrice(pricePerMegawattHour as Numeric?) as String {
        if (pricePerMegawattHour == null) {
            return NO_VALUE;
        }
        var price = pricePerMegawattHour.toFloat();
        var sign = price < 0 ? "-" : "";
        return sign + "$" + price.abs().format("%.2f") + "/MWh";
    }

    // Source values differ by ISO (natural_gas, gas, dual_fuel), so they are shown as sent.
    function formatFuel(fuel as String?) as String {
        if (fuel == null) {
            return NO_VALUE;
        }
        var label = "";
        var remaining = fuel;
        var separatorIndex = remaining.find("_");
        while (separatorIndex != null) {
            label += capitalize(remaining.substring(0, separatorIndex) as String) + " ";
            remaining = remaining.substring(separatorIndex + 1, remaining.length()) as String;
            separatorIndex = remaining.find("_");
        }
        return label + capitalize(remaining);
    }

    function capitalize(word as String) as String {
        if (word.length() == 0) {
            return word;
        }
        var first = word.substring(0, 1) as String;
        var rest = word.substring(1, word.length()) as String;
        return first.toUpper() + rest;
    }

    // Expects the API's fixed UTC format, for example 2026-11-07T00:05:00+00:00.
    function parseUtcTimestamp(timestamp as String?) as Moment? {
        if (timestamp == null || timestamp.length() < 19) {
            return null;
        }
        var year = (timestamp.substring(0, 4) as String).toNumber();
        var month = (timestamp.substring(5, 7) as String).toNumber();
        var day = (timestamp.substring(8, 10) as String).toNumber();
        var hour = (timestamp.substring(11, 13) as String).toNumber();
        var minute = (timestamp.substring(14, 16) as String).toNumber();
        var second = (timestamp.substring(17, 19) as String).toNumber();
        if (year == null || month == null || day == null || hour == null || minute == null || second == null) {
            return null;
        }
        return Gregorian.moment({
            :year => year,
            :month => month,
            :day => day,
            :hour => hour,
            :minute => minute,
            :second => second
        });
    }

    function formatAge(timestamp as String?, now as Moment) as String {
        var moment = parseUtcTimestamp(timestamp);
        if (moment == null) {
            return NO_VALUE;
        }
        var seconds = now.value() - moment.value();
        if (seconds < 60) {
            return "now";
        }
        var minutes = seconds / 60;
        if (minutes < 60) {
            return minutes + "m";
        }
        var hours = minutes / 60;
        if (hours < 48) {
            return hours + "h";
        }
        return (hours / 24) + "d";
    }

    function withAge(value as String, timestamp as String?, now as Moment) as String {
        return value + "  " + formatAge(timestamp, now);
    }

    function describeFailure(responseCode as Number) as String {
        if (responseCode == Communications.BLE_CONNECTION_UNAVAILABLE) {
            return "Phone not connected";
        }
        // The API answers 400 for an invalid key and 401 for a missing one.
        if (responseCode == 400 || responseCode == 401 || responseCode == 403) {
            return "API key rejected";
        }
        if (responseCode == 429) {
            return "Limit reached";
        }
        if (responseCode == 200) {
            return "No data returned";
        }
        return "Error " + responseCode;
    }
}
