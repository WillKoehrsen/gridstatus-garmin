import Toybox.Lang;
import Toybox.WatchUi;

class ConditionsDelegate extends WatchUi.BehaviorDelegate {
    private var _view as ConditionsView;
    private var _client as ConditionsClient;

    function initialize(view as ConditionsView, client as ConditionsClient) {
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
        _client.refreshIfStale();
        return true;
    }
}
