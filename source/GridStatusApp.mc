import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GridStatusApp extends Application.AppBase {
    private var _client as ConditionsClient;

    function initialize() {
        AppBase.initialize();
        _client = new ConditionsClient();
    }

    function onStart(state as Dictionary?) as Void {
        _client.fetch();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new ConditionsView(_client);
        return [view, new ConditionsDelegate(view, _client)];
    }
}
