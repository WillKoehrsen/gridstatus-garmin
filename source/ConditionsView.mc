import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Page 0 is the overview of every ISO, and each later page is one ISO.
class ConditionsView extends WatchUi.View {
    private const OVERVIEW_PAGE_INDEX = 0;

    private var _client as DatasetClient;
    private var _pageIndex as Number;

    function initialize(client as DatasetClient) {
        View.initialize();
        _client = client;
        var savedPageIndex = Application.Storage.getValue(AppData.PAGE_INDEX_KEY);
        _pageIndex = savedPageIndex instanceof Number ? savedPageIndex : OVERVIEW_PAGE_INDEX;
    }

    function showNextPage() as Void {
        movePage(1);
    }

    function showPreviousPage() as Void {
        movePage(-1);
    }

    // The ISO row on screen, or null on the overview or before any data has loaded.
    function getSelectedRow() as Dictionary? {
        var rows = _client.getRows();
        if (rows == null || _pageIndex == OVERVIEW_PAGE_INDEX || _pageIndex > rows.size()) {
            return null;
        }
        return rows[_pageIndex - 1];
    }

    function onHide() as Void {
        Application.Storage.setValue(AppData.PAGE_INDEX_KEY, _pageIndex);
    }

    private function movePage(offset as Number) as Void {
        var rows = _client.getRows();
        if (rows == null) {
            return;
        }
        var pageCount = rows.size() + 1;
        _pageIndex = (_pageIndex + offset + pageCount) % pageCount;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        Screen.clear(dc);

        var rows = _client.getRows();
        if (!_client.hasApiKey()) {
            Screen.drawCentered(dc, 50, Graphics.FONT_SMALL, "Add your API key\nin Garmin Connect");
        } else if (rows == null) {
            Screen.drawCentered(dc, 50, Graphics.FONT_SMALL, Screen.statusMessage(_client));
        } else if (_pageIndex == OVERVIEW_PAGE_INDEX || _pageIndex > rows.size()) {
            _pageIndex = OVERVIEW_PAGE_INDEX;
            drawOverview(dc, rows);
        } else {
            drawIsoPage(dc, rows[_pageIndex - 1], rows.size());
        }
    }

    private function drawOverview(dc as Dc, rows as Array<Dictionary>) as Void {
        var rowHeightPercent = 8;
        var font = Graphics.FONT_XTINY;
        Screen.draw(dc, 62, 18, font, "GW", Graphics.TEXT_JUSTIFY_RIGHT);
        Screen.draw(dc, 84, 18, font, "$/MWh", Graphics.TEXT_JUSTIFY_RIGHT);
        for (var index = 0; index < rows.size(); index++) {
            var row = rows[index];
            var heightPercent = 26 + index * rowHeightPercent;
            Screen.draw(dc, 16, heightPercent, font, (row["iso"] as String).toUpper(), Graphics.TEXT_JUSTIFY_LEFT);
            Screen.draw(dc, 62, heightPercent, font, Formatting.formatLoadNumber(row["latest_load"] as Numeric?), Graphics.TEXT_JUSTIFY_RIGHT);
            Screen.draw(dc, 84, heightPercent, font, Formatting.formatWholePrice(row["latest_lmp"] as Numeric?), Graphics.TEXT_JUSTIFY_RIGHT);
        }
        Screen.drawCentered(dc, 90, font, footerText(""));
    }

    private function drawIsoPage(dc as Dc, row as Dictionary, isoCount as Number) as Void {
        var now = Time.now();
        var load = Formatting.formatGigawatts(row["latest_load"] as Numeric?);
        var netLoad = Formatting.formatGigawatts(row["latest_net_load"] as Numeric?);
        var price = Formatting.formatPrice(row["latest_lmp"] as Numeric?);
        var fuel = Formatting.formatFuel(row["latest_primary_power_source"] as String?);
        var location = row["latest_lmp_location"] as String?;

        Screen.drawCentered(dc, 13, Graphics.FONT_SMALL, (row["iso"] as String).toUpper());
        Screen.drawCentered(dc, 29, Graphics.FONT_MEDIUM, Formatting.withAge(load, row["load_time_utc"] as String?, now));
        Screen.drawCentered(dc, 43, Graphics.FONT_TINY, "Net " + Formatting.withAge(netLoad, row["net_load_time_utc"] as String?, now));
        Screen.drawCentered(dc, 55, Graphics.FONT_TINY, Formatting.withAge(price, row["lmp_time_utc"] as String?, now));
        Screen.drawCentered(dc, 65, Graphics.FONT_XTINY, location != null ? location : Formatting.NO_VALUE);
        Screen.drawCentered(dc, 76, Graphics.FONT_TINY, Formatting.withAge(fuel, row["primary_power_source_time_utc"] as String?, now));
        Screen.drawCentered(dc, 89, Graphics.FONT_XTINY, footerText(_pageIndex + "/" + isoCount + "  "));
    }

    private function footerText(prefix as String) as String {
        if (_client.isFetching()) {
            return "Refreshing...";
        }
        var failureMessage = _client.getFailureMessage();
        if (failureMessage != null) {
            return failureMessage;
        }
        var secondsSinceFetch = _client.getSecondsSinceFetch();
        if (secondsSinceFetch == null) {
            return prefix;
        }
        return prefix + "Updated " + Formatting.formatElapsedSeconds(secondsSinceFetch);
    }
}
