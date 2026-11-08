import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class FuelMixView extends WatchUi.View {
    private const BAR_TOP_PERCENT = 22;
    private const BAR_HEIGHT_PERCENT = 5;
    // Rows sit at these heights, as percentages of the screen.
    private const FIRST_ROW_PERCENT = 36;
    private const ROW_STEP_PERCENT = 11;
    // On square screens rows still leave a margin of 10% on each side.
    private const MAXIMUM_HALF_WIDTH_PERCENT = 40;

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
        var halfWidth = rowsHalfWidth(dc, displayRows.size());
        drawBar(dc, displayRows, halfWidth);
        drawRows(dc, displayRows, halfWidth);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        Screen.drawFooter(dc, dc.getHeight() * 90 / 100, footerText(rows[0]));
    }

    // The widest the rows can be while every row stays inside the screen, so all rows share one left and right edge.
    private function rowsHalfWidth(dc as Dc, rowCount as Number) as Number {
        var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY);
        var halfWidth = dc.getWidth() * MAXIMUM_HALF_WIDTH_PERCENT / 100;
        for (var index = 0; index < rowCount; index++) {
            var available = Screen.availableHalfWidth(dc, rowY(dc, index), lineHeight);
            if (available < halfWidth) {
                halfWidth = available;
            }
        }
        return halfWidth;
    }

    private function rowY(dc as Dc, index as Number) as Number {
        return dc.getHeight() * (FIRST_ROW_PERCENT + index * ROW_STEP_PERCENT) / 100;
    }

    private function drawBar(dc as Dc, displayRows as Array<Dictionary>, halfWidth as Number) as Void {
        var barWidth = halfWidth * 2;
        var barHeight = dc.getHeight() * BAR_HEIGHT_PERCENT / 100;
        var top = dc.getHeight() * BAR_TOP_PERCENT / 100;
        var left = dc.getWidth() / 2 - halfWidth;
        var cumulativeShare = 0.0;
        for (var index = 0; index < displayRows.size(); index++) {
            var start = (cumulativeShare * barWidth).toNumber();
            cumulativeShare += displayRows[index][:share] as Float;
            var end = (cumulativeShare * barWidth).toNumber();
            dc.setColor(displayRows[index][:color] as Number, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left + start, top, end - start, barHeight);
        }
    }

    private function drawRows(dc as Dc, displayRows as Array<Dictionary>, halfWidth as Number) as Void {
        var font = Graphics.FONT_XTINY;
        var left = dc.getWidth() / 2 - halfWidth;
        var shareRight = dc.getWidth() / 2 + halfWidth;
        var swatchSize = dc.getWidth() * 3 / 100;
        var labelLeft = left + swatchSize * 2;
        var shares = [] as Array<String>;
        var widestShare = 0;
        for (var index = 0; index < displayRows.size(); index++) {
            shares.add(FuelMix.formatShare(displayRows[index][:share] as Float));
            var shareWidth = dc.getTextWidthInPixels(shares[index], font);
            if (shareWidth > widestShare) {
                widestShare = shareWidth;
            }
        }
        // Long labels are cut short of the widest share, so they never run into the percentages.
        var labelWidth = shareRight - labelLeft - widestShare - swatchSize;
        for (var index = 0; index < displayRows.size(); index++) {
            var displayRow = displayRows[index];
            var y = rowY(dc, index);
            dc.setColor(displayRow[:color] as Number, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left, y - swatchSize / 2, swatchSize, swatchSize);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var label = Screen.truncateToWidth(dc, displayRow[:label] as String, font, labelWidth);
            Screen.drawAt(dc, labelLeft, y, font, label, Graphics.TEXT_JUSTIFY_LEFT);
            Screen.drawAt(dc, shareRight, y, font, shares[index], Graphics.TEXT_JUSTIFY_RIGHT);
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
