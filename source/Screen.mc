import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Positions are percentages of the screen, so layouts follow the watch's resolution.
module Screen {
    // Space kept between a line's text box and the edge of the screen.
    const EDGE_MARGIN_PIXELS = 2;

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
        drawAt(dc, dc.getWidth() * widthPercent / 100, dc.getHeight() * heightPercent / 100, font, text, justification);
    }

    // Draws the bottom line at y, or higher if it would cross the screen's edge there.
    function drawFooter(dc as Dc, y as Number, text as String) as Void {
        var font = Graphics.FONT_XTINY;
        var dimensions = dc.getTextDimensions(text, font);
        var halfHeight = dimensions[1] / 2;
        var lowestCenter = dc.getHeight() - halfHeight - EDGE_MARGIN_PIXELS;
        if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
            var radius = dc.getWidth() / 2.0;
            var halfWidth = dimensions[0] / 2.0 + EDGE_MARGIN_PIXELS;
            var chordHeight = halfWidth < radius ? Math.sqrt(radius * radius - halfWidth * halfWidth) : 0;
            lowestCenter = (radius + chordHeight).toNumber() - halfHeight - EDGE_MARGIN_PIXELS;
        }
        drawAt(dc, dc.getWidth() / 2, y < lowestCenter ? y : lowestCenter, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Font sizes differ between watches, so the text steps down to smaller fonts until it fits on the screen.
    function drawAt(
        dc as Dc,
        x as Number,
        y as Number,
        font as FontDefinition,
        text as String,
        justification as TextJustification
    ) as Void {
        var fittedFont = font;
        while (fittedFont > Graphics.FONT_XTINY && marginInside(dc, x, y, fittedFont, text, justification) < EDGE_MARGIN_PIXELS) {
            fittedFont = (fittedFont - 1) as FontDefinition;
        }
        dc.drawText(x, y, fittedFont, text, justification | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // The smallest distance from the text's box to the edge of the screen, negative when the box crosses it.
    function marginInside(
        dc as Dc,
        x as Number,
        y as Number,
        font as FontDefinition,
        text as String,
        justification as TextJustification
    ) as Number {
        var dimensions = dc.getTextDimensions(text, font);
        var width = dimensions[0];
        var height = dimensions[1];
        var left = x - width / 2;
        if (justification == Graphics.TEXT_JUSTIFY_LEFT) {
            left = x;
        } else if (justification == Graphics.TEXT_JUSTIFY_RIGHT) {
            left = x - width;
        }
        var top = y - height / 2;
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        var margin = minimum(minimum(left, top), minimum(screenWidth - left - width, screenHeight - top - height));
        if (System.getDeviceSettings().screenShape != System.SCREEN_SHAPE_ROUND) {
            return margin;
        }
        var radius = screenWidth / 2.0;
        var horizontalReach = maximum((left - radius).abs(), (left + width - radius).abs());
        var verticalReach = maximum((top - radius).abs(), (top + height - radius).abs());
        var cornerDistance = Math.sqrt(horizontalReach * horizontalReach + verticalReach * verticalReach);
        return minimum(margin, (radius - cornerDistance).toNumber());
    }

    // Half the width available to a line of the given height centered at y, keeping clear of the screen's edge.
    function availableHalfWidth(dc as Dc, y as Number, height as Number) as Number {
        var halfScreen = dc.getWidth() / 2;
        if (System.getDeviceSettings().screenShape != System.SCREEN_SHAPE_ROUND) {
            return halfScreen - EDGE_MARGIN_PIXELS;
        }
        var reach = (y - halfScreen).abs() + height / 2;
        if (reach >= halfScreen) {
            return 0;
        }
        return Math.sqrt(halfScreen * halfScreen - reach * reach).toNumber() - EDGE_MARGIN_PIXELS;
    }

    // Drops characters from the end until the text is no wider than the given width.
    function truncateToWidth(dc as Dc, text as String, font as FontDefinition, maximumWidth as Number) as String {
        var truncated = text;
        while (truncated.length() > 1 && dc.getTextWidthInPixels(truncated, font) > maximumWidth) {
            truncated = truncated.substring(0, truncated.length() - 1) as String;
        }
        return truncated;
    }

    function minimum(first as Numeric, second as Numeric) as Number {
        return (first < second ? first : second).toNumber();
    }

    function maximum(first as Float, second as Float) as Float {
        return first > second ? first : second;
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
