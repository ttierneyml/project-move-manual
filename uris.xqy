xquery version "1.0-ml";

let $uris := cts:uris("", (), cts:directory-query("/news/"))

let $count := fn:count($uris)

return ($count, $uris) 