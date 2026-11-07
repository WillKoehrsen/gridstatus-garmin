import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

class ConditionsClient {
    private const CONDITIONS_URL = "https://api.gridstatus.io/v1/datasets/isos_latest/query";

    private var _rows as Array<Dictionary>? = null;
    private var _failureMessage as String? = null;
    private var _isFetching as Boolean = false;

    function initialize() {
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

    function fetch() as Void {
        if (_isFetching) {
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
                :headers => {"x-api-key" => WatchUi.loadResource(Rez.Strings.GridStatusApiKey) as String},
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
        } else {
            _failureMessage = Formatting.describeFailure(responseCode);
        }
        WatchUi.requestUpdate();
    }
}
