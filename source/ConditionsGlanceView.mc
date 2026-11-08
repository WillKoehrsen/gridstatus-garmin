import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Shows the last ISO viewed, from the data the app saved. It never makes a request, so it uses no API quota.
(:glance)
class ConditionsGlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var rows = Application.Storage.getValue(AppData.rowsKey(AppData.CONDITIONS_DATASET)) as Array<Dictionary>?;
        if (rows == null || rows.size() == 0) {
            drawLine(dc, 50, "Grid Status");
            return;
        }

        var row = selectRow(rows);
        var iso = (row["iso"] as String).toUpper();
        var load = Formatting.formatGigawatts(row["latest_load"] as Numeric?);
        var fetchedAtSeconds = Application.Storage.getValue(AppData.fetchedAtKey(AppData.CONDITIONS_DATASET)) as Number?;
        var price = Formatting.formatPrice(row["latest_lmp"] as Numeric?);
        var priceLine = price;
        if (fetchedAtSeconds != null) {
            priceLine = price + "  " + Formatting.formatElapsedSeconds(Time.now().value() - fetchedAtSeconds);
        }
        // Glance areas differ between watches, so the age is left off when the line wouldn't fit.
        if (dc.getTextWidthInPixels(priceLine, Graphics.FONT_GLANCE) > dc.getWidth()) {
            priceLine = price;
        }
        drawLine(dc, 30, iso + "  " + load);
        drawLine(dc, 72, priceLine);
    }

    private function selectRow(rows as Array<Dictionary>) as Dictionary {
        var pageIndex = Application.Storage.getValue(AppData.PAGE_INDEX_KEY);
        var isoIndex = pageIndex instanceof Number ? pageIndex - AppData.FIRST_ISO_PAGE_INDEX : -1;
        return isoIndex >= 0 && isoIndex < rows.size() ? rows[isoIndex] : rows[0];
    }

    private function drawLine(dc as Dc, heightPercent as Number, text as String) as Void {
        dc.drawText(0, dc.getHeight() * heightPercent / 100, Graphics.FONT_GLANCE, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
