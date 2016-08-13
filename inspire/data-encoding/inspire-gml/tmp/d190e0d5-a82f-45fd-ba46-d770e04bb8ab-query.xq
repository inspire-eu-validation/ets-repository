declare namespace hy3='urn:x-inspire:specification:gmlas:HydroBase:3.0'; 
declare namespace hy-n3='urn:x-inspire:specification:gmlas:HydroNetwork:3.0'; 
declare namespace hy-p3='urn:x-inspire:specification:gmlas:HydroPhysicalWaters:3.0'; 
declare namespace net3='urn:x-inspire:specification:gmlas:Network:3.2'; 
declare namespace gn3='urn:x-inspire:specification:gmlas:GeographicalNames:3.0'; 
declare namespace base32='urn:x-inspire:specification:gmlas:BaseTypes:3.2'; 
declare namespace hy='http://inspire.ec.europa.eu/schemas/hy/4.0'; 
declare namespace hy-n='http://inspire.ec.europa.eu/schemas/hy-n/4.0'; 
declare namespace hy-p='http://inspire.ec.europa.eu/schemas/hy-p/4.0'; 
declare namespace net='http://inspire.ec.europa.eu/schemas/net/4.0'; 
declare namespace gn='http://inspire.ec.europa.eu/schemas/gn/4.0'; 
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
let $startmessage := prof:void(local:start('EID545f9e49-009b-4114-9333-7ca26413b5d4'))
let $logentry := local:log('Test Suite ''INSPIRE GML encoding'' started')
let $testmoduleresults := (
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID8e96257c-ae42-4123-b298-b8c5eda3a027'))
let $logentry := local:log('Test Module ''IGNORE'' started')
let $testcaseresults := (
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EIDf66872d4-3a1f-4581-a501-94200219bf13'))
let $logentry := local:log('Test Case ''Basic tests'' started')
let $dependencyResult := local:passed('TODO UUID of other Test Case')
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EIDc177cf64-3a66-4ac4-92b9-61207aab8007')) 
let $logentry := local:log('Test Step ''IGNORE'' started')
let $assertionresults := (
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID928d8204-3015-4811-82fd-f4779b35385b')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO extension to identify all feature elements :)
let $filesWithErrors := $db[not(wfs:FeatureCollection or gml:FeatureCollection or base32:SpatialDataSet or base:SpatialDataSet or gml:AbstractFeature)][position() le $limitErrors]
return 
(if ($filesWithErrors) then 'FAILED' else 'PASSED',
 for $file in $filesWithErrors
    order by local:filename($file)
    let $root := $file/element()
    return
     (local:addMessage('errorInFile', map { 'filename': local:filename($root), 'count': '1' }),
      local:addMessage('incorrectRoot', map { 'filename': local:filename($root), 'elementName': local-name($root), 'namespace': namespace-uri($root) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID928d8204-3015-4811-82fd-f4779b35385b',$status))
let $logentry := local:log('Test Assertion ''b.1: Document root element'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc177cf64-3a66-4ac4-92b9-61207aab8007'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID928d8204-3015-4811-82fd-f4779b35385b'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID928d8204-3015-4811-82fd-f4779b35385b')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID928d8204-3015-4811-82fd-f4779b35385b',$status))
let $logentry := local:log('Test Assertion ''b.1: Document root element'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc177cf64-3a66-4ac4-92b9-61207aab8007'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID928d8204-3015-4811-82fd-f4779b35385b'/>
    <messages/>
  </TestAssertionResult>,
  let $startmessage := prof:void(local:start('EIDbdfdccf3-8c0d-489c-ad96-6acb7e017009')) 
  let $endmessage := prof:void(local:end('EIDbdfdccf3-8c0d-489c-ad96-6acb7e017009','NOT_APPLICABLE'))
  let $logentry := local:log('Test Assertion ''b.2: Character encoding'': disabled')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc177cf64-3a66-4ac4-92b9-61207aab8007'/>
    <resultStatus>NOT_APPLICABLE</resultStatus>
    <startTimestamp>2016-08-13T16:25:00.995+02:00</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDbdfdccf3-8c0d-489c-ad96-6acb7e017009'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EIDc177cf64-3a66-4ac4-92b9-61207aab8007',$status))
let $logentry := local:log('Test Step ''IGNORE'' finished: ' || $status)
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EIDf66872d4-3a1f-4581-a501-94200219bf13'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EIDc177cf64-3a66-4ac4-92b9-61207aab8007'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EIDf66872d4-3a1f-4581-a501-94200219bf13',$status))
let $logentry := local:log('Test Case ''Basic tests'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID8e96257c-ae42-4123-b298-b8c5eda3a027'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EIDf66872d4-3a1f-4581-a501-94200219bf13'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>)
let $status := local:status($testcaseresults/etf:resultStatus)
let $endmessage := prof:void(local:end('EID8e96257c-ae42-4123-b298-b8c5eda3a027',$status))
let $logentry := local:log('Test Module ''IGNORE'' finished: ' || $status)
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID545f9e49-009b-4114-9333-7ca26413b5d4'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampModule}</startTimestamp>
<duration>{sum($testcaseresults/duration)}</duration>
<resultedFrom ref='EID8e96257c-ae42-4123-b298-b8c5eda3a027'/>
<testCaseResults>{$testcaseresults}</testCaseResults>
</TestModuleResult>)
let $status := local:status($testmoduleresults/etf:resultStatus)
let $endmessage := prof:void(local:end('EID545f9e49-009b-4114-9333-7ca26413b5d4',$status))
let $logentry := local:log('Test Suite ''INSPIRE GML encoding'' finished')
return
<TestTaskResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='d190e0d5-a82f-45fd-ba46-d770e04bb8ab'>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{sum($testmoduleresults/duration)}</duration>
<resultedFrom ref='EID545f9e49-009b-4114-9333-7ca26413b5d4'/>
<testObject ref='{$testObjectId}'/>
<attachements>
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/d190e0d5-a82f-45fd-ba46-d770e04bb8ab-log.txt')) then 
<Attachment>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/d190e0d5-a82f-45fd-ba46-d770e04bb8ab-log.txt'/>
</Attachment>
else ()}
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/d190e0d5-a82f-45fd-ba46-d770e04bb8ab-stat.xml')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/d190e0d5-a82f-45fd-ba46-d770e04bb8ab-stat.xml'/>
</Attachment>
else ()}
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/d190e0d5-a82f-45fd-ba46-d770e04bb8ab-query.xq')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>XQuery executed against the dataset</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/d190e0d5-a82f-45fd-ba46-d770e04bb8ab-query.xq'/>
</Attachment>
else ()}
</attachements>
<testModuleResults>{$testmoduleresults}</testModuleResults>
</TestTaskResult>