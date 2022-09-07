xquery version "1.0-ml";

declare namespace http = "xdmp:http";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
declare variable $s := xdmp:get-request-field("sortby");
declare variable $total := fn:count(local:totalArticles());
declare variable $resultTotal := fn:count(local:results-controller());
declare variable $sort := "date";

declare function local:totalArticles(){
    for $doc in cts:search(doc(), cts:collection-query("canonical"))
    return $doc
};

declare function local:results-controller(){
    let $docs := if(xdmp:get-request-field("query"))
                then local:search-results()
                else cts:search(doc(), cts:collection-query("canonical"))
    let $facetedDocs := local:facet-results($docs)
    let $sortedDocs := local:sort-results($facetedDocs)
    return $sortedDocs
};

declare function local:search-results(){
    let $q := xdmp:get-request-field("query")
    let $docs := if($q = "")
                then cts:search(doc(), cts:collection-query("canonical"))
                else cts:search(doc(), cts:and-query((cts:element-query(xs:QName("xhtml:html"), $q), cts:collection-query("canonical"))))
    return $docs
};

declare function local:sort-results($docs){
    let $sort := xdmp:get-request-field('sortby')
    for $doc in $docs
    let $sortElement := if($sort eq "countryCode")
                        then $doc//countryCode
                        else $doc//date
    order by $sortElement ascending
    return $doc
};

declare function local:facet-results($docs){
    let $rCode := xdmp:get-request-field("responseCode")
    let $cCode := xdmp:get-request-field("countryCode")
    let $domain := xdmp:get-request-field("domainName")
    let $rCodeDocs := local:applyFacet($rCode, $docs, "responseCode")
    let $cCodeDocs := local:applyFacet($cCode, $rCodeDocs, "countryCode")
    let $returnDocs := local:applyFacet($domain, $cCodeDocs, "domain")
    return $returnDocs
};

declare function local:applyFacet($facets, $docs, $facetType){
    let $tokenFacets := fn:tokenize($facets, "/")
    let $returnDocs := for $facet in $tokenFacets
                        let $items := for $item in $docs
                                        where $item//*[fn:local-name() = $facetType]/text() = $facet
                                        return $item
                        return $items
    return if($facets) then $returnDocs else $docs
};

declare function local:pagination(){
    let $p := xdmp:get-request-field("page")
    let $start := xs:int($p) * 15
    return $start
};

declare function local:getFacets($docs){
    let $facets := for $doc in $docs
              let $responseCode := $doc/envelope/headers/responseCode
              let $countryCode := $doc/envelope/headers/countryCode
              let $url := $doc/envelope/instance/source/root/SOURCEURL
              let $domain := $doc/envelope/headers/domain
              return <facet><responseCode>{$responseCode}</responseCode><countryCode>{$countryCode}</countryCode><domain>{$domain}</domain></facet>
let $countryCodes := for $countryCode in fn:distinct-values($facets/countryCode)
                    let $docs := for $doc in $facets
                                 where $doc/countryCode = $countryCode
                                 return $doc
                    return <countryCode><code>{$countryCode}</code><count>{fn:count($docs)}</count></countryCode>
let $responseCodes := for $responseCode in fn:distinct-values($facets/responseCode)
              let $docs := for $doc in $facets
                           where $doc/responseCode = $responseCode
                           return $doc
              return <responseCode><code>{$responseCode}</code><count>{fn:count($docs)}</count></responseCode>
let $domains := for $domain in fn:distinct-values($facets/domain)
              let $docs := for $doc in $facets
                           where $doc/domain = $domain
                           return $doc
              return <domain><domainName>{$domain}</domainName><count>{fn:count($docs)}</count></domain>
return ($countryCodes, $responseCodes, $domains)
};

declare function local:getURL(){
    let $q := xdmp:get-request-field("query")
    let $s := xdmp:get-request-field("sortby")
    let $rCode := xdmp:get-request-field("responseCode")
    let $cCode := xdmp:get-request-field("countryCode")
    let $domain := xdmp:get-request-field("domainName")
    let $page := xdmp:get-request-field("page")
    let $url := fn:concat("/index.xqy?query=", $q, "&amp;sortby=", $s, "&amp;responseCode=", $rCode, "&amp;countryCode=", $cCode, "&amp;domainName=", $domain, "&amp;page=", $page)
    return $url
};

declare function local:setURL($sort){
    let $currURL := local:getURL()
    let $currsort := fn:concat("sortby=", xdmp:get-request-field("sortby"))
    let $newSort := fn:concat("sortby=", $sort)
    let $updatedURL := fn:replace($currURL, $currsort, $newSort)
    return $updatedURL
};

declare function local:addFacetsURL($facetType, $facet){
    let $currURL := local:getURL()
    let $currFacets := xdmp:get-request-field($facetType)
    let $updatedURL := if(fn:contains($currFacets, $facet))
                        then let $target := fn:concat($facet, "/")
                            let $updatedFacets := fn:replace($currFacets, $target, "")
                            return if($updatedFacets)
                                    then fn:replace($currURL, fn:concat($facetType, "=", $currFacets), fn:concat($facetType, "=", $updatedFacets))
                                    else fn:replace($currURL, fn:concat($facetType, "=", $currFacets), fn:concat($facetType, "="))
                        else let $facets := fn:concat($currFacets, $facet, "/")
                            return fn:replace($currURL, fn:concat($facetType, "=", $currFacets), fn:concat($facetType, "=", $facets))
    return $updatedURL
};

declare function local:setPageURL($p){
    let $currURL := local:getURL()
    let $currP := xdmp:get-request-field("page")
    let $newURL := fn:replace($currURL, fn:concat("page=", $currP), fn:concat("page=", $p))
    return $newURL
};

declare function local:display-results(){
    let $start := local:pagination()
    let $docs := for $i in local:results-controller()[$start to ($start + 14)]
                return $i
    return if($docs)
            then(
                <div id="content">
                    <table cellspacing="0" width="700px">
                        <tr>
                            <th width="20px">ID</th>
                            <th width="200px">Title</th>
                            <th width="70px"><a href="{local:setURL("date")}" class="button">Date</a></th>
                            <th width="70px"><a href="{local:setURL("countryCode")}" class="button">Country Code</a></th>
                            <th width="40px">Latitude</th>
                            <th width="40px">Longitude</th>
                        </tr>

                        {let $sortedDocs := $docs
                        for $doc in $sortedDocs
                        let $id := $doc//GLOBALEVENTID/text()
                        let $formatted-date := $doc//formatted-date
                        let $countryCode := $doc//countryCode
                        let $title := fn:substring($doc//xhtml:html/xhtml:head/xhtml:title[1]/string(), 1, 100)
                        let $lat := $doc/envelope/headers/lat
                        let $long := $doc/envelope/headers/long
                        let $link := $doc//SOURCEURL
                        where $title != ""
                        return( <tr>
                                    <td colspan="10"><hr/></td>
                                </tr>,

                                <tr>
                                    <td><b>{$id}</b></td>
                                    <td><a width="200px" overflowWrap="break-word" inlineSize="200px" href="{$link}">{$title}</a></td>
                                    <td><b>{$formatted-date}</b></td>
                                    <td><b>{$countryCode}</b></td>
                                    <td><b>{$lat}</b></td>
                                    <td><b>{$long}</b></td>
                                </tr>
                        )}
                    </table>
                </div>
            )
            else <div>Sorry, no results for your search.<br/><br/><br/></div>
};

declare function local:facets(){
    let $facets := local:getFacets(local:search-results())
    let $countryCodes := for $facet in $facets
                         where $facet[fn:local-name() = "countryCode"]
                         order by xs:int($facet//*[fn:local-name() = "count"]) descending
                         return $facet
    let $responseCodes := for $facet in $facets
                         where $facet[fn:local-name() = "responseCode"]
                         order by xs:int($facet//*[fn:local-name() = "count"]) descending
                         return $facet
    let $domainNames := for $facet in $facets
                         where $facet[fn:local-name() = "domain"]
                         order by xs:int($facet//*[fn:local-name() = "count"]) descending
                         return $facet
    return <div class="facet">
                <div id="countryCodes">
                    <h3>Country Codes</h3>
                    {for $facet in $countryCodes[1 to 5]
                    return <div id="facet">
                                <a style="inline-block" href="{local:addFacetsURL("countryCode", $facet/code/text())}">{$facet/code}</a><a style="inline-block">[{$facet/count}]</a>
                            </div>
                    }
                </div>
                <div id="responseCodes">
                    <h3>Response Codes</h3>
                    {for $facet in $responseCodes[1 to 5]
                    return <div id="facet">
                                <a style="inline-block" href="{local:addFacetsURL("responseCode", $facet/code/text())}">{$facet/code}</a><a style="inline-block">[{$facet/count}]</a>
                            </div>
                    }
                </div>
                <div id="domainNames">
                    <h3>Domain Names</h3>
                    {for $facet in $domainNames[1 to 5]
                    return <div id="facet">
                                <a style="inline-block" href="{local:addFacetsURL("domainName", $facet/domainName/text())}">{$facet/domainName}</a><a style="inline-block">[{$facet/count}]</a>
                            </div>
                    }
                </div>
            </div>
};

declare function local:displayPagination(){
    let $p := if(xdmp:get-request-field("page"))
                then xdmp:get-request-field("page")
                else 1
    let $a := if(xs:int($p) > 3) then (xs:int($p) - 2) else 1
    let $b := if(xs:int($p) > 3) then (xs:int($p) - 1) else 2
    let $c := if(xs:int($p) > 3) then xs:int($p) else 3
    let $d := if(xs:int($p) > 3) then (xs:int($p) + 1) else 4
    let $e := if(xs:int($p) > 3) then (xs:int($p) + 2) else 5

    return (
        <div>
            <a class="pageLink" href="{local:setPageURL($a)}">{$a}</a>&nbsp;
            <a class="pageLink" href="{local:setPageURL($b)}">{$b}</a>&nbsp;
            <a class="pageLink" href="{local:setPageURL($c)}">{$c}</a>&nbsp;
            <a class="pageLink" href="{local:setPageURL($d)}">{$d}</a>&nbsp;
            <a class="pageLink" href="{local:setPageURL($e)}">{$e}</a>&nbsp;
        </div>
    )
};

xdmp:set-response-content-type("text/html; charset=utf-8"),
<html>
    <head>
        <title>Project Move</title>
    <link href="css/project-move.css" rel="stylesheet" type="text/css" />
    </head>
    <body>
        <div id="wrapper">
            <div>
                <h3>total articles: {$total}</h3>
                <h3>results: {$resultTotal}</h3>
            </div>
            <div id="input">
                <form id="sinput" onsubmit="{local:getURL()}">
                    <input type="text" name="query" id="query" size="55" onsubmit="{local:getURL()}" value="{xdmp:get-request-field("query")}"/><button type="button" id="reset_button" onclick="document.location.href='index.xqy'">x</button>&#160;
                    <button type="submit" onsubmit="{local:getURL()}" href="{local:getURL()}">search</button>
                </form>
                <div id="pinput">
                    {local:displayPagination()}
                </div>
            </div>
            <div id="display">
                <div id="leftcol">
                    {local:facets()}
                </div>
                <div id="rightcol">
                    {local:display-results()}
                </div>
            </div>
        </div>
    </body>
</html>