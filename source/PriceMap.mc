import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// A map with each ISO filled in a color for its hub price and labeled with the price. States in no ISO are gray.
module PriceMap {
    const OTHER_REGION_COLOR = 0x555555;
    const LABEL_PADDING_PIXELS = 2;

    // Fits the map between top and bottom, and inside the circle on round screens.
    function draw(dc as Dc, rows as Array<Dictionary>, top as Number, bottom as Number) as Void {
        var map = WatchUi.loadResource(Rez.JsonData.MapShapes) as Dictionary;
        var mapWidth = map["width"] as Number;
        var mapHeight = map["height"] as Number;
        var regions = map["regions"] as Array<Dictionary>;

        var centerY = (top + bottom) / 2.0;
        var scale = (dc.getWidth() - 2 * Screen.EDGE_MARGIN_PIXELS).toFloat() / mapWidth;
        if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
            // Centered on the screen, the map's farthest point sets its size.
            centerY = dc.getHeight() / 2.0;
            scale = (centerY - Screen.EDGE_MARGIN_PIXELS) / (map["reach"] as Number);
            var halfHeight = centerY - top < bottom - centerY ? centerY - top : bottom - centerY;
            scale = minimumFloat(scale, 2 * halfHeight / mapHeight);
        } else {
            scale = minimumFloat(scale, (bottom - top).toFloat() / mapHeight);
        }
        var left = dc.getWidth() / 2.0 - mapWidth * scale / 2;
        var mapTop = centerY - mapHeight * scale / 2;

        var prices = {} as Dictionary<String, Numeric?>;
        for (var index = 0; index < rows.size(); index++) {
            prices[rows[index]["iso"] as String] = rows[index]["latest_lmp"] as Numeric?;
        }

        for (var index = 0; index < regions.size(); index++) {
            var iso = regions[index]["iso"] as String;
            dc.setColor(iso.equals("") ? OTHER_REGION_COLOR : colorForPrice(prices[iso]), Graphics.COLOR_TRANSPARENT);
            var rings = regions[index]["rings"] as Array<Array<Number>>;
            for (var ringIndex = 0; ringIndex < rings.size(); ringIndex++) {
                dc.fillPolygon(toPoints(rings[ringIndex], left, mapTop, scale));
            }
        }
        // Black outlines keep neighboring regions apart where their simplified edges overlap.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var index = 0; index < regions.size(); index++) {
            var rings = regions[index]["rings"] as Array<Array<Number>>;
            for (var ringIndex = 0; ringIndex < rings.size(); ringIndex++) {
                drawOutline(dc, toPoints(rings[ringIndex], left, mapTop, scale));
            }
        }

        var placedLabels = [] as Array<Array<Number>>;
        for (var index = 0; index < regions.size(); index++) {
            var anchor = regions[index]["label"] as Array<Number>?;
            if (anchor != null) {
                var price = prices[regions[index]["iso"] as String];
                drawLabel(dc, Formatting.formatWholePrice(price), left + anchor[0] * scale, mapTop + anchor[1] * scale, placedLabels);
            }
        }
    }

    // Fixed price bands, so a color means the same price on every visit.
    function colorForPrice(price as Numeric?) as Number {
        if (price == null) {
            return Graphics.COLOR_LT_GRAY;
        }
        if (price < 0) {
            return 0x0055FF;
        }
        if (price < 25) {
            return 0x00AA00;
        }
        if (price < 50) {
            return 0xAAAA00;
        }
        if (price < 100) {
            return 0xFFAA00;
        }
        if (price < 250) {
            return 0xFF5500;
        }
        return 0xFF0000;
    }

    function toPoints(ring as Array<Number>, left as Float, top as Float, scale as Float) as Array<Point2D> {
        var points = new Array<Point2D>[ring.size() / 2];
        for (var index = 0; index < points.size(); index++) {
            points[index] = [left + ring[index * 2] * scale, top + ring[index * 2 + 1] * scale] as Point2D;
        }
        return points;
    }

    function drawOutline(dc as Dc, points as Array<Point2D>) as Void {
        for (var index = 0; index < points.size(); index++) {
            var next = points[(index + 1) % points.size()];
            dc.drawLine(points[index][0], points[index][1], next[0], next[1]);
        }
    }

    // Labels go in the region's middle, or beside it when that spot overlaps an earlier label. Each spot first slides onto the screen.
    function drawLabel(dc as Dc, text as String, x as Float, y as Float, placedLabels as Array<Array<Number>>) as Void {
        var font = Graphics.FONT_XTINY;
        var width = dc.getTextWidthInPixels(text, font) + 2 * LABEL_PADDING_PIXELS;
        // The font's full height includes space for accents and descenders, which prices don't have.
        var height = Graphics.getFontAscent(font);
        var offsets = [[0, 0], [0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], [-1, 1], [1, -1], [-1, -1], [0, 2], [0, -2]] as Array<Array<Number>>;
        var box = null as Array<Number>?;
        for (var index = 0; index < offsets.size(); index++) {
            var candidate = moveOntoScreen(dc, [
                (x - width / 2 + offsets[index][0] * width).toNumber(),
                (y - height / 2 + offsets[index][1] * height).toNumber(),
                width,
                height
            ] as Array<Number>);
            if (box == null) {
                box = candidate;
            }
            if (!overlapsAny(candidate, placedLabels)) {
                box = candidate;
                break;
            }
        }
        var placed = box as Array<Number>;
        placedLabels.add(placed);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(placed[0], placed[1], placed[2], placed[3], height / 4);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(placed[0] + width / 2, placed[1] + height / 2, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Steps the box toward the middle of the screen until it is inside the screen's edge.
    function moveOntoScreen(dc as Dc, box as Array<Number>) as Array<Number> {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        for (var step = 0; step < dc.getWidth() && !isOnScreen(dc, box); step++) {
            var boxCenterX = box[0] + box[2] / 2;
            var boxCenterY = box[1] + box[3] / 2;
            box[0] += boxCenterX < centerX ? 1 : (boxCenterX > centerX ? -1 : 0);
            box[1] += boxCenterY < centerY ? 1 : (boxCenterY > centerY ? -1 : 0);
        }
        return box;
    }

    function isOnScreen(dc as Dc, box as Array<Number>) as Boolean {
        var margin = Screen.EDGE_MARGIN_PIXELS;
        if (box[0] < margin || box[1] < margin || box[0] + box[2] > dc.getWidth() - margin || box[1] + box[3] > dc.getHeight() - margin) {
            return false;
        }
        if (System.getDeviceSettings().screenShape != System.SCREEN_SHAPE_ROUND) {
            return true;
        }
        var radius = dc.getWidth() / 2.0;
        var horizontalReach = Screen.maximum((box[0] - radius).abs(), (box[0] + box[2] - radius).abs());
        var verticalReach = Screen.maximum((box[1] - radius).abs(), (box[1] + box[3] - radius).abs());
        return Math.sqrt(horizontalReach * horizontalReach + verticalReach * verticalReach) <= radius - margin;
    }

    function overlapsAny(box as Array<Number>, placedLabels as Array<Array<Number>>) as Boolean {
        for (var index = 0; index < placedLabels.size(); index++) {
            var other = placedLabels[index];
            if (box[0] < other[0] + other[2] && other[0] < box[0] + box[2] && box[1] < other[1] + other[3] && other[1] < box[1] + box[3]) {
                return true;
            }
        }
        return false;
    }

    function minimumFloat(first as Float, second as Float) as Float {
        return first < second ? first : second;
    }
}
