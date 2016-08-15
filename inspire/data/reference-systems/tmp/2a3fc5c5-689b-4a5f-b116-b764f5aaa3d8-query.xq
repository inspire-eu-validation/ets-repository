declare namespace hy3='urn:x-inspire:specification:gmlas:HydroBase:3.0'; 
declare namespace hy-n3='urn:x-inspire:specification:gmlas:HydroNetwork:3.0'; 
declare namespace hy-p3='urn:x-inspire:specification:gmlas:HydroPhysicalWaters:3.0'; 
declare namespace net3='urn:x-inspire:specification:gmlas:Network:3.2'; 
declare namespace gn3='urn:x-inspire:specification:gmlas:GeographicalNames:3.0'; 
declare namespace cp3='urn:x-inspire:specification:gmlas:CadastralParcels:3.0'; 
declare namespace base32='urn:x-inspire:specification:gmlas:BaseTypes:3.2'; 
declare namespace hy='http://inspire.ec.europa.eu/schemas/hy/4.0'; 
declare namespace hy-n='http://inspire.ec.europa.eu/schemas/hy-n/4.0'; 
declare namespace hy-p='http://inspire.ec.europa.eu/schemas/hy-p/4.0'; 
declare namespace net='http://inspire.ec.europa.eu/schemas/net/4.0'; 
declare namespace gn='http://inspire.ec.europa.eu/schemas/gn/4.0'; 
declare namespace cp='http://inspire.ec.europa.eu/schemas/cp/4.0'; 
declare namespace base='http://inspire.ec.europa.eu/schemas/base/3.3'; 
declare namespace gml='http://www.opengis.net/gml/3.2'; 
declare namespace wfs='http://www.opengis.net/wfs/2.0'; 
declare namespace xsi='http://www.w3.org/2001/XMLSchema-instance'; 
declare namespace xlink='http://www.w3.org/1999/xlink'; 
declare namespace etf='http://www.interactive-instruments.de/etf/1.0';
declare namespace uuid='java.util.UUID';

import module namespace functx = 'http://www.functx.com';
import module namespace ggeo = 'de.interactive_instruments.etf.bsxm.GmlGeoX';

declare variable $limitErrors external := 1000;
declare variable $limitMessages external := 50;
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
  local:strippath(db:path($element))
};

declare function local:passed($id as xs:string) as xs:boolean
{
	true() (: TODO :)
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
  <message xmlns='http://www.interactive-instruments.de/etf/1.0' ref='{$templateId}'>
   <translationArguments>
    { for $key in map:keys($map) return <argument><token>{$key}</token><value>{map:get($map,$key)}</value></argument>}
   </translationArguments>
  </message>
};

declare function local:status($stati as xs:string*) as xs:string 
{
	if ($stati='FAILED') then 'FAILED' else if ($stati='SKIPPED') then 'SKIPPED' else if ($stati='WARNING') then 'WARNING' else if ($stati='INFO') then 'INFO' else if ($stati='PASSED_MANUAL') then 'PASSED_MANUAL' else if ($stati='PASSED') then 'PASSED' else if ($stati='NOT_APPLICABLE') then 'NOT_APPLICABLE' else 'UNDEFINED'
};

(: Start logging :)
let $logentry := local:log('Testing ' || count($features) || ' features')

(: Index geometries :)
let $start := prof:current-ms()
let $indexedFeatures :=
	for $feature in $features
		let $geom := $feature//*[self::gml:Point or self::gml:LineString or self::gml:Curve or self::gml:Polygon or self::gml:PolyhedralSurface or self::gml:Surface or self::gml:MultiPoint or self::gml:MultiCurve or self::gml:MultiLineString or self::gml:MultiSurface or self::gml:MultiPolygon or self::gml:MultiGeometry][1]
		return 
		if ($geom) then 
			let $void := prof:void(ggeo:index(db:node-pre($feature),db:name($feature),$feature/@gml:id,$geom))
			return $feature 
		else ()
let $duration := prof:current-ms()-$start
let $logentry := local:log('Indexing ' || count($indexedFeatures) || ' features: ' || $duration || ' ms')

(: Statistics and assertions follow below :)

let $start := prof:current-ms()
let $entries := ('all all ' || count($features),
for $feature in $features
	let $ft := $feature/local-name()
	group by $ft 
	order by $ft
	return 'all ' || $ft || ' ' || count($feature),
if (count($db)<=1) then () else
for $file in $db
	let $filename := local:filename($file)
	order by $filename
	return
		for $feature in $features[local:filename(.)=$filename]
			let $ft := $feature/local-name()
			group by $ft 
			order by $ft
			return $filename || ' ' || $ft || ' ' || count($feature))
let $statTable :=
<StatisticalReportTable xmlns='http://www.interactive-instruments.de/etf/1.0'>
<type ref='EID8bb8f162-1082-434f-bd06-23d6507634b8'/>
<entries>
{ for $entry in $entries return <entry xmlns='http://www.interactive-instruments.de/etf/1.0'>{$entry}</entry> }
</entries>
</StatisticalReportTable>
let $statWrite := file:write($statFile, $statTable, map { 'method': 'xml', 'media-type': 'application/xml' })
let $duration := prof:current-ms()-$start
let $logentry := local:log('Statistics table: ' || $duration || ' ms')


let $timestampSuite := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID63f586f0-080c-493b-8ca2-9919427440cc'))
let $logentry := local:log('Test Suite ''Reference systems'' started')
let $testmoduleresults := (
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID047a97c5-f102-4e9e-8ad6-e8e0b39ec5e0'))
let $testcaseresults := (
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID3f6ab9e4-f76b-4043-9e0d-498293f41972'))
let $logentry := local:log('Test Case ''Spatial reference systems'' started')
let $dependencyResult := true()
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EIDa0903ed7-7a6d-427d-ab0e-6e83ff50bb48')) 
let $assertionresults := (
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDdf2eceaf-f406-465f-80c3-61369d69e64f')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $crsuris := (
'http://www.opengis.net/def/crs/EPSG/0/4936', 'http://www.opengis.net/def/crs/EPSG/0/4937', 'http://www.opengis.net/def/crs/EPSG/0/4258', 'http://www.opengis.net/def/crs/EPSG/0/3035', 'http://www.opengis.net/def/crs/EPSG/0/3034', 'http://www.opengis.net/def/crs/EPSG/0/3038', 'http://www.opengis.net/def/crs/EPSG/0/3039', 'http://www.opengis.net/def/crs/EPSG/0/3040', 'http://www.opengis.net/def/crs/EPSG/0/3041', 'http://www.opengis.net/def/crs/EPSG/0/3042', 'http://www.opengis.net/def/crs/EPSG/0/3043', 'http://www.opengis.net/def/crs/EPSG/0/3044', 'http://www.opengis.net/def/crs/EPSG/0/3045', 'http://www.opengis.net/def/crs/EPSG/0/3046', 'http://www.opengis.net/def/crs/EPSG/0/3047', 'http://www.opengis.net/def/crs/EPSG/0/3048', 'http://www.opengis.net/def/crs/EPSG/0/3049', 'http://www.opengis.net/def/crs/EPSG/0/3050', 'http://www.opengis.net/def/crs/EPSG/0/3051', 'http://www.opengis.net/def/crs/EPSG/0/5730', 'http://www.opengis.net/def/crs/EPSG/0/7409')
let $featuresWithErrors := $features[.//@srsName[not(. = $crsuris)]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $srsnames := $feature//@srsName[not(. = $crsuris)]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': string(count($srsnames)) }),
      for $srsname in $srsnames return local:addMessage('unknownCRS1', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'crs': $srsname }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDdf2eceaf-f406-465f-80c3-61369d69e64f',$status))
let $logentry := local:log('Test Assertion ''a.1: Spatial reference systems in feature geometries'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDa0903ed7-7a6d-427d-ab0e-6e83ff50bb48'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDdf2eceaf-f406-465f-80c3-61369d69e64f'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDdf2eceaf-f406-465f-80c3-61369d69e64f')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDdf2eceaf-f406-465f-80c3-61369d69e64f',$status))
let $logentry := local:log('Test Assertion ''a.1: Spatial reference systems in feature geometries'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDa0903ed7-7a6d-427d-ab0e-6e83ff50bb48'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDdf2eceaf-f406-465f-80c3-61369d69e64f'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID5aa4e48c-7967-49a4-bff4-cda0188a2a82')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $crsuris := (
'http://www.opengis.net/def/crs/EPSG/0/4936', 'http://www.opengis.net/def/crs/EPSG/0/4937', 'http://www.opengis.net/def/crs/EPSG/0/4258', 'http://www.opengis.net/def/crs/EPSG/0/3035', 'http://www.opengis.net/def/crs/EPSG/0/3034', 'http://www.opengis.net/def/crs/EPSG/0/3038', 'http://www.opengis.net/def/crs/EPSG/0/3039', 'http://www.opengis.net/def/crs/EPSG/0/3040', 'http://www.opengis.net/def/crs/EPSG/0/3041', 'http://www.opengis.net/def/crs/EPSG/0/3042', 'http://www.opengis.net/def/crs/EPSG/0/3043', 'http://www.opengis.net/def/crs/EPSG/0/3044', 'http://www.opengis.net/def/crs/EPSG/0/3045', 'http://www.opengis.net/def/crs/EPSG/0/3046', 'http://www.opengis.net/def/crs/EPSG/0/3047', 'http://www.opengis.net/def/crs/EPSG/0/3048', 'http://www.opengis.net/def/crs/EPSG/0/3049', 'http://www.opengis.net/def/crs/EPSG/0/3050', 'http://www.opengis.net/def/crs/EPSG/0/3051', 'http://www.opengis.net/def/crs/EPSG/0/5730', 'http://www.opengis.net/def/crs/EPSG/0/7409')
let $filesWithErrors := $db[*/wfs:boundedBy/*/@srsName[not(. = $crsuris)] or */gml:boundedBy/*/@srsName[not(. = $crsuris)]][position() le $limitErrors] 
return
(if ($filesWithErrors) then 'FAILED' else 'PASSED',
 for $file in $filesWithErrors
    order by local:filename($file)
    let $root := $file/element()
    let $srsnames := $file/*/*[local-name() = 'boundedBy']/*/@srsName[not(. = $crsuris)]
   return
     (local:addMessage('errorInFile', map { 'filename': local:filename($root), 'count': string(count($srsnames)) }),
      for $srsname in $srsnames return local:addMessage('unknownCRS2', map { 'filename': local:filename($root), 'crs': $srsname }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID5aa4e48c-7967-49a4-bff4-cda0188a2a82',$status))
let $logentry := local:log('Test Assertion ''a.2: Default spatial reference systems in feature collections'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDa0903ed7-7a6d-427d-ab0e-6e83ff50bb48'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID5aa4e48c-7967-49a4-bff4-cda0188a2a82'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID5aa4e48c-7967-49a4-bff4-cda0188a2a82')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID5aa4e48c-7967-49a4-bff4-cda0188a2a82',$status))
let $logentry := local:log('Test Assertion ''a.2: Default spatial reference systems in feature collections'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDa0903ed7-7a6d-427d-ab0e-6e83ff50bb48'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID5aa4e48c-7967-49a4-bff4-cda0188a2a82'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EIDa0903ed7-7a6d-427d-ab0e-6e83ff50bb48',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID3f6ab9e4-f76b-4043-9e0d-498293f41972'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EIDa0903ed7-7a6d-427d-ab0e-6e83ff50bb48'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID3f6ab9e4-f76b-4043-9e0d-498293f41972',$status))
let $logentry := local:log('Test Case ''Spatial reference systems'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID047a97c5-f102-4e9e-8ad6-e8e0b39ec5e0'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EID3f6ab9e4-f76b-4043-9e0d-498293f41972'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>,
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID9d1677e1-e2e3-4776-845c-1cce60649881'))
let $logentry := local:log('Test Case ''Temporal reference systems'' started')
let $dependencyResult := true()
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EIDf3993dd7-ecf9-4041-a376-0ff05e42bf71')) 
let $assertionresults := (
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID11310d1c-24e5-45da-9b50-b04f82200ffe')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $crsuris := ( 'http://www.opengis.net/def/trs/ISO-8601' )
let $featuresWithErrors := $features[.//gml:TimeInstance/@frame[not(. = $crsuris)] | .//gml:TimeInstance/gml:timePosition/@frame[not(. = $crsuris)] | .//gml:TimePeriod/@frame[not(. = $crsuris)] | .//gml:TimePeriod/gml:beginPosition/@frame[not(. = $crsuris)] | .//gml:TimePeriod/gml:endPosition/@frame[not(. = $crsuris)]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $frames := $feature//@frame[not(. = $crsuris)]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': string(count($frames)) }),
      for $frame in $frames return local:addMessage('unknownTRS', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'trs': $frame }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID11310d1c-24e5-45da-9b50-b04f82200ffe',$status))
let $logentry := local:log('Test Assertion ''a.1: Temporal reference systems in features'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDf3993dd7-ecf9-4041-a376-0ff05e42bf71'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID11310d1c-24e5-45da-9b50-b04f82200ffe'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID11310d1c-24e5-45da-9b50-b04f82200ffe')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID11310d1c-24e5-45da-9b50-b04f82200ffe',$status))
let $logentry := local:log('Test Assertion ''a.1: Temporal reference systems in features'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDf3993dd7-ecf9-4041-a376-0ff05e42bf71'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID11310d1c-24e5-45da-9b50-b04f82200ffe'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EIDf3993dd7-ecf9-4041-a376-0ff05e42bf71',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID9d1677e1-e2e3-4776-845c-1cce60649881'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EIDf3993dd7-ecf9-4041-a376-0ff05e42bf71'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID9d1677e1-e2e3-4776-845c-1cce60649881',$status))
let $logentry := local:log('Test Case ''Temporal reference systems'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID047a97c5-f102-4e9e-8ad6-e8e0b39ec5e0'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EID9d1677e1-e2e3-4776-845c-1cce60649881'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>)
let $status := local:status($testcaseresults/etf:resultStatus)
let $endmessage := prof:void(local:end('EID047a97c5-f102-4e9e-8ad6-e8e0b39ec5e0',$status))
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID63f586f0-080c-493b-8ca2-9919427440cc'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampModule}</startTimestamp>
<duration>{sum($testcaseresults/duration)}</duration>
<resultedFrom ref='EID047a97c5-f102-4e9e-8ad6-e8e0b39ec5e0'/>
<testCaseResults>{$testcaseresults}</testCaseResults>
</TestModuleResult>)
let $status := local:status($testmoduleresults/etf:resultStatus)
let $endmessage := prof:void(local:end('EID63f586f0-080c-493b-8ca2-9919427440cc',$status))
let $logentry := local:log('Test Suite ''Reference systems'' finished')
return
<TestTaskResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='2a3fc5c5-689b-4a5f-b116-b764f5aaa3d8'>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{sum($testmoduleresults/duration)}</duration>
<resultedFrom ref='EID63f586f0-080c-493b-8ca2-9919427440cc'/>
<testObject ref='{$testObjectId}'/>
<attachements>
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/2a3fc5c5-689b-4a5f-b116-b764f5aaa3d8-log.txt')) then 
<Attachment>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/2a3fc5c5-689b-4a5f-b116-b764f5aaa3d8-log.txt'/>
</Attachment>
else ()}
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/2a3fc5c5-689b-4a5f-b116-b764f5aaa3d8-stat.xml')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/2a3fc5c5-689b-4a5f-b116-b764f5aaa3d8-stat.xml'/>
</Attachment>
else ()}
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/2a3fc5c5-689b-4a5f-b116-b764f5aaa3d8-query.xq')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>XQuery executed against the dataset</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/2a3fc5c5-689b-4a5f-b116-b764f5aaa3d8-query.xq'/>
</Attachment>
else ()}
</attachements>
<testModuleResults>{$testmoduleresults}</testModuleResults>
</TestTaskResult>