# /// script
# requires-python = ">=3.11"
# dependencies = ["shapely>=2.0"]
# ///
"""Writes resources/jsonData/map.json, the ISO outlines the map page fills with each ISO's price.

Each ISO is drawn as the US states (or the province) it mostly covers, from Natural Earth's public-domain outlines, so the regions are approximate.
Usage: uv run scripts/generate_map.py
"""

import json
import math
import urllib.request
from pathlib import Path

from shapely.geometry import MultiPolygon, Polygon, box, shape
from shapely.ops import polylabel, unary_union

NATURAL_EARTH_URL = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_50m_admin_1_states_provinces.geojson"
OUTPUT_PATH = Path(__file__).resolve().parent.parent / "resources" / "jsonData" / "map.json"

# Each state goes to the ISO that covers most of it. States in no ISO are drawn in gray.
STATES_BY_ISO = {
    "caiso": ["CA"],
    "ercot": ["TX"],
    "spp": ["KS", "OK", "NE", "SD", "ND"],
    "miso": ["MN", "WI", "IA", "IL", "IN", "MI", "MO", "AR", "LA", "MS"],
    "pjm": ["PA", "NJ", "MD", "DE", "DC", "VA", "WV", "OH", "KY"],
    "nyiso": ["NY"],
    "isone": ["CT", "RI", "MA", "VT", "NH", "ME"],
}
OTHER_STATES = ["WA", "OR", "ID", "MT", "WY", "NV", "UT", "CO", "AZ", "NM", "TN", "NC", "SC", "GA", "AL", "FL"]
ONTARIO_ISO = "ieso"
# Ontario reaches 57°N, so it is cut off a little above the US border to keep the map wide rather than tall.
ONTARIO_NORTHERN_LIMIT_DEGREES = 50.5

# Connect IQ draws polygons of at most 64 points.
MAXIMUM_POINTS_PER_POLYGON = 64
MAP_WIDTH = 1000
# Islands and slivers smaller than this share of the map's area would be under a pixel on the watch.
MINIMUM_AREA_SHARE = 0.0004
STARTING_TOLERANCE_SHARE = 0.004


def albers(longitude: float, latitude: float) -> tuple[float, float]:
    """Albers equal-area conic with the usual contiguous-US parallels, on a unit sphere."""
    first_parallel, second_parallel, origin_latitude, origin_longitude = (math.radians(value) for value in (29.5, 45.5, 23.0, -96.0))
    cone = (math.sin(first_parallel) + math.sin(second_parallel)) / 2
    constant = math.cos(first_parallel) ** 2 + 2 * cone * math.sin(first_parallel)
    origin_radius = math.sqrt(constant - 2 * cone * math.sin(origin_latitude)) / cone
    radius = math.sqrt(constant - 2 * cone * math.sin(math.radians(latitude))) / cone
    angle = cone * (math.radians(longitude) - origin_longitude)
    return radius * math.sin(angle), origin_radius - radius * math.cos(angle)


def project(geometry: Polygon | MultiPolygon) -> MultiPolygon:
    polygons = geometry.geoms if isinstance(geometry, MultiPolygon) else [geometry]
    return MultiPolygon([Polygon([albers(longitude, latitude) for longitude, latitude in polygon.exterior.coords]) for polygon in polygons])


def outer_polygons(geometry: Polygon | MultiPolygon) -> list[Polygon]:
    polygons = geometry.geoms if isinstance(geometry, MultiPolygon) else [geometry]
    return [Polygon(polygon.exterior) for polygon in polygons]


def simplify_to_limit(polygon: Polygon, tolerance: float) -> Polygon:
    while True:
        simplified = polygon.simplify(tolerance, preserve_topology=True)
        assert isinstance(simplified, Polygon)
        if len(simplified.exterior.coords) - 1 <= MAXIMUM_POINTS_PER_POLYGON:
            return simplified
        tolerance *= 1.25


def load_outlines() -> dict[str, Polygon | MultiPolygon]:
    with urllib.request.urlopen(NATURAL_EARTH_URL) as response:
        features = json.load(response)["features"]
    outlines = {}
    for feature in features:
        properties = feature["properties"]
        if properties["iso_a2"] == "US" or (properties["iso_a2"] == "CA" and properties["postal"] == "ON"):
            outlines[properties["postal"]] = shape(feature["geometry"])
    outlines["ON"] = outlines["ON"].intersection(box(-100, 40, -70, ONTARIO_NORTHERN_LIMIT_DEGREES))
    return outlines


def main() -> None:
    outlines = load_outlines()
    groups = {iso: [outlines[state] for state in states] for iso, states in STATES_BY_ISO.items()}
    groups[ONTARIO_ISO] = [outlines["ON"]]
    groups[""] = [outlines[state] for state in OTHER_STATES]
    # A small buffer closes the slivers between neighboring states' outlines before they merge.
    merged = {iso: unary_union([project(outline).buffer(1e-4) for outline in group]).buffer(-1e-4) for iso, group in groups.items()}

    minimum_x, minimum_y, maximum_x, maximum_y = unary_union(list(merged.values())).bounds
    scale = MAP_WIDTH / (maximum_x - minimum_x)
    map_height = round((maximum_y - minimum_y) * scale)
    minimum_area = MINIMUM_AREA_SHARE * MAP_WIDTH * map_height

    regions = []
    areas = {}
    for iso, geometry in merged.items():
        # Flips the y axis so it points down, like the screen's.
        screen_geometry = MultiPolygon(
            [Polygon([((x - minimum_x) * scale, (maximum_y - y) * scale) for x, y in polygon.exterior.coords]) for polygon in outer_polygons(geometry)]
        )
        polygons = [polygon for polygon in screen_geometry.geoms if polygon.area >= minimum_area]
        polygons.sort(key=lambda polygon: polygon.area, reverse=True)
        rings = []
        for polygon in polygons:
            simplified = simplify_to_limit(polygon, STARTING_TOLERANCE_SHARE * MAP_WIDTH)
            rings.append([round(value) for point in simplified.exterior.coords[:-1] for value in point])
        region = {"iso": iso, "rings": rings}
        areas[iso] = sum(polygon.area for polygon in polygons)
        if iso:
            label = polylabel(polygons[0], tolerance=1)
            region["label"] = [round(label.x), round(label.y)]
        regions.append(region)

    # The gray regions come first so ISOs draw over them, then the smallest ISOs, whose labels have the least room to move.
    regions.sort(key=lambda region: (region["iso"] != "", areas[region["iso"]]))
    # How far the farthest point is from the map's center, which sets how large the map can be drawn on a round screen.
    reach = max(math.hypot(ring[index] - MAP_WIDTH / 2, ring[index + 1] - map_height / 2) for region in regions for ring in region["rings"] for index in range(0, len(ring), 2))
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    output = {"width": MAP_WIDTH, "height": map_height, "reach": math.ceil(reach), "regions": regions}
    OUTPUT_PATH.write_text(json.dumps(output, separators=(",", ":")) + "\n")
    point_count = sum(len(ring) // 2 for region in regions for ring in region["rings"])
    print(f"Wrote {OUTPUT_PATH.name}: {MAP_WIDTH}x{map_height}, reach {output['reach']}, {len(regions)} regions, {point_count} points")
    for region in regions:
        print(f"  {region['iso'] or 'other'}: {[len(ring) // 2 for ring in region['rings']]} label {region.get('label')}")


if __name__ == "__main__":
    main()
