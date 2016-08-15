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
let $startmessage := prof:void(local:start('EID09820daf-62b2-4fa3-a95f-56a0d2b7c4d8'))
let $logentry := local:log('Test Suite ''INSPIRE GML application schemas'' started')
let $testmoduleresults := (
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID073b8871-8ce0-4ba8-9b53-f1aec2019d3b'))
let $testcaseresults := (
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID071a80e9-332e-4219-b600-329f47b98ef1'))
let $logentry := local:log('Test Case ''Schema'' started')
let $dependencyResult := true()
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID871889b6-5664-4498-8762-849fb77a084f')) 
let $assertionresults := (
  let $startmessage := prof:void(local:start('EID09ad14e3-d46f-42fc-9b01-64cb6ed2134c')) 
  let $endmessage := prof:void(local:end('EID09ad14e3-d46f-42fc-9b01-64cb6ed2134c','PASSED_MANUAL'))
  let $logentry := local:log('Test Assertion ''a.1: Mapping of source data to INSPIRE'': PASSED_MANUAL')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID871889b6-5664-4498-8762-849fb77a084f'/>
    <resultStatus>PASSED_MANUAL</resultStatus>
    <startTimestamp>2016-08-15T11:59:59.95+02:00</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID09ad14e3-d46f-42fc-9b01-64cb6ed2134c'/>
    <messages/>
  </TestAssertionResult>,
  let $startmessage := prof:void(local:start('EID77f090cf-48ef-46f3-901b-6ef2db4a1599')) 
  let $endmessage := prof:void(local:end('EID77f090cf-48ef-46f3-901b-6ef2db4a1599','PASSED_MANUAL'))
  let $logentry := local:log('Test Assertion ''a.2: Modelling of additional spatial object types'': PASSED_MANUAL')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID871889b6-5664-4498-8762-849fb77a084f'/>
    <resultStatus>PASSED_MANUAL</resultStatus>
    <startTimestamp>2016-08-15T11:59:59.95+02:00</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID77f090cf-48ef-46f3-901b-6ef2db4a1599'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID871889b6-5664-4498-8762-849fb77a084f',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID071a80e9-332e-4219-b600-329f47b98ef1'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EID871889b6-5664-4498-8762-849fb77a084f'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID071a80e9-332e-4219-b600-329f47b98ef1',$status))
let $logentry := local:log('Test Case ''Schema'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID073b8871-8ce0-4ba8-9b53-f1aec2019d3b'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EID071a80e9-332e-4219-b600-329f47b98ef1'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>,
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID2c6fe882-7c53-47f2-b4c4-66b15c248be4'))
let $logentry := local:log('Test Case ''Schema validation'' started')
let $dependencyResult := true()
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID77f090cf-48ef-46f3-901b-6ef2db4a1599')) 
let $assertionresults := (
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID40646a32-7b85-411f-abc7-1eba528d7d95')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $filesWithErrors := $db[not(/*/@xsi:schemaLocation)][position() le $limitErrors]
return
(if ($filesWithErrors) then 'FAILED' else 'PASSED',
 for $file in $filesWithErrors
    order by local:filename($file)
    let $root := $file/element()
    return
     (local:addMessage('errorInFile', map { 'filename': local:filename($root), 'count': '1' }),
      local:addMessage('noSchemaLocation', map { 'filename': local:filename($root) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID40646a32-7b85-411f-abc7-1eba528d7d95',$status))
let $logentry := local:log('Test Assertion ''b.1: xsi:schemaLocation attribute'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID77f090cf-48ef-46f3-901b-6ef2db4a1599'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID40646a32-7b85-411f-abc7-1eba528d7d95'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID40646a32-7b85-411f-abc7-1eba528d7d95')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID40646a32-7b85-411f-abc7-1eba528d7d95',$status))
let $logentry := local:log('Test Assertion ''b.1: xsi:schemaLocation attribute'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID77f090cf-48ef-46f3-901b-6ef2db4a1599'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID40646a32-7b85-411f-abc7-1eba528d7d95'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID0eaac0f2-9ab3-44ab-9f02-4ee0a1587d14')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $errors := for $file in $db
  let $messages := validate:xsd-info($file)
  let $errors := count($messages)
  let $root := $file/element()
  return
   if ($errors>0) then
    (local:addMessage('errorInFile', map { 'filename': local:filename($root), 'count': string($errors) }),
     local:addMessage('invalidSchema', map { 'filename': local:filename($root), 'issues': fn:string-join($messages,file:line-separator()) }))
   else ()						 
return
(if ($errors) then 'FAILED' else 'PASSED',
 $errors) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID0eaac0f2-9ab3-44ab-9f02-4ee0a1587d14',$status))
let $logentry := local:log('Test Assertion ''b.2: validate XML documents'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID77f090cf-48ef-46f3-901b-6ef2db4a1599'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID0eaac0f2-9ab3-44ab-9f02-4ee0a1587d14'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID0eaac0f2-9ab3-44ab-9f02-4ee0a1587d14')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID0eaac0f2-9ab3-44ab-9f02-4ee0a1587d14',$status))
let $logentry := local:log('Test Assertion ''b.2: validate XML documents'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID77f090cf-48ef-46f3-901b-6ef2db4a1599'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID0eaac0f2-9ab3-44ab-9f02-4ee0a1587d14'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID77f090cf-48ef-46f3-901b-6ef2db4a1599',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID2c6fe882-7c53-47f2-b4c4-66b15c248be4'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EID77f090cf-48ef-46f3-901b-6ef2db4a1599'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID2c6fe882-7c53-47f2-b4c4-66b15c248be4',$status))
let $logentry := local:log('Test Case ''Schema validation'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID073b8871-8ce0-4ba8-9b53-f1aec2019d3b'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EID2c6fe882-7c53-47f2-b4c4-66b15c248be4'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>,
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID18099150-f7ac-4174-a7b6-45121383a5d3'))
let $logentry := local:log('Test Case ''GML model'' started')
let $dependencyResult := true()
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b')) 
let $assertionresults := (
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDb33aaf9a-898f-4625-b87f-81c07ac09adf')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $propertiesWithErrors := $features/*[not(@xlink:href or element() or (text() and string-length(normalize-space(text()))>0) or @xsi:nil eq 'true')][position() le $limitErrors]
let $featureIdsWithErrors := fn:distinct-values($propertiesWithErrors/../@gml:id)
return
(if ($propertiesWithErrors) then 'FAILED' else 'PASSED',
 for $gmlid in $featureIdsWithErrors
   order by $gmlid
   let $feature := $features[@gml:id=$gmlid]
   let $properties := $feature/*[not(@xlink:href or element() or (text() and string-length(normalize-space(text()))>0) or @xsi:nil eq 'true')]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $gmlid, 'count': string(count($properties)) }),
      local:addMessage('emptyValue', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $gmlid, 'propertyNames': fn:string-join($properties/local-name(),', ') }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDb33aaf9a-898f-4625-b87f-81c07ac09adf',$status))
let $logentry := local:log('Test Assertion ''c.1: Consistency with the GML model'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDb33aaf9a-898f-4625-b87f-81c07ac09adf'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDb33aaf9a-898f-4625-b87f-81c07ac09adf')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDb33aaf9a-898f-4625-b87f-81c07ac09adf',$status))
let $logentry := local:log('Test Assertion ''c.1: Consistency with the GML model'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDb33aaf9a-898f-4625-b87f-81c07ac09adf'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDb62f96a5-349f-40dd-b777-1e52ea09b686')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $propertiesWithErrors := $features/*[@nilReason and not(@xsi:nil eq 'true')][position() le $limitErrors]
let $featureIdsWithErrors := fn:distinct-values($propertiesWithErrors/../@gml:id)
return
(if ($propertiesWithErrors) then 'FAILED' else 'PASSED',
 for $gmlid in $featureIdsWithErrors
   order by $gmlid
   let $feature := $features[@gmlid=$gmlid]
   let $properties := $feature/*[@nilReason and not(@xsi:nil eq 'true')]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $gmlid, 'count': string(count($properties)) }),
      local:addMessage('nilMissing', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $gmlid, 'propertyNames': fn:string-join($properties/local-name(),', ') }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDb62f96a5-349f-40dd-b777-1e52ea09b686',$status))
let $logentry := local:log('Test Assertion ''c.2: nilReason attributes require xsi:nil=true'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDb62f96a5-349f-40dd-b777-1e52ea09b686'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDb62f96a5-349f-40dd-b777-1e52ea09b686')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDb62f96a5-349f-40dd-b777-1e52ea09b686',$status))
let $logentry := local:log('Test Assertion ''c.2: nilReason attributes require xsi:nil=true'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDb62f96a5-349f-40dd-b777-1e52ea09b686'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDabc9199e-d5a8-4829-80bd-09b7e49e2a76')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { let $values := ( 'http://inspire.ec.europa.eu/codelist/VoidReasonValue/Unknown', 'http://inspire.ec.europa.eu/codelist/VoidReasonValue/Unpopulated', 'http://inspire.ec.europa.eu/codelist/VoidReasonValue/Withheld', 'unknown', 'other:unpopulated', 'withheld' )
let $propertiesWithErrors := $features/*[@xsi:nil eq 'true' and not(@nilReason =  $values)][position() le $limitErrors]
let $featureIdsWithErrors := fn:distinct-values($propertiesWithErrors/../@gml:id)
return
(if ($propertiesWithErrors) then 'FAILED' else 'PASSED',
 for $gmlid in $featureIdsWithErrors
   order by $gmlid
   let $feature := $features[@gmlid=$gmlid]
   let $properties := $feature/*[@xsi:nil eq 'true' and not(@nilReason =  $values)]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $gmlid, 'count': string(count($properties)) }),
      local:addMessage('incorrectReason', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $gmlid, 'propertyNames': fn:string-join($properties/local-name(),', ') }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDabc9199e-d5a8-4829-80bd-09b7e49e2a76',$status))
let $logentry := local:log('Test Assertion ''c.3: nilReason values'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDabc9199e-d5a8-4829-80bd-09b7e49e2a76'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDabc9199e-d5a8-4829-80bd-09b7e49e2a76')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDabc9199e-d5a8-4829-80bd-09b7e49e2a76',$status))
let $logentry := local:log('Test Assertion ''c.3: nilReason values'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDabc9199e-d5a8-4829-80bd-09b7e49e2a76'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID18099150-f7ac-4174-a7b6-45121383a5d3'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EIDc04ade3c-0ad2-4fa5-9977-d83022855e3b'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID18099150-f7ac-4174-a7b6-45121383a5d3',$status))
let $logentry := local:log('Test Case ''GML model'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID073b8871-8ce0-4ba8-9b53-f1aec2019d3b'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EID18099150-f7ac-4174-a7b6-45121383a5d3'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>,
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID7e0765c8-c149-4cf2-956f-ca4db0e0ed94'))
let $logentry := local:log('Test Case ''Simple features'' started')
let $dependencyResult := true()
let $teststepresults := (
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('EID73531400-70ac-4374-83fd-5df504d5cfba')) 
let $assertionresults := (
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDf625c820-71a1-41e2-afb2-11cdc7d5a01b')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//*[self::gml:Node|self::gml:Edge|self::gml:Face|self::gml:TopoSolid|self::gml:TopoPoint|self::gml:TopoCurve|self::gml:TopoSurface|self::gml:TopoVolume|self::gml:TopoComplex]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $element := $feature//*[self::gml:Node|self::gml:Edge|self::gml:Face|self::gml:TopoSolid|self::gml:TopoPoint|self::gml:TopoCurve|self::gml:TopoSurface|self::gml:TopoVolume|self::gml:TopoComplex][1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('spatialTopologyTypeFound', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'elementName': name($element) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDf625c820-71a1-41e2-afb2-11cdc7d5a01b',$status))
let $logentry := local:log('Test Assertion ''d.1: No spatial topology objects'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDf625c820-71a1-41e2-afb2-11cdc7d5a01b'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDf625c820-71a1-41e2-afb2-11cdc7d5a01b')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDf625c820-71a1-41e2-afb2-11cdc7d5a01b',$status))
let $logentry := local:log('Test Assertion ''d.1: No spatial topology objects'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDf625c820-71a1-41e2-afb2-11cdc7d5a01b'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID44cf3e26-809e-49a9-8ec0-750a373e9ff1')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//gml:Curve/gml:segments/*[not(self::gml:LineStringSegment)]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $element := $feature//gml:Curve/gml:segments/*[not(self::gml:LineStringSegment)][1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('invalidInterpolationFound', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'elementName': name($element) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID44cf3e26-809e-49a9-8ec0-750a373e9ff1',$status))
let $logentry := local:log('Test Assertion ''d.2: No non-linear interpolation'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID44cf3e26-809e-49a9-8ec0-750a373e9ff1'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID44cf3e26-809e-49a9-8ec0-750a373e9ff1')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID44cf3e26-809e-49a9-8ec0-750a373e9ff1',$status))
let $logentry := local:log('Test Assertion ''d.2: No non-linear interpolation'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID44cf3e26-809e-49a9-8ec0-750a373e9ff1'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID3d7ad0b2-c9f5-4910-aa09-b3226b720f7d')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//*[self::gml:OrientableSurface|self::gml:CompositeSurface|self::gml:PolyhedralSurface|self::gml:Tin|self::gml:TriangulatedSurface]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $element := $feature//*[self::gml:OrientableSurface|self::gml:CompositeSurface|self::gml:PolyhedralSurface|self::gml:Tin|self::gml:TriangulatedSurface][1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('invalidSurfaceElementFound', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'elementName': name($element) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID3d7ad0b2-c9f5-4910-aa09-b3226b720f7d',$status))
let $logentry := local:log('Test Assertion ''d.3: Surface geometry elements'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID3d7ad0b2-c9f5-4910-aa09-b3226b720f7d'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID3d7ad0b2-c9f5-4910-aa09-b3226b720f7d')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID3d7ad0b2-c9f5-4910-aa09-b3226b720f7d',$status))
let $logentry := local:log('Test Assertion ''d.3: Surface geometry elements'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID3d7ad0b2-c9f5-4910-aa09-b3226b720f7d'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID008b7c4f-b315-4596-b5e9-4a29910eb43f')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//gml:Surface/gml:patches/*[not(self::gml:PolygonPatch)]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $element := $feature//gml:Surface/gml:patches/*[not(self::gml:PolygonPatch)][1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('invalidSurfacePatchElementFound', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'elementName': name($element) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID008b7c4f-b315-4596-b5e9-4a29910eb43f',$status))
let $logentry := local:log('Test Assertion ''d.4: No non-planar interpolation'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID008b7c4f-b315-4596-b5e9-4a29910eb43f'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID008b7c4f-b315-4596-b5e9-4a29910eb43f')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID008b7c4f-b315-4596-b5e9-4a29910eb43f',$status))
let $logentry := local:log('Test Assertion ''d.4: No non-planar interpolation'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID008b7c4f-b315-4596-b5e9-4a29910eb43f'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID4f2f9722-897a-4bad-b11e-d4e119b6690d')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//*[self::gml:Solid|self::gml:MultiSolid|self::gml:CompositeSolid|self::gml:CompositeCurve|self::gml:Grid]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $element := $feature//*[self::gml:Solid|self::gml:MultiSolid|self::gml:CompositeSolid|self::gml:CompositeCurve|self::gml:Grid][1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('invalidGeometryElementFound', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'elementName': name($element) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID4f2f9722-897a-4bad-b11e-d4e119b6690d',$status))
let $logentry := local:log('Test Assertion ''d.5: Geometry elements'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID4f2f9722-897a-4bad-b11e-d4e119b6690d'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID4f2f9722-897a-4bad-b11e-d4e119b6690d')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID4f2f9722-897a-4bad-b11e-d4e119b6690d',$status))
let $logentry := local:log('Test Assertion ''d.5: Geometry elements'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID4f2f9722-897a-4bad-b11e-d4e119b6690d'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDbc49770c-4eab-4330-8462-af0664ae0b80')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//gml:Point/*[not(self::gml:pos)]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $element := $feature//gml:Point/*[not(self::gml:pos)][1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('invalidPositionElementFound', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'elementName': name($element), 'geometryType': 'point', 'posElementName': 'gml:pos' }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDbc49770c-4eab-4330-8462-af0664ae0b80',$status))
let $logentry := local:log('Test Assertion ''d.6: Point coordinates in gml:pos'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDbc49770c-4eab-4330-8462-af0664ae0b80'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDbc49770c-4eab-4330-8462-af0664ae0b80')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDbc49770c-4eab-4330-8462-af0664ae0b80',$status))
let $logentry := local:log('Test Assertion ''d.6: Point coordinates in gml:pos'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDbc49770c-4eab-4330-8462-af0664ae0b80'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID894c6a96-4fb2-4921-ad98-1d2a52985887')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//*[self::gml:LineString|self::gml:LineStringSegment|self::gml:LinearRing]/*[not(self::gml:posList)]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $element := ($feature//*[self::gml:LineString|self::gml:LineStringSegment|self::gml:LinearRing|self::gml:Arc|self::gml:Circle]/*[not(self::gml:posList)])[1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('invalidPositionElementFound', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'elementName': name($element), 'geometryType': 'curve/surface', 'posElementName': 'gml:posList' }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID894c6a96-4fb2-4921-ad98-1d2a52985887',$status))
let $logentry := local:log('Test Assertion ''d.7: Curve/Surface coordinates in gml:posList'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID894c6a96-4fb2-4921-ad98-1d2a52985887'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID894c6a96-4fb2-4921-ad98-1d2a52985887')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID894c6a96-4fb2-4921-ad98-1d2a52985887',$status))
let $logentry := local:log('Test Assertion ''d.7: Curve/Surface coordinates in gml:posList'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID894c6a96-4fb2-4921-ad98-1d2a52985887'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID160e4f83-e9c3-45c5-b684-20027f8f191a')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//*[self::gml:MultiPoint/gml:pointMembers|self::gml:MultiCurve/gml:curveMembers|self::gml:MultiSurface/gml:surfaceMembers|self::gml:MultiGeometry/gml:geometryMembers]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $element := ($feature//*[self::gml:MultiPoint|self::gml:MultiCurve|self::gml:MultiSurface|self::gml:MultiGeometry]/*[self::gml:pointMembers|self::gml:curveMembers|self::gml:surfaceMembers|self::gml:geometryMembers])[1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('arrayElementFound', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'elementName': name($element) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID160e4f83-e9c3-45c5-b684-20027f8f191a',$status))
let $logentry := local:log('Test Assertion ''d.8: No array property elements'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID160e4f83-e9c3-45c5-b684-20027f8f191a'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID160e4f83-e9c3-45c5-b684-20027f8f191a')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID160e4f83-e9c3-45c5-b684-20027f8f191a',$status))
let $logentry := local:log('Test Assertion ''d.8: No array property elements'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID160e4f83-e9c3-45c5-b684-20027f8f191a'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EIDf9e92525-152a-41fa-9990-42691f39b1ce')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := $featuresToInspect[.//*[@srsDimension > 3]][position() le $limitErrors]
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   let $dimension := $feature//@srsDimension[. > 3][1]
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('tooManyDimensions', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'dimension': string($dimension) }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EIDf9e92525-152a-41fa-9990-42691f39b1ce',$status))
let $logentry := local:log('Test Assertion ''d.9: 1, 2 or 3 coordinate dimensions'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EIDf9e92525-152a-41fa-9990-42691f39b1ce'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EIDf9e92525-152a-41fa-9990-42691f39b1ce')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EIDf9e92525-152a-41fa-9990-42691f39b1ce',$status))
let $logentry := local:log('Test Assertion ''d.9: 1, 2 or 3 coordinate dimensions'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EIDf9e92525-152a-41fa-9990-42691f39b1ce'/>
    <messages/>
  </TestAssertionResult>,
if ($dependencyResult) then
let $startmessage := prof:void(local:start('EID79aec969-3ca0-4190-a6e9-8b49682f414a')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { (: TODO: add other feature types to exclude; extend with subtypes :)
let $featuresToInspect := $features[not(self::*:CadastralParcel)]  
let $featuresWithErrors := for $feature in $featuresToInspect
  return
   if (contains(ggeo:validate($feature,'110'),'F')) then $feature else ()
return
(if ($featuresWithErrors) then 'FAILED' else 'PASSED',
 for $feature in $featuresWithErrors
   order by $feature/@gml:id
   return
     (local:addMessage('errorInFeature', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id, 'count': '1' }),
      local:addMessage('invalidGeometry', map { 'filename': local:filename($feature), 'featureType': local-name($feature), 'gmlid': $feature/@gml:id }))) } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('EID79aec969-3ca0-4190-a6e9-8b49682f414a',$status))
let $logentry := local:log('Test Assertion ''d.10: Validate geometries'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='EID79aec969-3ca0-4190-a6e9-8b49682f414a'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('EID79aec969-3ca0-4190-a6e9-8b49682f414a')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('EID79aec969-3ca0-4190-a6e9-8b49682f414a',$status))
let $logentry := local:log('Test Assertion ''d.10: Validate geometries'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='EID79aec969-3ca0-4190-a6e9-8b49682f414a'/>
    <messages/>
  </TestAssertionResult>)
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID73531400-70ac-4374-83fd-5df504d5cfba',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID7e0765c8-c149-4cf2-956f-ca4db0e0ed94'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='EID73531400-70ac-4374-83fd-5df504d5cfba'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>)
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('EID7e0765c8-c149-4cf2-956f-ca4db0e0ed94',$status))
let $logentry := local:log('Test Case ''Simple features'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID073b8871-8ce0-4ba8-9b53-f1aec2019d3b'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='EID7e0765c8-c149-4cf2-956f-ca4db0e0ed94'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>)
let $status := local:status($testcaseresults/etf:resultStatus)
let $endmessage := prof:void(local:end('EID073b8871-8ce0-4ba8-9b53-f1aec2019d3b',$status))
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='EID09820daf-62b2-4fa3-a95f-56a0d2b7c4d8'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampModule}</startTimestamp>
<duration>{sum($testcaseresults/duration)}</duration>
<resultedFrom ref='EID073b8871-8ce0-4ba8-9b53-f1aec2019d3b'/>
<testCaseResults>{$testcaseresults}</testCaseResults>
</TestModuleResult>)
let $status := local:status($testmoduleresults/etf:resultStatus)
let $endmessage := prof:void(local:end('EID09820daf-62b2-4fa3-a95f-56a0d2b7c4d8',$status))
let $logentry := local:log('Test Suite ''INSPIRE GML application schemas'' finished')
return
<TestTaskResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='4d820861-048a-4733-8763-eba82a717289'>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{sum($testmoduleresults/duration)}</duration>
<resultedFrom ref='EID09820daf-62b2-4fa3-a95f-56a0d2b7c4d8'/>
<testObject ref='{$testObjectId}'/>
<attachements>
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/4d820861-048a-4733-8763-eba82a717289-log.txt')) then 
<Attachment>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/4d820861-048a-4733-8763-eba82a717289-log.txt'/>
</Attachment>
else ()}
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/4d820861-048a-4733-8763-eba82a717289-stat.xml')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/4d820861-048a-4733-8763-eba82a717289-stat.xml'/>
</Attachment>
else ()}
{ if (file:exists('/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/4d820861-048a-4733-8763-eba82a717289-query.xq')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>XQuery executed against the dataset</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='file:/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data-encoding/inspire-gml/tmp/4d820861-048a-4733-8763-eba82a717289-query.xq'/>
</Attachment>
else ()}
</attachements>
<testModuleResults>{$testmoduleresults}</testModuleResults>
</TestTaskResult>