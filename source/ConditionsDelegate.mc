import Toybox.Lang;
import Toybox.WatchUi;

class ConditionsDelegate extends WatchUi.BehaviorDelegate {
    private var _view as ConditionsView;
    private var _client as DatasetClient;

    function initialize(view as ConditionsView, client as DatasetClient) {
        BehaviorDelegate.initialize();
        _view = view;
        _client = client;
    }

    function onNextPage() as Boolean {
        _view.showNextPage();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.showPreviousPage();
        return true;
    }

    function onSelect() as Boolean {
        var row = _view.getSelectedRow();
        if (row == null) {
            _client.refreshIfStale();
            return true;
        }
        var iso = row["iso"] as String;
        var fuelMixClient = new DatasetClient(iso + AppData.FUEL_MIX_DATASET_SUFFIX, {"order" => "desc", "limit" => 1});
        WatchUi.pushView(new FuelMixView(iso, fuelMixClient), new FuelMixDelegate(fuelMixClient), WatchUi.SLIDE_LEFT);
        fuelMixClient.refreshIfStale();
        return true;
    }
}
