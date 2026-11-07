import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class ConditionsClient {
    private const CONDITIONS_URL = "https://api.gridstatus.io/v1/datasets/isos_latest/query";
    private const API_KEY_PROPERTY = "apiKey";
    private const ROWS_STORAGE_KEY = "conditionsRows";
    private const FETCHED_AT_STORAGE_KEY = "conditionsFetchedAt";

    private var _rows as Array<Dictionary>? = null;
    private var _fetchedAtSeconds as Number? = null;
    private var _failureMessage as String? = null;
    private var _isFetching as Boolean = false;

    function initialize() {
        _rows = Application.Storage.getValue(ROWS_STORAGE_KEY) as Array<Dictionary>?;
        _fetchedAtSeconds = Application.Storage.getValue(FETCHED_AT_STORAGE_KEY) as Number?;
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
            CONDITIONS_URL,
            null,
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
            Application.Storage.setValue(ROWS_STORAGE_KEY, _rows as Application.Storage.ValueType);
            Application.Storage.setValue(FETCHED_AT_STORAGE_KEY, _fetchedAtSeconds as Number);
        } catch (exception instanceof Lang.StorageFullException) {
            // The data on screen is still good; the next open just fetches again.
        }
    }
}
