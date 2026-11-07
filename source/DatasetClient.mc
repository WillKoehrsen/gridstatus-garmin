import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Fetches one Grid Status dataset and keeps the last response on the watch.
class DatasetClient {
    private const API_URL = "https://api.gridstatus.io/v1/datasets/";
    private const API_KEY_PROPERTY = "apiKey";

    private var _datasetId as String;
    private var _parameters as Dictionary<Object, Object>?;
    private var _rows as Array<Dictionary>?;
    private var _fetchedAtSeconds as Number?;
    private var _failureMessage as String? = null;
    private var _isFetching as Boolean = false;

    function initialize(datasetId as String, parameters as Dictionary<Object, Object>?) {
        _datasetId = datasetId;
        _parameters = parameters;
        _rows = Application.Storage.getValue(AppData.rowsKey(datasetId)) as Array<Dictionary>?;
        _fetchedAtSeconds = Application.Storage.getValue(AppData.fetchedAtKey(datasetId)) as Number?;
    }

    function getRows() as Array<Dictionary>? {
        return _rows;
    }

    function getFailureMessage() as String? {
        return _failureMessage;
    }

    function isFetching() as Boolean {
        return _isFetching;
    }

    function hasApiKey() as Boolean {
        return getApiKey().length() > 0;
    }

    function getSecondsSinceFetch() as Number? {
        return _fetchedAtSeconds != null ? Time.now().value() - _fetchedAtSeconds : null;
    }

    // Each request counts against the user's quota, and the data changes about every 5 minutes.
    function refreshIfStale() as Void {
        if (_rows != null && Formatting.isFresh(_fetchedAtSeconds, Time.now().value())) {
            WatchUi.requestUpdate();
            return;
        }
        fetch();
    }

    function fetch() as Void {
        if (_isFetching || !hasApiKey()) {
            WatchUi.requestUpdate();
            return;
        }
        _isFetching = true;
        _failureMessage = null;
        WatchUi.requestUpdate();

        // The key goes in a header so it stays out of URLs, which servers and proxies often log.
        Communications.makeWebRequest(
            API_URL + _datasetId + "/query",
            _parameters,
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {"x-api-key" => getApiKey()},
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onResponse)
        );
    }

    function onResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        _isFetching = false;
        var rows = data instanceof Dictionary ? data["data"] : null;
        if (responseCode == 200 && rows instanceof Array && rows.size() > 0) {
            _rows = rows as Array<Dictionary>;
            _fetchedAtSeconds = Time.now().value();
            saveToStorage();
        } else {
            _failureMessage = Formatting.describeFailure(responseCode);
        }
        WatchUi.requestUpdate();
    }

    private function getApiKey() as String {
        var apiKey = Application.Properties.getValue(API_KEY_PROPERTY);
        return apiKey instanceof String ? Formatting.trim(apiKey) : "";
    }

    private function saveToStorage() as Void {
        try {
            Application.Storage.setValue(AppData.rowsKey(_datasetId), _rows as Application.Storage.ValueType);
            Application.Storage.setValue(AppData.fetchedAtKey(_datasetId), _fetchedAtSeconds as Number);
        } catch (exception instanceof Lang.StorageFullException) {
            // The data on screen is still good; the next open just fetches again.
        }
    }
}
