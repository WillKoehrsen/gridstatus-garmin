import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Page 0 is the overview of every ISO, page 1 is the price map, and each later page is one ISO.
class ConditionsView extends WatchUi.View {
    private const OVERVIEW_PAGE_INDEX = 0;
    private const MAP_PAGE_INDEX = 1;
    private const FIRST_ISO_PAGE_INDEX = AppData.FIRST_ISO_PAGE_INDEX;

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

    // The ISO row on screen, or null on the overview and map or before any data has loaded.
    function getSelectedRow() as Dictionary? {
        var rows = _client.getRows();
        if (rows == null || _pageIndex < FIRST_ISO_PAGE_INDEX || _pageIndex >= rows.size() + FIRST_ISO_PAGE_INDEX) {
            return null;
        }
        return rows[_pageIndex - FIRST_ISO_PAGE_INDEX];
    }

    function onHide() as Void {
        Application.Storage.setValue(AppData.PAGE_INDEX_KEY, _pageIndex);
    }

    private function movePage(offset as Number) as Void {
        var rows = _client.getRows();
        if (rows == null) {
            return;
        }
        var pageCount = rows.size() + FIRST_ISO_PAGE_INDEX;
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
        } else if (_pageIndex == MAP_PAGE_INDEX) {
            drawMap(dc, rows);
        } else if (_pageIndex >= FIRST_ISO_PAGE_INDEX && _pageIndex < rows.size() + FIRST_ISO_PAGE_INDEX) {
            drawIsoPage(dc, rows[_pageIndex - FIRST_ISO_PAGE_INDEX], _pageIndex - FIRST_ISO_PAGE_INDEX + 1, rows.size());
        } else {
            _pageIndex = OVERVIEW_PAGE_INDEX;
            drawOverview(dc, rows);
        }
    }

    // The map fills the space between the title and the bottom line.
    private function drawMap(dc as Dc, rows as Array<Dictionary>) as Void {
        var titleY = dc.getHeight() * 13 / 100;
        var footerY = dc.getHeight() * 89 / 100;
        Screen.drawCentered(dc, 13, Graphics.FONT_SMALL, "PRICES");
        PriceMap.draw(
            dc,
            rows,
            titleY + dc.getFontHeight(Graphics.FONT_SMALL) / 2,
            footerY - dc.getFontHeight(Graphics.FONT_XTINY) / 2
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        Screen.drawFooter(dc, footerY, footerText(""));
    }

    // A table sized from its widest values and the font's height, so its columns and rows don't collide on any screen.
    private function drawOverview(dc as Dc, rows as Array<Dictionary>) as Void {
        var font = Graphics.FONT_XTINY;
        var isoColumn = [] as Array<String>;
        var loadColumn = ["GW"] as Array<String>;
        var priceColumn = ["$/MWh"] as Array<String>;
        for (var index = 0; index < rows.size(); index++) {
            isoColumn.add((rows[index]["iso"] as String).toUpper());
            loadColumn.add(Formatting.formatLoadNumber(rows[index]["latest_load"] as Numeric?));
            priceColumn.add(Formatting.formatWholePrice(rows[index]["latest_lmp"] as Numeric?));
        }
        var gap = dc.getWidth() * 5 / 100;
        var isoWidth = widestText(dc, isoColumn, font);
        var loadWidth = widestText(dc, loadColumn, font);
        var tableWidth = isoWidth + gap + loadWidth + gap + widestText(dc, priceColumn, font);
        var left = (dc.getWidth() - tableWidth) / 2;
        var loadRight = left + isoWidth + gap + loadWidth;
        var priceRight = left + tableWidth;

        var rowStep = dc.getFontHeight(font) * 9 / 10;
        var minimumRowStep = dc.getHeight() * 7 / 100;
        if (rowStep < minimumRowStep) {
            rowStep = minimumRowStep;
        }
        // The header, ISO rows and footer are evenly spaced and centered as one block.
        var headerY = dc.getHeight() / 2 - rowStep * (rows.size() + 1) / 2;
        // The header sits where a round screen is narrower, so the price unit moves in to fit and shortens if it would reach the load unit.
        var headerRight = dc.getWidth() / 2 + Screen.availableHalfWidth(dc, headerY, dc.getFontHeight(font));
        if (headerRight > priceRight) {
            headerRight = priceRight;
        }
        var priceHeader = priceColumn[0];
        if (headerRight - dc.getTextWidthInPixels(priceHeader, font) < loadRight + gap) {
            priceHeader = "$";
        }
        Screen.drawAt(dc, loadRight, headerY, font, loadColumn[0], Graphics.TEXT_JUSTIFY_RIGHT);
        Screen.drawAt(dc, headerRight, headerY, font, priceHeader, Graphics.TEXT_JUSTIFY_RIGHT);
        for (var index = 0; index < rows.size(); index++) {
            var y = headerY + (index + 1) * rowStep;
            Screen.drawAt(dc, left, y, font, isoColumn[index], Graphics.TEXT_JUSTIFY_LEFT);
            Screen.drawAt(dc, loadRight, y, font, loadColumn[index + 1], Graphics.TEXT_JUSTIFY_RIGHT);
            Screen.drawAt(dc, priceRight, y, font, priceColumn[index + 1], Graphics.TEXT_JUSTIFY_RIGHT);
        }
        Screen.drawFooter(dc, headerY + (rows.size() + 1) * rowStep, footerText(""));
    }

    private function widestText(dc as Dc, texts as Array<String>, font as FontDefinition) as Number {
        var widest = 0;
        for (var index = 0; index < texts.size(); index++) {
            var width = dc.getTextWidthInPixels(texts[index], font);
            if (width > widest) {
                widest = width;
            }
        }
        return widest;
    }

    private function drawIsoPage(dc as Dc, row as Dictionary, isoNumber as Number, isoCount as Number) as Void {
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
        Screen.drawFooter(dc, dc.getHeight() * 89 / 100, footerText(isoNumber + "/" + isoCount + "  "));
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
