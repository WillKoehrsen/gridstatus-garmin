import Toybox.Lang;
import Toybox.WatchUi;

// The pages behind an ISO's page: its fuel mix, then charts of its load and price over the last 24 hours. UP and DOWN move between them.
class IsoDetailDelegate extends WatchUi.BehaviorDelegate {
    private const FUEL_MIX_PAGE_INDEX = 0;
    private const LOAD_PAGE_INDEX = 1;
    private const PRICE_PAGE_INDEX = 2;

    private var _iso as String;
    private var _priceLocation as String?;
    private var _pageCount as Number;
    private var _pageIndex as Number = FUEL_MIX_PAGE_INDEX;
    // Each page's client is kept, so moving back to a page shows what it already fetched.
    private var _clients as Array<DatasetClient?> = [null, null, null] as Array<DatasetClient?>;

    function initialize(row as Dictionary) {
        BehaviorDelegate.initialize();
        _iso = row["iso"] as String;
        _priceLocation = row["latest_lmp_location"] as String?;
        // Without the hub's name there is no price to chart.
        _pageCount = _priceLocation != null ? 3 : 2;
    }

    function show() as Void {
        WatchUi.pushView(createView(_pageIndex), self, WatchUi.SLIDE_LEFT);
        getClient(_pageIndex).refreshIfStale();
    }

    function onNextPage() as Boolean {
        showPage((_pageIndex + 1) % _pageCount, WatchUi.SLIDE_UP);
        return true;
    }

    function onPreviousPage() as Boolean {
        showPage((_pageIndex + _pageCount - 1) % _pageCount, WatchUi.SLIDE_DOWN);
        return true;
    }

    function onSelect() as Boolean {
        getClient(_pageIndex).refreshIfStale();
        return true;
    }

    private function showPage(pageIndex as Number, transition as SlideType) as Void {
        _pageIndex = pageIndex;
        WatchUi.switchToView(createView(pageIndex), self, transition);
        getClient(pageIndex).refreshIfStale();
    }

    private function createView(pageIndex as Number) as WatchUi.View {
        var client = getClient(pageIndex);
        if (pageIndex == LOAD_PAGE_INDEX) {
            return new TrendView(_iso.toUpper() + " LOAD", client, false);
        }
        if (pageIndex == PRICE_PAGE_INDEX) {
            return new TrendView(_iso.toUpper() + " PRICE", client, true);
        }
        return new FuelMixView(_iso, client);
    }

    private function getClient(pageIndex as Number) as DatasetClient {
        var client = _clients[pageIndex];
        if (client == null) {
            if (pageIndex == LOAD_PAGE_INDEX) {
                client = TrendClient.forLoad(_iso);
            } else if (pageIndex == PRICE_PAGE_INDEX) {
                client = TrendClient.forPrice(_iso, _priceLocation as String);
            } else {
                client = new DatasetClient(_iso + AppData.FUEL_MIX_DATASET_SUFFIX, {"order" => "desc", "limit" => 1});
            }
            _clients[pageIndex] = client;
        }
        return client;
    }
}
