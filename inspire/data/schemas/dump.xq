declare namespace hy3='urn:x-inspire:specification:gmlas:HydroBase:3.0'; 
declare namespace hy-n3='urn:x-inspire:specification:gmlas:HydroNetwork:3.0'; 
declare namespace hy-p3='urn:x-inspire:specification:gmlas:HydroPhysicalWaters:3.0'; 
declare namespace net3='urn:x-inspire:specification:gmlas:Network:3.2'; 
declare namespace gn3='urn:x-inspire:specification:gmlas:GeographicalNames:3.0'; 
declare namespace base3='urn:x-inspire:specification:gmlas:BaseTypes:3.2'; 
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

declare function local:log($text as xs:string) as empty-sequence()
{
  prof:dump($text)
};

declare function local:start($text as xs:string) as empty-sequence()
{
  (:
  local:log('Starting model item ' || $text)
  :)
  ()
};

declare function local:end($text as xs:string, $status as xs:string) as empty-sequence()
{
  (:
  local:log('Ending model item ' || $text || ' - Result: ' || $status)
  :)
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
let $logentry := local:log('Testing ' || count($features) || ' features.')

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

(: Assertions follow below :)

let $timestampSuite := fn:current-dateTime()
let $startmessage := prof:void(local:start(EID545f9e49-009b-4114-9333-7ca26413b5d4))
let $logentry := local:log('Test Suite ''INSPIRE GML encoding'' started')
let $testmoduleresults := (
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start(EID8e96257c-ae42-4123-b298-b8c5eda3a027))
let $logentry := local:log('Test Module ''TODO'' started')
let $testcaseresults := (
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start(EIDf66872d4-3a1f-4581-a501-94200219bf13))
let $logentry := local:log('Test Case ''Basic test'' started')
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start(EIDc177cf64-3a66-4ac4-92b9-61207aab8007)) 
let $logentry := local:log('Test Step ''TODO'' started')
let $assertionresults := ((
let $startmessage := prof:void(local:start(EID928d8204-3015-4811-82fd-f4779b35385b)) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $filesWithErrors := $db[not(wfs:FeatureCollection or gml:FeatureCollection or base:SpatialDataSet)][position() le $limitErrors]
return 
(if ($filesWithErrors) then 'FAILED' else 'PASSED',
 for $file in $filesWithErrors
    order by local:filename($file)
    let $root := $file/element()
    return
     (local:addMessage('errorInFile', map { '$filename': local:filename($root), '$count': '1' }),
      local:addMessage('incorrectRoot', map { '$filename': local:filename($root), '$elementName': local-name($root), '$namespace': namespace-uri($root) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end(EID928d8204-3015-4811-82fd-f4779b35385b,$status))
let $logentry := local:log('Test Assertion ''Root element'': ' || $duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME.EID928d8204-3015-4811-82fd-f4779b35385b'>
    <parent ref='EIDc177cf64-3a66-4ac4-92b9-61207aab8007'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID928d8204-3015-4811-82fd-f4779b35385b'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>))
let $status := local:status($assertionresults/etf:resultStatus)
let $endmessage := prof:void(local:end(EIDc177cf64-3a66-4ac4-92b9-61207aab8007,$status))
let $logentry := local:log('Test Step ''TODO'' finished')
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME.EIDc177cf64-3a66-4ac4-92b9-61207aab8007'>
<parent ref='EIDf66872d4-3a1f-4581-a501-94200219bf13'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EIDc177cf64-3a66-4ac4-92b9-61207aab8007'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := local:status($teststepresults/etf:resultStatus)
let $endmessage := prof:void(local:end(EIDf66872d4-3a1f-4581-a501-94200219bf13,$status))
let $logentry := local:log('Test Case ''Basic test'' finished')
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME.EIDf66872d4-3a1f-4581-a501-94200219bf13'>
<parent ref='EID8e96257c-ae42-4123-b298-b8c5eda3a027'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EIDf66872d4-3a1f-4581-a501-94200219bf13'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>,
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start(EIDf66872d4-3a1f-4581-a501-94200219bf13))
let $logentry := local:log('Test Case ''Basic test'' started')
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start(EIDc177cf64-3a66-4ac4-92b9-61207aab8007)) 
let $logentry := local:log('Test Step ''TODO'' started')
let $assertionresults := (
  let $startmessage := prof:void(local:start(EID928d8204-3015-4811-82fd-f4779b35385b)) 
  let $endmessage := prof:void(local:end(EID928d8204-3015-4811-82fd-f4779b35385b,'NOT_APPLICABLE'))
  let $logentry := local:log('Test Assertion ''Character encoding'': skipped')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME.EID928d8204-3015-4811-82fd-f4779b35385b'>
    <parent ref='EIDc177cf64-3a66-4ac4-92b9-61207aab8007'/>
    <resultStatus>NOT_APPLICABLE</resultStatus>
    <startTimestamp>2016-08-10T18:54:43.897+02:00</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID928d8204-3015-4811-82fd-f4779b35385b'/>
    <messages/>
  </TestAssertionResult>)
let $status := local:status($assertionresults/etf:resultStatus)
let $endmessage := prof:void(local:end(EIDc177cf64-3a66-4ac4-92b9-61207aab8007,$status))
let $logentry := local:log('Test Step ''TODO'' finished')
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME.EIDc177cf64-3a66-4ac4-92b9-61207aab8007'>
<parent ref='EIDf66872d4-3a1f-4581-a501-94200219bf13'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EIDc177cf64-3a66-4ac4-92b9-61207aab8007'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := local:status($teststepresults/etf:resultStatus)
let $endmessage := prof:void(local:end(EIDf66872d4-3a1f-4581-a501-94200219bf13,$status))
let $logentry := local:log('Test Case ''Basic test'' finished')
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME.EIDf66872d4-3a1f-4581-a501-94200219bf13'>
<parent ref='EID8e96257c-ae42-4123-b298-b8c5eda3a027'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EIDf66872d4-3a1f-4581-a501-94200219bf13'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>)
let $status := local:status($testcaseresults/etf:resultStatus)
let $endmessage := prof:void(local:end(EID8e96257c-ae42-4123-b298-b8c5eda3a027,$status))
let $logentry := local:log('Test Module ''TODO'' finished')
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME.EID8e96257c-ae42-4123-b298-b8c5eda3a027'>
<parent ref='EID545f9e49-009b-4114-9333-7ca26413b5d4'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampModule}</startTimestamp>
<duration>{sum($testcaseresults/duration)}</duration>
<resultedFrom ref='EID8e96257c-ae42-4123-b298-b8c5eda3a027'/>
<testCaseResults>{$testcaseresults}</testCaseResults>
</TestModuleResult>)
let $status := local:status($testmoduleresults/etf:resultStatus)
let $endmessage := prof:void(local:end(EID545f9e49-009b-4114-9333-7ca26413b5d4,$status))
let $logentry := local:log('Test Suite ''INSPIRE GML encoding'' finished')
return
<TestTaskResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='EID00000000-0000-0000-0000-0000000000003'>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{sum($testmoduleresults/duration)}</duration>
<resultedFrom ref='EID545f9e49-009b-4114-9333-7ca26413b5d4'/>
<attachements>
<Attachment>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='TODO'/>
</Attachment>
</attachements>
<testModuleResults>{$testmoduleresults}</testModuleResults>
</TestTaskResult>