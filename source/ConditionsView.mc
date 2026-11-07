import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class ConditionsView extends WatchUi.View {
    private var _client as ConditionsClient;
    private var _pageIndex as Number = 0;

    function initialize(client as ConditionsClient) {
        View.initialize();
        _client = client;
    }

    function showNextPage() as Void {
        movePage(1);
    }

    function showPreviousPage() as Void {
        movePage(-1);
    }

    private function movePage(offset as Number) as Void {
        var rows = _client.getRows();
        if (rows == null) {
            return;
        }
        _pageIndex = (_pageIndex + offset + rows.size()) % rows.size();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var rows = _client.getRows();
        if (rows == null) {
            drawMessage(dc);
        } else {
            drawPage(dc, rows);
        }
    }

    private function drawMessage(dc as Dc) as Void {
        var failureMessage = _client.getFailureMessage();
        var message = (_client.isFetching() || failureMessage == null)
            ? "Loading..."
            : failureMessage + "\nPress START\nto retry";
        drawLine(dc, 50, Graphics.FONT_SMALL, message);
    }

    private function drawPage(dc as Dc, rows as Array<Dictionary>) as Void {
        if (_pageIndex >= rows.size()) {
            _pageIndex = 0;
        }
        var row = rows[_pageIndex];
        var now = Time.now();

        var load = Formatting.formatGigawatts(row["latest_load"] as Numeric?);
        var netLoad = Formatting.formatGigawatts(row["latest_net_load"] as Numeric?);
        var price = Formatting.formatPrice(row["latest_lmp"] as Numeric?);
        var fuel = Formatting.formatFuel(row["latest_primary_power_source"] as String?);
        var location = row["latest_lmp_location"] as String?;

        drawLine(dc, 13, Graphics.FONT_SMALL, (row["iso"] as String).toUpper());
        drawLine(dc, 29, Graphics.FONT_MEDIUM, Formatting.withAge(load, row["load_time_utc"] as String?, now));
        drawLine(dc, 43, Graphics.FONT_TINY, "Net " + Formatting.withAge(netLoad, row["net_load_time_utc"] as String?, now));
        drawLine(dc, 55, Graphics.FONT_TINY, Formatting.withAge(price, row["lmp_time_utc"] as String?, now));
        drawLine(dc, 65, Graphics.FONT_XTINY, location != null ? location : Formatting.NO_VALUE);
        drawLine(dc, 76, Graphics.FONT_TINY, Formatting.withAge(fuel, row["primary_power_source_time_utc"] as String?, now));
        drawLine(dc, 89, Graphics.FONT_XTINY, footerText(rows.size()));
    }

    private function footerText(pageCount as Number) as String {
        if (_client.isFetching()) {
            return "Refreshing...";
        }
        var failureMessage = _client.getFailureMessage();
        if (failureMessage != null) {
            return failureMessage;
        }
        return (_pageIndex + 1) + "/" + pageCount;
    }

    private function drawLine(dc as Dc, heightPercent as Number, font as FontDefinition, text as String) as Void {
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() * heightPercent / 100,
            font,
            text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
