import Toybox.Lang;

// Names shared by the app and its glance, which runs with far less memory and reads only what the app saved.
(:glance)
module AppData {
    const CONDITIONS_DATASET = "isos_latest";
    const FUEL_MIX_DATASET_SUFFIX = "_fuel_mix";
    const PAGE_INDEX_KEY = "pageIndex";
    // The saved page index counts the overview and the price map before the first ISO.
    const FIRST_ISO_PAGE_INDEX = 2;

    function rowsKey(datasetId as String) as String {
        return datasetId + "Rows";
    }

    function fetchedAtKey(datasetId as String) as String {
        return datasetId + "FetchedAt";
    }
}
