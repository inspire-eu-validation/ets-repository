declare namespace hy3='urn:x-inspire:specification:gmlas:HydroBase:3.0'; 
declare namespace hy-n3='urn:x-inspire:specification:gmlas:HydroNetwork:3.0'; 
declare namespace hy-p3='urn:x-inspire:specification:gmlas:HydroPhysicalWaters:3.0'; 
declare namespace net3='urn:x-inspire:specification:gmlas:Network:3.2'; 
declare namespace gn3='urn:x-inspire:specification:gmlas:GeographicalNames:3.0'; 
declare namespace cp3='urn:x-inspire:specification:gmlas:CadastralParcels:3.0'; 
declare namespace ps3='urn:x-inspire:specification:gmlas:ProtectedSites:3.0'; 
declare namespace base32='urn:x-inspire:specification:gmlas:BaseTypes:3.2'; 
declare namespace hy='http://inspire.ec.europa.eu/schemas/hy/4.0'; 
declare namespace hy-n='http://inspire.ec.europa.eu/schemas/hy-n/4.0'; 
declare namespace hy-p='http://inspire.ec.europa.eu/schemas/hy-p/4.0'; 
declare namespace net='http://inspire.ec.europa.eu/schemas/net/4.0'; 
declare namespace gn='http://inspire.ec.europa.eu/schemas/gn/4.0'; 
declare namespace cp='http://inspire.ec.europa.eu/schemas/cp/4.0'; 
declare namespace ps='http://inspire.ec.europa.eu/schemas/cp/4.0'; 
declare namespace base='http://inspire.ec.europa.eu/schemas/base/3.3'; 
declare namespace gml='http://www.opengis.net/gml/3.2'; 
declare namespace wfs='http://www.opengis.net/wfs/2.0'; 
declare namespace xsi='http://www.w3.org/2001/XMLSchema-instance'; 
declare namespace xlink='http://www.w3.org/1999/xlink'; 
declare namespace etf='http://www.interactive-instruments.de/etf/2.0';
declare namespace uuid='java.util.UUID';
declare namespace atom='http://www.w3.org/2005/Atom';

import module namespace functx = 'http://www.functx.com';
import module namespace http = 'http://expath.org/ns/http-client';
import module namespace ggeo = 'de.interactive_instruments.etf.bsxm.GmlGeoX';

declare variable $limitErrors external := 1000;
declare variable $validationErrors external := ''; 
declare variable $db external; 
declare variable $features external; 
declare variable $idMap external;
declare variable $testObjectId external;
declare variable $executableTestSuiteId external;
declare variable $testTaskResultId external;
declare variable $testObjectTypeIds external;
declare variable $translationTemplateBundleId external;
declare variable $logFile external;
declare variable $statFile external;

declare function local:strippath($path as xs:string) as xs:string
{
  let $sep := file:dir-separator()
  return
  if (contains($path,$sep)) then
    local:strippath(substring-after($path,$sep))
  else
    replace($path,'\.[gGxX][mM][lL]','')
};

declare function local:filename($element as node()) as xs:string
{
  db:path($element)
};

declare function local:log($text as xs:string) as empty-sequence()
{
  let $dummy := file:append($logFile, $text || file:line-separator(), map { "method": "text", "media-type": "text/plain" })
  return prof:dump($text)
};

declare function local:start($id as xs:string) as empty-sequence()
{
  ()
};

declare function local:end($id as xs:string, $status as xs:string) as empty-sequence()
{
  ()
};

declare function local:addMessage($templateId as xs:string, $map as map(*)) as element()
{
  <message xmlns='http://www.interactive-instruments.de/etf/2.0' ref='{$templateId}'>
   <translationArguments>
    { for $key in map:keys($map) return <argument token='{$key}'>{map:get($map,$key)}</argument> }
   </translationArguments>
  </message>
};

declare function local:passed($id as xs:string) as xs:boolean
{
	true() (: TODO :)
};

declare function local:error-statistics($template as xs:string, $count as xs:integer) as element()*
{
	(if ($count>=$limitErrors) then local:addMessage('TR.tooManyErrors', map { 'count': string($count) }) else (),
	 if ($count>0) then local:addMessage($template, map { 'count': string($count) }) else ())
};

declare function local:status($stati as xs:string*) as xs:string 
{
	if ($stati='FAILED') then 'FAILED' else if ($stati='SKIPPED') then 'SKIPPED' else if ($stati='WARNING') then 'WARNING' else if ($stati='INFO') then 'INFO' else if ($stati='PASSED_MANUAL') then 'PASSED_MANUAL' else if ($stati='PASSED') then 'PASSED' else if ($stati='NOT_APPLICABLE') then 'NOT_APPLICABLE' else 'UNDEFINED'
};

declare function local:check-resource-uri($uri as xs:string) as xs:boolean
{
	if (starts-with($uri,'http://') or starts-with($uri,'https://')) then
		(http:send-request(<http:request method='head' status-only='true'/>, $uri)/@status=('300','204'))
	else
		false()
};

declare function local:check-resource-uris($uris as xs:string*) as map(*)
{
	map:merge( for $uri in $uris return map { $uri : local:check-resource-uri($uri) } )
};

declare function local:check-code-list-values($features3 as element()*, $features4 as element()*, $property as xs:string, $uri as xs:string) as element()*
{
let $clname := fn:substring-after($uri, 'http://inspire.ec.europa.eu/codelist/')
let $cluri := $uri || '/' || $clname || '.en.atom'
let $clfeed := if (fn:doc-available($cluri)) then fn:doc($cluri) else ()
return
if (not($clfeed)) then ('FAILED', local:addMessage('TR.systemError', map { 'text': 'Code list ' || $uri || 'cannot be accessed.' }))
else
let $valuesURI := $clfeed//atom:entry/atom:id/text()
let $valuesCode := for $value in $valuesURI return fn:substring-after($value, $uri || '/')
let $featuresWithErrors := ($features3[*[local-name()=$property and not(@xsi:nil='true') and not(text()=$valuesCode)]] | $features4[*[local-name()=$property and not(@xsi:nil='true') and @xlink:href and not(@xlink:href=$valuesURI)]])[position() le $limitErrors]
return
(local:error-statistics('TR.featuresWithErrors', count($featuresWithErrors)),
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $v4 := fn:starts-with(namespace-uri($feature/*[local-name()=$property]),'http://inspire.ec.europa.eu/schemas/')
   let $value := if ($v4) then $feature/*[local-name()=$property]/@xlink:href else $feature/*[local-name()=$property]/text()
   return
     local:addMessage('TR.disallowedCodeListValue', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': string($feature/@gml:id), 'property': $property, 'value': string($value), 'codelist' : $uri }))  
};

declare function local:testDesignationConstraint($features3 as element()*, $features4 as element()*, $scheme as xs:string, $codelist as xs:string ) as element()*
{
let $allowedValuesURI := local:getAllowedValuesURI( 'http://inspire.ec.europa.eu/codelist/' || $codelist )
let $allowedValuesCode := local:getAllowedValuesCode( $allowedValuesURI, $codelist )
let $valuesCode := fn:distinct-values($features3/ps3:siteDesignation/*[ps3:designationScheme=$scheme]/ps3:designation/text())
let $valuesURI := fn:distinct-values($features4/ps:siteDesignation/*[ps:designationScheme=concat('http://inspire.ec.europa.eu/codelist/DesignationSchemeValue/',$scheme)]/ps:designation/@xlink:href)
let $badvaluesCode := functx:value-except($valuesCode,$allowedValuesCode)
let $badvaluesURI := functx:value-except($valuesURI,$allowedValuesURI)
let $featuresWithErrors3 := $features3[ps3:siteDesignation/*[ps3:designationScheme=$scheme]/ps3:designation/text()=$badvaluesCode]
let $featuresWithErrors4 := $features4[ps:siteDesignation/*[ps:designationScheme=$scheme]/ps:designation/@xlink:href=$badvaluesURI]
return
(for $feature in $featuresWithErrors3
   order by $feature/@gml:id
   let $values := $feature/ps3:siteDesignation/*[ps3:designationScheme=$scheme]/ps3:designation/text()[.=$badvaluesCode]
   return
     local:addMessage('TR.constraintViolation', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': string($feature/@gml:id), 'constraint': 'Sites must use designations from an appropriate designation scheme.', 'additionalInfo': 'For designation scheme ''' || $scheme || ''' the following disallowed value(s) have been used: ' || string-join($values,', ') || '. Allowed values are: ' || string-join($allowedValuesCode,', ') || '.' }),
 for $feature in $featuresWithErrors4
   order by $feature/@gml:id
   let $values := $feature/ps:siteDesignation/*[ps:designationScheme=$scheme]/ps:designation/@xlink:href[.=$badvaluesURI]
   return
     local:addMessage('TR.constraintViolation', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': string($feature/@gml:id), 'constraint': 'Sites must use designations from an appropriate designation scheme.', 'additionalInfo': 'For designation scheme ''' || $scheme || ''' the following disallowed value(s) have been used: ' || string-join($values,', ') || '. Allowed values are: ' || string-join($allowedValuesURI,', ') || '.' }))
};

declare function local:getAllowedValuesURI( $uri as xs:string ) as xs:string*
{
	let $clname := fn:substring-after($uri, 'http://inspire.ec.europa.eu/codelist/')
	let $cluri := $uri || '/' || $clname || '.en.atom'
	let $clfeed := if (fn:doc-available($cluri)) then fn:doc($cluri) else ()
	return
		if (not($clfeed)) then 
			let $dummy := local:addMessage('TR.systemError', map { 'text': 'Code list ' || $uri || 'cannot be accessed.' })
			return ()
		else
			let $valuesURI := $clfeed//atom:entry/atom:id/text()
			return $valuesURI
};

declare function local:getAllowedValuesCode( $valuesURI as xs:string*, $uri as xs:string ) as xs:string*
{
	let $valuesCode := for $value in $valuesURI return fn:substring-after($value, $uri || '/')
	return $valuesCode
};

(: Start logging :)
let $logentry := local:log('Testing ' || count($features) || ' features')

(: Index geometries :)
let $start := prof:current-ms()
let $geometryParsingErrors :=
	map:merge(for $feature in $features
		let $geom := $feature//*[self::gml:Point or self::gml:LineString or self::gml:Curve or self::gml:Polygon or self::gml:PolyhedralSurface or self::gml:Surface or self::gml:MultiPoint or self::gml:MultiCurve or self::gml:MultiLineString or self::gml:MultiSurface or self::gml:MultiPolygon or self::gml:MultiGeometry][1]
		return 
		if ($geom) then 
			try { 
				prof:void(ggeo:index(db:node-pre($feature),db:name($feature),$feature/@gml:id,$geom)) } 
			catch * { 
				map:entry($feature/@gml:id,$err:description)
			}
		else ())
let $duration := prof:current-ms()-$start
let $logentry := local:log('Indexing features (parsing errors: ' || map:size($geometryParsingErrors) || '): ' || $duration || ' ms')

(: Statistics and assertions follow below :)
