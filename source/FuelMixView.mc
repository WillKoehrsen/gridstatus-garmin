import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class FuelMixView extends WatchUi.View {
    private const BAR_LEFT_PERCENT = 15;
    private const BAR_WIDTH_PERCENT = 70;
    private const BAR_TOP_PERCENT = 22;
    private const BAR_HEIGHT_PERCENT = 5;

    private var _iso as String;
    private var _client as DatasetClient;

    function initialize(iso as String, client as DatasetClient) {
        View.initialize();
        _iso = iso;
        _client = client;
    }

    function onUpdate(dc as Dc) as Void {
        Screen.clear(dc);

        var rows = _client.getRows();
        Screen.drawCentered(dc, 13, Graphics.FONT_SMALL, _iso.toUpper());
        if (rows == null) {
            Screen.drawCentered(dc, 50, Graphics.FONT_SMALL, Screen.statusMessage(_client));
            return;
        }

        var displayRows = FuelMix.summarize(rows[0]);
        drawBar(dc, displayRows);
        drawRows(dc, displayRows);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        Screen.drawCentered(dc, 90, Graphics.FONT_XTINY, footerText(rows[0]));
    }

    private function drawBar(dc as Dc, displayRows as Array<Dictionary>) as Void {
        var barWidth = dc.getWidth() * BAR_WIDTH_PERCENT / 100;
        var barHeight = dc.getHeight() * BAR_HEIGHT_PERCENT / 100;
        var top = dc.getHeight() * BAR_TOP_PERCENT / 100;
        var left = dc.getWidth() * BAR_LEFT_PERCENT / 100;
        var cumulativeShare = 0.0;
        for (var index = 0; index < displayRows.size(); index++) {
            var start = (cumulativeShare * barWidth).toNumber();
            cumulativeShare += displayRows[index][:share] as Float;
            var end = (cumulativeShare * barWidth).toNumber();
            dc.setColor(displayRows[index][:color] as Number, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left + start, top, end - start, barHeight);
        }
    }

    private function drawRows(dc as Dc, displayRows as Array<Dictionary>) as Void {
        var swatchSize = dc.getWidth() * 3 / 100;
        for (var index = 0; index < displayRows.size(); index++) {
            var displayRow = displayRows[index];
            var heightPercent = 36 + index * 11;
            dc.setColor(displayRow[:color] as Number, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(dc.getWidth() * 15 / 100, dc.getHeight() * heightPercent / 100 - swatchSize / 2, swatchSize, swatchSize);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            Screen.draw(dc, 20, heightPercent, Graphics.FONT_XTINY, displayRow[:label] as String, Graphics.TEXT_JUSTIFY_LEFT);
            Screen.draw(dc, 85, heightPercent, Graphics.FONT_XTINY, FuelMix.formatShare(displayRow[:share] as Float), Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    private function footerText(row as Dictionary) as String {
        if (_client.isFetching()) {
            return "Refreshing...";
        }
        var failureMessage = _client.getFailureMessage();
        if (failureMessage != null) {
            return failureMessage;
        }
        var age = Formatting.formatAge(row["interval_end_utc"] as String?, Time.now());
        return age.equals("now") ? "Now" : age + " ago";
    }
}
