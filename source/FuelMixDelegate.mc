import Toybox.Lang;
import Toybox.WatchUi;

class FuelMixDelegate extends WatchUi.BehaviorDelegate {
    private var _client as DatasetClient;

    function initialize(client as DatasetClient) {
        BehaviorDelegate.initialize();
        _client = client;
    }

    function onSelect() as Boolean {
        _client.refreshIfStale();
        return true;
    }
}
