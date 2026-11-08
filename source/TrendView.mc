import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// A chart of one ISO's load or price over the last 24 hours.
class TrendView extends WatchUi.View {
    private const RANGE_PERCENT = 25;
    private const CHART_TOP_PERCENT = 33;
    private const CHART_BOTTOM_PERCENT = 77;
    // On square screens the chart still leaves a margin of 10% on each side.
    private const MAXIMUM_HALF_WIDTH_PERCENT = 40;

    private var _title as String;
    private var _client as DatasetClient;
    private var _isPrice as Boolean;

    function initialize(title as String, client as DatasetClient, isPrice as Boolean) {
        View.initialize();
        _title = title;
        _client = client;
        _isPrice = isPrice;
    }

    function onUpdate(dc as Dc) as Void {
        Screen.clear(dc);
        Screen.drawCentered(dc, 13, Graphics.FONT_SMALL, _title);

        var points = _client.getRows();
        if (points == null) {
            Screen.drawCentered(dc, 50, Graphics.FONT_SMALL, Screen.statusMessage(_client));
            return;
        }

        var lowest = points[0][Trend.VALUE_KEY] as Float;
        var highest = lowest;
        for (var index = 1; index < points.size(); index++) {
            var value = points[index][Trend.VALUE_KEY] as Float;
            lowest = value < lowest ? value : lowest;
            highest = value > highest ? value : highest;
        }
        Screen.drawCentered(dc, RANGE_PERCENT, Graphics.FONT_XTINY, "24h: " + format(lowest) + " to " + format(highest) + (_isPrice ? "" : " GW"));
        drawChart(dc, points, lowest, highest);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        Screen.drawFooter(dc, dc.getHeight() * 89 / 100, footerText());
    }

    private function format(value as Float) as String {
        return _isPrice ? Formatting.formatWholePrice(value) : Formatting.formatLoadNumber(value);
    }

    // Hourly points from 24 hours ago to the current hour, with the area below the line filled. Prices fill to zero, so negative hours fill upward.
    private function drawChart(dc as Dc, points as Array<Dictionary>, lowest as Float, highest as Float) as Void {
        var top = dc.getHeight() * CHART_TOP_PERCENT / 100;
        var bottom = dc.getHeight() * CHART_BOTTOM_PERCENT / 100;
        var halfWidth = Screen.availableHalfWidth(dc, (top + bottom) / 2, bottom - top);
        var maximumHalfWidth = dc.getWidth() * MAXIMUM_HALF_WIDTH_PERCENT / 100;
        halfWidth = halfWidth < maximumHalfWidth ? halfWidth : maximumHalfWidth;
        var left = dc.getWidth() / 2 - halfWidth;
        var width = halfWidth * 2;
        if (highest - lowest < 0.01) {
            highest = lowest + 1.0;
        }

        var windowEnd = Trend.windowEndSeconds(Time.now().value());
        var windowStart = windowEnd - Trend.WINDOW_SECONDS;
        var line = [] as Array<Point2D>;
        for (var index = 0; index < points.size(); index++) {
            var time = points[index][Trend.TIME_KEY] as Number;
            if (time >= windowStart && time <= windowEnd) {
                var x = left + (time - windowStart).toFloat() * width / Trend.WINDOW_SECONDS;
                var y = bottom - ((points[index][Trend.VALUE_KEY] as Float) - lowest) * (bottom - top) / (highest - lowest);
                line.add([x, y] as Point2D);
            }
        }
        if (line.size() == 0) {
            Screen.drawCentered(dc, 55, Graphics.FONT_XTINY, "No recent hours");
            return;
        }

        var baseline = bottom.toFloat();
        if (_isPrice && lowest < 0) {
            baseline = highest <= 0 ? top.toFloat() : bottom - (0 - lowest) * (bottom - top) / (highest - lowest);
        }
        var area = line.slice(0, null);
        area.add([line[line.size() - 1][0], baseline] as Point2D);
        area.add([line[0][0], baseline] as Point2D);
        dc.setColor(_isPrice ? 0xAA5500 : 0x0055AA, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(area);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(left, baseline, left + width, baseline);

        var penWidth = dc.getWidth() / 120;
        penWidth = penWidth > 2 ? penWidth : 2;
        dc.setColor(_isPrice ? 0xFFAA00 : 0x00AAFF, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(penWidth);
        for (var index = 1; index < line.size(); index++) {
            dc.drawLine(line[index - 1][0], line[index - 1][1], line[index][0], line[index][1]);
        }
        var last = line[line.size() - 1];
        dc.fillCircle(last[0], last[1], penWidth + 1);
        dc.setPenWidth(1);
    }

    private function footerText() as String {
        if (_client.isFetching()) {
            return "Refreshing...";
        }
        var failureMessage = _client.getFailureMessage();
        if (failureMessage != null) {
            return failureMessage;
        }
        var secondsSinceFetch = _client.getSecondsSinceFetch();
        return secondsSinceFetch == null ? "" : "Updated " + Formatting.formatElapsedSeconds(secondsSinceFetch);
    }
}
