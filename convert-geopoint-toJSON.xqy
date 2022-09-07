let $points := 
            cts:element-pair-geospatial-values(
                xs:QName("ParentNameHere"),
                xs:QName("ActionGeo_Lat"),
                xs:QName("ActionGeo_Long"),
                (),
                ("limit=10000", "frequency-order"),
                $yourSearchQ
            )
    let $xml :=
        <json type="object" xmlns="http://marklogic.com/xdmp/json/basic">
            <response type="object">
                <data type="object">
                    <points type="array">
                    {
                        for $point in $points
                        return
                            <point type="array">
                                <latitude type="number">{cts:point-latitude($point)}</latitude>
                                <longitude type="number">{cts:point-longitude($point)}</longitude>
                                <count type="number">{cts:frequency($point)}</count>
                            </point>
                    }
                    </points>
                </data>
                <success type="boolean">true</success>
            </response>
        </json>
    return
        json:transform-to-json($xml)