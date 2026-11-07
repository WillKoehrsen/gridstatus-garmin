import Toybox.Graphics;
import Toybox.Lang;

// Positions are percentages of the screen, so layouts follow the watch's resolution.
module Screen {
    function drawCentered(dc as Dc, heightPercent as Number, font as FontDefinition, text as String) as Void {
        draw(dc, 50, heightPercent, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function draw(
        dc as Dc,
        widthPercent as Number,
        heightPercent as Number,
        font as FontDefinition,
        text as String,
        justification as TextJustification
    ) as Void {
        dc.drawText(
            dc.getWidth() * widthPercent / 100,
            dc.getHeight() * heightPercent / 100,
            font,
            text,
            justification | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function clear(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
    }

    // The text shown when a dataset has nothing to display yet.
    function statusMessage(client as DatasetClient) as String {
        var failureMessage = client.getFailureMessage();
        if (client.isFetching() || failureMessage == null) {
            return "Loading...";
        }
        return failureMessage + "\nPress START\nto retry";
    }
}
