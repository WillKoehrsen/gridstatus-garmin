import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class GridStatusApp extends Application.AppBase {
    private var _client as DatasetClient? = null;

    function initialize() {
        AppBase.initialize();
    }

    // The client is created here because the glance runs this class without it.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var client = new DatasetClient(AppData.CONDITIONS_DATASET, null);
        _client = client;
        var view = new ConditionsView(client);
        client.refreshIfStale();
        return [view, new ConditionsDelegate(view, client)];
    }

    function getGlanceView() as [GlanceView] or [GlanceView, GlanceViewDelegate] or Null {
        return [new ConditionsGlanceView()];
    }

    function onSettingsChanged() as Void {
        if (_client != null) {
            _client.fetch();
        }
    }
}
