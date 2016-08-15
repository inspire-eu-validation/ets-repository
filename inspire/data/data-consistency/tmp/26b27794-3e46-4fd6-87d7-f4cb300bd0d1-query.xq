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
let $startmessage := prof:void(local:start('EID61070ae8-13cb-4303-a340-72c8b877b00a'))
let $logentry := local:log('Test Suite ''Data consistency'' started')
let $testmoduleresults := (
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start('EIDcdde50c8-7645-4a51-9a91-8d7fd6c0ff0a'))
let $testcaseresults := (
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID34e2a27a-e57e-486a-a612-bfa89c963116'))
let $logentry := local:log('Test Case ''Version consistency'' started')
let $dependencyResult := true()
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EIDd42be9c8-dd7a-49f2-bb0e-fc2650d6ac5d')) 
let $assertionresults := (
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDc88de361-bf4d-4fdb-8cc0-68d1a62e5eae')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $featuresWithErrors := $features[(*[self::*:beginLifespanVersion and not(xsi:nil='true')] and *[self::*:endLifespanVersion and not(xsi:nil='true')] and xs:dateTime(*:beginLifespanVersion[1]/text()) >= xs:dateTime(*:endLifespanVersion[1]/text()))][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $begin := $feature/*[self::*:beginLifespanVersion][1]/text()
   let $end := $feature/*[self::*:endLifespanVersion][1]/text()
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('endTooEarly', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'begin': $begin, 'end': $end, 'propertyBegin': 'beginLifespanVersion', 'propertyEnd': 'endLifespanVersion' }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDc88de361-bf4d-4fdb-8cc0-68d1a62e5eae',$status))
let $logentry := local:log('Test Assertion ''a.1:'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDd42be9c8-dd7a-49f2-bb0e-fc2650d6ac5d'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDc88de361-bf4d-4fdb-8cc0-68d1a62e5eae'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDc88de361-bf4d-4fdb-8cc0-68d1a62e5eae')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDc88de361-bf4d-4fdb-8cc0-68d1a62e5eae',$status))
let $logentry := local:log('Test Assertion ''a.1:'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDd42be9c8-dd7a-49f2-bb0e-fc2650d6ac5d'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDc88de361-bf4d-4fdb-8cc0-68d1a62e5eae'/>
    <messages/>
  </TestAssertionResult>,
  let $startmessage := prof:void(local:start('EIDeaa9832a-a372-484a-b25b-c67e1c808e0f')) 
  let $endmessage := prof:void(local:end('EIDeaa9832a-a372-484a-b25b-c67e1c808e0f','PASSED_MANUAL'))
  let $logentry := local:log('Test Assertion ''a.2: Unique identifier persistency'': PASSED_MANUAL')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDd42be9c8-dd7a-49f2-bb0e-fc2650d6ac5d'/>
    <resultStatus>PASSED_MANUAL</resultStatus>
    <startTimestamp>2016-08-15T12:01:11.263+02:00</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDeaa9832a-a372-484a-b25b-c67e1c808e0f'/>
    <messages/>
  </TestAssertionResult>,
  let $startmessage := prof:void(local:start('EID2b8243c8-e2e7-402d-97f1-86110b70e55e')) 
  let $endmessage := prof:void(local:end('EID2b8243c8-e2e7-402d-97f1-86110b70e55e','PASSED_MANUAL'))
  let $logentry := local:log('Test Assertion ''a.3: Spatial object type stable'': PASSED_MANUAL')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDd42be9c8-dd7a-49f2-bb0e-fc2650d6ac5d'/>
    <resultStatus>PASSED_MANUAL</resultStatus>
    <startTimestamp>2016-08-15T12:01:11.263+02:00</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID2b8243c8-e2e7-402d-97f1-86110b70e55e'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EIDd42be9c8-dd7a-49f2-bb0e-fc2650d6ac5d',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID34e2a27a-e57e-486a-a612-bfa89c963116'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EIDd42be9c8-dd7a-49f2-bb0e-fc2650d6ac5d'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID34e2a27a-e57e-486a-a612-bfa89c963116',$status))
let $logentry := local:log('Test Case ''Version consistency'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EIDcdde50c8-7645-4a51-9a91-8d7fd6c0ff0a'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EID34e2a27a-e57e-486a-a612-bfa89c963116'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>,
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID4ca5564d-2643-4ee3-9ec9-bf97043d3fa0'))
let $logentry := local:log('Test Case ''Temporal consistency'' started')
let $dependencyResult := true()
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID72a3ee32-8582-4f67-80a0-435f636f8cf3')) 
let $assertionresults := (
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDcefa9614-ce69-43d4-bed5-7758e7d890a9')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $featuresWithErrors := $features[*[self::*:validFrom and not(xsi:nil='true')] and *[self::*:validTo and not(xsi:nil='true')] and xs:dateTime(*:validFrom/text()) >= xs:dateTime(*:validTo/text())][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $begin := $feature/*[self::*:validFrom][1]/text()
   let $end := $feature/*[self::*:validTo][1]/text()
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('endTooEarly', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'begin': $begin, 'end': $end, 'propertyBegin': 'validFrom', 'propertyEnd': 'validTo' }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDcefa9614-ce69-43d4-bed5-7758e7d890a9',$status))
let $logentry := local:log('Test Assertion ''b.1: Validity time sequence'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID72a3ee32-8582-4f67-80a0-435f636f8cf3'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDcefa9614-ce69-43d4-bed5-7758e7d890a9'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDcefa9614-ce69-43d4-bed5-7758e7d890a9')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDcefa9614-ce69-43d4-bed5-7758e7d890a9',$status))
let $logentry := local:log('Test Assertion ''b.1: Validity time sequence'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID72a3ee32-8582-4f67-80a0-435f636f8cf3'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDcefa9614-ce69-43d4-bed5-7758e7d890a9'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID72a3ee32-8582-4f67-80a0-435f636f8cf3',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID4ca5564d-2643-4ee3-9ec9-bf97043d3fa0'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EID72a3ee32-8582-4f67-80a0-435f636f8cf3'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID4ca5564d-2643-4ee3-9ec9-bf97043d3fa0',$status))
let $logentry := local:log('Test Case ''Temporal consistency'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EIDcdde50c8-7645-4a51-9a91-8d7fd6c0ff0a'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EID4ca5564d-2643-4ee3-9ec9-bf97043d3fa0'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>)
let $status := local:status($testcaseresults/etf:resultStatus)
let $endmessage := prof:void(local:end('EIDcdde50c8-7645-4a51-9a91-8d7fd6c0ff0a',$status))
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID61070ae8-13cb-4303-a340-72c8b877b00a'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampModule}</startTimestamp>
<duration>{sum($testcaseresults/duration)}</duration>
<resultedFrom ref='EIDcdde50c8-7645-4a51-9a91-8d7fd6c0ff0a'/>
<testCaseResults>{$testcaseresults}</testCaseResults>
</TestModuleResult>)
let $status := local:status($testmoduleresults/etf:resultStatus)
let $endmessage := prof:void(local:end('EID61070ae8-13cb-4303-a340-72c8b877b00a',$status))
let $logentry := local:log('Test Suite ''Data consistency'' finished')
return
<TestTaskResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='26b27794-3e46-4fd6-87d7-f4cb300bd0d1'>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{sum($testmoduleresults/duration)}</duration>
<resultedFrom ref='EID61070ae8-13cb-4303-a340-72c8b877b00a'/>
<testObject ref='{$testObjectId}'/>
<attachements>
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/26b27794-3e46-4fd6-87d7-f4cb300bd0d1-log.txt')) then 
<Attachment>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/26b27794-3e46-4fd6-87d7-f4cb300bd0d1-log.txt'/>
</Attachment>
else ()}
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/26b27794-3e46-4fd6-87d7-f4cb300bd0d1-stat.xml')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/26b27794-3e46-4fd6-87d7-f4cb300bd0d1-stat.xml'/>
</Attachment>
else ()}
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/26b27794-3e46-4fd6-87d7-f4cb300bd0d1-query.xq')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>XQuery executed against the dataset</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/26b27794-3e46-4fd6-87d7-f4cb300bd0d1-query.xq'/>
</Attachment>
else ()}
</attachements>
<testModuleResults>{$testmoduleresults}</testModuleResults>
</TestTaskResult>