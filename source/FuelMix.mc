import Toybox.Graphics;
import Toybox.Lang;

module FuelMix {
    const MAXIMUM_ROW_COUNT = 5;
    const OTHERS_LABEL = "Others";
    const OTHERS_COLOR = 0xAAAAAA;
    const MAXIMUM_LABEL_LENGTH = 18;

    // Fuel columns differ by ISO, so every numeric column counts as a fuel. Only positive values count toward
    // the mix, because a negative value is a source drawing power, such as storage charging.
    function summarize(row as Dictionary) as Array<Dictionary> {
        var fuels = [] as Array<Dictionary>;
        var total = 0.0;
        var columns = row.keys();
        for (var index = 0; index < columns.size(); index++) {
            var value = row[columns[index]];
            if ((value instanceof Number || value instanceof Float || value instanceof Double || value instanceof Long) && value > 0) {
                total += value.toFloat();
                fuels.add({:fuel => columns[index], :megawatts => value.toFloat()});
            }
        }
        sortByMegawatts(fuels);
        return toDisplayRows(fuels, total);
    }

    function toDisplayRows(fuels as Array<Dictionary>, total as Float) as Array<Dictionary> {
        var displayRows = [] as Array<Dictionary>;
        var hasOthers = fuels.size() > MAXIMUM_ROW_COUNT;
        var namedCount = hasOthers ? MAXIMUM_ROW_COUNT - 1 : fuels.size();
        var namedTotal = 0.0;
        for (var index = 0; index < namedCount; index++) {
            var megawatts = fuels[index][:megawatts] as Float;
            var fuel = fuels[index][:fuel] as String;
            namedTotal += megawatts;
            displayRows.add({:label => shorten(Formatting.formatFuel(fuel)), :share => megawatts / total, :color => colorFor(fuel)});
        }
        if (hasOthers) {
            displayRows.add({:label => OTHERS_LABEL, :share => (total - namedTotal) / total, :color => OTHERS_COLOR});
        }
        return displayRows;
    }

    function sortByMegawatts(fuels as Array<Dictionary>) as Void {
        for (var index = 1; index < fuels.size(); index++) {
            var current = fuels[index];
            var position = index;
            while (position > 0 && (fuels[position - 1][:megawatts] as Float) < (current[:megawatts] as Float)) {
                fuels[position] = fuels[position - 1];
                position -= 1;
            }
            fuels[position] = current;
        }
    }

    function shorten(label as String) as String {
        return label.length() > MAXIMUM_LABEL_LENGTH ? label.substring(0, MAXIMUM_LABEL_LENGTH) as String : label;
    }

    function formatShare(share as Float) as String {
        return (share * 100).format("%.0f") + "%";
    }

    // Hues follow the fuel colors on gridstatus.io, snapped to the watch's limited palette.
    function colorFor(fuel as String) as Number {
        if (contains(fuel, "coal")) {
            return 0xFF5500;
        }
        if (contains(fuel, "gas") || contains(fuel, "dual_fuel") || contains(fuel, "multiple_fuels")) {
            return 0x55AAFF;
        }
        if (contains(fuel, "nuclear")) {
            return 0xAAFF00;
        }
        if (contains(fuel, "wind")) {
            return 0x55AA00;
        }
        if (contains(fuel, "solar")) {
            return 0xFFFF00;
        }
        if (contains(fuel, "hydro")) {
            return 0x00AAAA;
        }
        if (contains(fuel, "batter") || contains(fuel, "storage")) {
            return 0xAA55FF;
        }
        if (contains(fuel, "imports")) {
            return 0xFF5555;
        }
        return OTHERS_COLOR;
    }

    function contains(text as String, part as String) as Boolean {
        return text.find(part) != null;
    }
}
