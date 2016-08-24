declare namespace base32='http://inspire.ec.europa.eu/schemas/base/3.2';
declare namespace base='http://inspire.ec.europa.eu/schemas/base/3.3';
declare namespace gml='http://www.opengis.net/gml/3.2';
declare namespace wfs='http://www.opengis.net/wfs/2.0';
declare namespace xsi='http://www.w3.org/2001/XMLSchema-instance';
declare namespace xlink='http://www.w3.org/1999/xlink';
declare namespace etf='http://www.interactive-instruments.de/etf/2.0';
declare namespace uuid='java.util.UUID';

declare function local:test($db as document-node()*, $features as element()*, $ets as element()*, $testQuery as xs:string) as element()
{
<DsResultSet xmlns="http://www.interactive-instruments.de/etf/2.0">
<executableTestSuites>{$ets}</executableTestSuites>
<!-- TODO temporary during testing in BaseX GUI -->
<testObjects>
<TestObject id="{$testObjectId}">
<label>Sample data set</label>
<description>An INSPIRE data set encoded in GML.</description>
<version>1.0.0</version>
<author>unknown</author>
<creationDate>{fn:current-dateTime()}</creationDate>
<testObjectTypes>
<testObjectType xsi:type="loc" ref="EIDe1d4a306-7a78-4a3b-ae2d-cf5f0810853e"/>
</testObjectTypes>
</TestObject>
</testObjects>
<testObjectTypes>
<TestObjectType id="EIDe1d4a306-7a78-4a3b-ae2d-cf5f0810853e">
<label>INSPIRE data set in GML</label>
<description>A set of XML documents. Each document is either a WFS 2.0 FeatureCollection, a GML 3.2 Feature Collection or an INSPIRE Base 3.2 or 3.3 SpatialDataSet. All features are GML 3.2 Features.</description>
</TestObjectType>
</testObjectTypes>
<translationTemplateBundles>
{doc($translationTemplateBundle)}
</translationTemplateBundles>
<testRuns>
<TestRun id="{$testRunId}">
<label>Test Run in BaseX GUI</label>
<defaultLang>en</defaultLang>
<startTimestamp>{fn:current-dateTime()}</startTimestamp>
<testTasks>
<TestTask id="{$testTaskId}">
<parent ref="{$testRunId}"/>
<executableTestSuite ref="{$executableTestSuiteId}"/>
<testObject ref="{$testObjectId}"/>
<ArgumentList>
<arguments>
<argument name="files_to_test">{$files_to_test}</argument>
<argument name="tests_to_execute">{$tests_to_execute}</argument>
</arguments>
</ArgumentList>
<testTaskResult ref="{$testTaskResultId}"/>
</TestTask>
</testTasks>
</TestRun>
</testRuns>
<!-- TODO END temporary during testing in BaseX GUI -->
<testTaskResults>{let $query := $testQuery || (let $test-module-results :=
for $module in $ets//*[local-name()='TestModule']
let $test-case-results :=
for $case in $module//*[local-name()='TestCase']
  let $dep := if ($case/etf:dependencies) 
    then "let $dependencyResult := local:passed('" || $case/etf:dependencies/etf:testCase/@ref || "')" 
    else "let $dependencyResult := true()"
  let $test-step-results :=
    for $step in $case//*[local-name()='TestStep']
      let $assertion-results := 
        for $assertion in $step//*[local-name()='TestAssertion']
          let $type := $assertion/etf:testItemType
          let $disabled := if (not(matches($assertion/etf:label,$tests_to_execute)) or $type/@ref='EID92f22a19-2ec2-43f0-8971-c2da3eaafcd2' (:disabled :)) then 'NOT_APPLICABLE' else if ($type/@ref='EIDb48eeaa3-6a74-414a-879c-1dc708017e11' (: manual :)) then 'PASSED_MANUAL' else ()
          return
if ($disabled) then "
  let $startmessage := prof:void(local:start('" || $assertion/@id || "')) 
  let $endmessage := prof:void(local:end('" || $assertion/@id || "','" || $disabled || "'))
  let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': " || $disabled || "')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{uuid:randomUUID()}'>
    <parent ref='" || $step/@id || "'/>
    <status>" || $disabled || "</status>
    <startTimestamp>" || fn:current-dateTime() || "</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='" || $assertion/@id || "'/>
    <messages/>
  </TestAssertionResult>" 
else "
if ($dependencyResult) then
let $startmessage := prof:void(local:start('" || $assertion/@id || "')) 
let $start := prof:current-ms()
let $timestampAssertion := fn:current-dateTime()
let $result :=
try { " || $assertion/etf:expression || " } catch * {
  let $text := '[' || $err:code || '] ' || $err:description || ' &#xa;' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
  return ('FAILED', local:addMessage('TR.systemError', map { 'text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('" || $assertion/@id || "',$status))
let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{uuid:randomUUID()}'>
    <parent ref='" || $step/@id || "'/>
    <status>{$status}</status>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='" || $assertion/@id || "'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('" || $assertion/@id || "')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('" || $assertion/@id || "',$status))
let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{uuid:randomUUID()}'>
    <parent ref='" || $step/@id || "'/>
    <status>{$status}</status>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='" || $assertion/@id || "'/>
    <messages/>
  </TestAssertionResult>"

      return "
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('" || $step/@id || "')) 
let $assertionresults := (" || string-join( $assertion-results, ',' ) || ")
let $status := if ($dependencyResult) then local:status($assertionresults/etf:status) else 'SKIPPED'
let $endmessage := prof:void(local:end('" || $step/@id || "',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{uuid:randomUUID()}'>
<parent ref='" || $case/@id || "'/>
<status>{$status}</status>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='" || $step/@id || "'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>"

    return "
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start('" || $case/@id || "'))
let $logentry := local:log('Test Case ''" || $case/etf:label || "'' started')
" || $dep || "
let $teststepresults := (" || string-join( $test-step-results, ',' ) || ")
let $status := if ($dependencyResult) then local:status($teststepresults/etf:status) else 'SKIPPED'
let $endmessage := prof:void(local:end('" || $case/@id || "',$status))
let $logentry := local:log('Test Case ''" || $case/etf:label || "'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{uuid:randomUUID()}'>
<parent ref='" || $module/@id || "'/>
<status>{$status}</status>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='" || $case/@id || "'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>"

return "
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start('" || $module/@id || "'))
let $testcaseresults := (" || string-join( $test-case-results, ',' ) || ")
let $status := local:status($testcaseresults/etf:status)
let $endmessage := prof:void(local:end('" || $module/@id || "',$status))
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{uuid:randomUUID()}'>
<parent ref='" || $ets/@id || "'/>
<status>{$status}</status>
<startTimestamp>{$timestampModule}</startTimestamp>
<duration>{sum($testcaseresults/duration)}</duration>
<resultedFrom ref='" || $module/@id || "'/>
<testCaseResults>{$testcaseresults}</testCaseResults>
</TestModuleResult>"

return "
let $timestampSuite := fn:current-dateTime()
let $startmessage := prof:void(local:start('" || $ets/@id || "'))
let $logentry := local:log('Test Suite ''" || $ets/etf:label || "'' started')
let $testmoduleresults := (" || string-join( $test-module-results, ',' ) || ")
let $status := local:status($testmoduleresults/etf:status)
let $endmessage := prof:void(local:end('" || $ets/@id || "',$status))
let $logentry := local:log('Test Suite ''" || $ets/etf:label || "'' finished: ' || $status)
return
<TestTaskResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='" || $testTaskResultId || "'>
<parent ref='" || $testTaskId || "'/>
<status>{$status}</status>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{sum($testmoduleresults/duration)}</duration>
<resultedFrom ref='" || $ets/@id || "'/>
<testObject ref='{$testObjectId}'/>
<attachements>
{ if (file:exists('" || $logFile || "')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/2.0' type='LogFile'>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='" || file:path-to-uri($logFile) || "'/>
</Attachment>
else ()}
{ if (file:exists('" || $statFile || "')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/2.0' type='StatisticalReport'>
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='" || file:path-to-uri($statFile) || "'/>
</Attachment>
else ()}
{ if (file:exists('" || $queryFile || "')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/2.0' type='Query'>
<label>XQuery executed against the dataset</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='" || file:path-to-uri($queryFile) || "'/>
</Attachment>
else ()}
</attachements>
<testModuleResults>{$testmoduleresults}</testModuleResults>
</TestTaskResult>")

let $writeQuery := file:write($queryFile, $query, map { "method": "text", "media-type": "text/plain" })

return try {
  xquery:eval($query, map {'features': $features, 'idMap': map:merge($features ! map:entry(fn:string(gml:identifier), .)), 'validationErrors': $validationErrors, 'db': $db, 'files_to_test': $files_to_test, 'tests_to_execute': $tests_to_execute, 'limitErrors': $limitErrors, 'testObjectId': $testObjectId, 'executableTestSuiteId': $executableTestSuiteId, 'testTaskResultId': $testTaskResultId, 'testObjectTypeIds': $testObjectTypeIds, 'translationTemplateBundleId': $translationTemplateBundleId, 'logFile': $logFile, 'statFile': $statFile })
} catch * {      
<TestTaskResult xmlns="http://www.interactive-instruments.de/etf/2.0" id='{$testTaskResultId}'>
<parent ref="{$testTaskId}"/>
<status>UNDEFINED</status>
<startTimestamp>{fn:current-dateTime()}</startTimestamp>
<duration>0</duration>
<resultedFrom ref='{$ets/@id}'/>
<testObject ref='{$testObjectId}'/>
<attachements>
{ 
let $text := 'System error in the Executable Test Suite. Please contact a system administrator. Error information:
[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
let $logentry := file:append($logFile, $text || file:line-separator(), map { 'method': 'text', 'media-type': 'text/plain' })
let $logout := prof:dump($text)
return
<Attachment xmlns="http://www.interactive-instruments.de/etf/2.0" type="LogFile">
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='{file:path-to-uri($logFile)}'/>
</Attachment>
}
{ if (file:exists($statFile)) then 
<Attachment xmlns="http://www.interactive-instruments.de/etf/2.0" type="StatisticalReport">
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='{file:path-to-uri($statFile)}'/>
</Attachment>
else ()}
{ if (file:exists($queryFile)) then 
<Attachment xmlns="http://www.interactive-instruments.de/etf/2.0" type="Query">
<label>XQuery executed against the dataset</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='{file:path-to-uri($queryFile)}'/>
</Attachment>
else ()}
</attachements>
<testModuleResults/>
</TestTaskResult> }
}</testTaskResults>
</DsResultSet>
};

(: Parameters as strings :)
declare variable $files_to_test external := ".*";
declare variable $tests_to_execute external := ".*";
declare variable $schema_file external;

(: ETF test driver parameters :)
declare variable $validationErrors external := "";
declare variable $testRunId external := uuid:randomUUID();
declare variable $testObjectId external := uuid:randomUUID();
declare variable $executableTestSuiteId external := 'EID545f9e49-009b-4114-9333-7ca26413b5d4';
declare variable $testTaskId external := uuid:randomUUID();
declare variable $testTaskResultId external := uuid:randomUUID();
declare variable $testObjectTypeIds external := "FIXME" ;
declare variable $translationTemplateBundleId external := "FIXME" ;
declare variable $projDir external := "/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire";
declare variable $tmpDir external := $projDir || file:dir-separator() || "tmp";
declare variable $outputFile external := $tmpDir || file:dir-separator() || $testTaskResultId || "-result.xml";
declare variable $logFile external :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-log.txt";
declare variable $statFile external :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-stat.xml";
declare variable $queryFile external :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-query.xq";
declare variable $statisticalReportTableType external := $projDir || file:dir-separator() || "StatisticalReportTableType-EID8bb8f162-1082-434f-bd06-23d6507634b8-esrtt.xml";
declare variable $translationTemplateBundle external := $projDir || file:dir-separator() || "TranslationTemplateBundle-EID70a263c0-0ad7-42f2-9d4d-0d8a4ca71b52-ettb.xml";
declare variable $dbBaseName external := "es";
declare variable $dbCount external := 1;
declare variable $dbDir external;
declare variable $etsno external := 2;

(: Project internals :)
declare variable $testQueryFile := "testquery.xq";

declare variable $etsFile := 
  if ($etsno = 1) then "data-encoding" || file:dir-separator() || "inspire-gml" || file:dir-separator() || "ets-inspire-gml-bsxets.xml"
  else if ($etsno = 2) then "data" || file:dir-separator() || "schemas" || file:dir-separator() || "ets-schemas-bsxets.xml"
  else if ($etsno = 3) then "data" || file:dir-separator() || "data-consistency" || file:dir-separator() || "ets-data-consistency-bsxets.xml"
  else if ($etsno = 4) then "data" || file:dir-separator() || "information-accessibility" || file:dir-separator() || "ets-information-accessibility-bsxets.xml"
  else if ($etsno = 5) then "data" || file:dir-separator() || "reference-systems" || file:dir-separator() || "ets-reference-systems-bsxets.xml"
  else if ($etsno = 6) then "data-hy" || file:dir-separator() || "hy-gml" || file:dir-separator() || "ets-hy-gml-bsxets.xml"
  else if ($etsno = 7) then "data-hy" || file:dir-separator() || "hy-n-as" || file:dir-separator() || "ets-hy-n-as-bsxets.xml"
  else if ($etsno = 8) then "data-hy" || file:dir-separator() || "hy-p-as" || file:dir-separator() || "ets-hy-p-as-bsxets.xml"
  else if ($etsno = 9) then "data-hy" || file:dir-separator() || "hy-dc" || file:dir-separator() || "ets-hy-dc-bsxets.xml"
  else if ($etsno = 10) then "data-hy" || file:dir-separator() || "hy-ia" || file:dir-separator() || "ets-hy-ia-bsxets.xml"
  else if ($etsno = 11) then "data-hy" || file:dir-separator() || "hy-rs" || file:dir-separator() || "ets-hy-rs-bsxets.xml"
  else if ($etsno = 12) then "data-ps" || file:dir-separator() || "ps-dc" || file:dir-separator() || "ets-ps-dc-bsxets.xml"
  else if ($etsno = 13) then "data-ps" || file:dir-separator() || "ps-gml" || file:dir-separator() || "ets-ps-gml-bsxets.xml"
  else if ($etsno = 14) then "data-ps" || file:dir-separator() || "ps-ia" || file:dir-separator() || "ets-ps-ia-bsxets.xml"
  else if ($etsno = 15) then "data-ps" || file:dir-separator() || "ps-rs" || file:dir-separator() || "ets-ps-rs-bsxets.xml"
  else if ($etsno = 16) then "data-ps" || file:dir-separator() || "ps-as" || file:dir-separator() || "ets-ps-as-bsxets.xml"
  else "data-encoding" || file:dir-separator() || "inspire-gml" || file:dir-separator() || "ets-inspire-gml-bsxets.xml";

declare variable $limitErrors := 1000;
declare variable $paramerror := xs:QName("etf:ParameterError");

(: Parameter checks :)

declare variable $count :=
try { xs:int($dbCount - 1)
} catch * {
error($paramerror,concat("System error: Internal parameter $dbCount must be an integer value. The value is '",data($dbCount),"'. Please contact an administrator.&#xa;"))
};

if ($count ge 0) then () else error($paramerror,concat("System error: Internal parameter $dbCount must be a positive integer value. The value is '",data($dbCount),"'. Please contact an administrator.&#xa;")),

try { let $x := matches('filename.gml',$files_to_test) 
return ()
} catch * {
error($paramerror,concat("Parameter $files_to_test must be a valid regular expression. You have set the value to '",data($files_to_test),"', which results in the following error during execution:&#xa; '",data($err:description),"'&#xa;"))
},

try { let $x := matches('module.case.assertion',$tests_to_execute) 
return ()
} catch * {
error($paramerror,concat("Parameter $tests_to_execute must be a valid regular expression. You have set the value to '",data($tests_to_execute),"', which results in the following error during execution:&#xa; '",data($err:description),"'&#xa;"))
},

if (file:exists($projDir)) then if (file:is-dir($projDir)) then () else error($paramerror,concat("System error: Internal parameter $projDir must be the path of an existing directory in the file system. The current value is '",data($projDir),"', which is a file, not a directory. Please contact an administrator.&#xa;")) else error($paramerror,concat("Internal parameter $projDir must be the path of an existing directory in the file system. The current value is '",data($projDir),"'. Please contact an administrator.&#xa;")),

if (file:exists($outputFile)) then if (file:is-file($outputFile)) then () else error($paramerror,concat("System error: Internal parameter $outputFile is an existing directory, not a file. The current value is '",data($outputFile),"'. Please contact an administrator.&#xa;")) else (),

for $i in 0 to $count return if (db:exists($dbBaseName || '-' || $i)) then () else error($paramerror,concat("System error: XML database '",concat($dbBaseName,"-",$i),"' was specified, but not found. Please contact an administrator.&#xa;")),

let $startlog := "let $startlog := local:log('Executing Test Suite: " || $etsFile || "')
"

let $etsFile := $projDir || file:dir-separator() || $etsFile
let $ets :=
try{
	doc($etsFile)/element()
} catch * {
	error($paramerror,concat("System error: The Executable Test Suite file '",data($etsFile),"' was not found or is invalid. Please contact an administrator.&#xa;"))
}

let $testQueryFile := concat($projDir, file:dir-separator(),$testQueryFile)
let $testQuery :=
try{
	file:read-text($testQueryFile, "UTF-8")
} catch * {
	error($paramerror,concat("System error: The system file '",data($testQueryFile),"' could not be opened.  Please contact an administrator.&#xa;"))
}

let $db := for $i in 0 to $count return db:open($dbBaseName || '-' || $i)[matches(db:path(.),$files_to_test)]

let $features := $db/wfs:FeatureCollection/wfs:member/* | $db/gml:FeatureCollection/gml:featureMember/* | $db/gml:FeatureCollection/gml:featureMembers/* | $db/base:SpatialDataSet/base:member/* | $db/base32:SpatialDataSet/base32:member/*

let $stattmpl := if (not($statisticalReportTableType) or not(fn:doc-available($statisticalReportTableType))) then () else doc($statisticalReportTableType)
let $stat := if (not($stattmpl)) then "let $logentry := local:log('Statistics table: " || string($statisticalReportTableType) || "')" else "
let $start := prof:current-ms()
let $entries := (" || string-join($stattmpl//etf:StatisticalReportTableType[1]/etf:rowExpressions/etf:expression,', ') || ")
let $statTable :=
<StatisticalReportTable xmlns='http://www.interactive-instruments.de/etf/2.0'>
<type ref='" || $stattmpl//etf:StatisticalReportTableType[1]/@id || "'/>
<entries>
{ for $entry in $entries return <entry xmlns='http://www.interactive-instruments.de/etf/2.0'>{$entry}</entry> }
</entries>
</StatisticalReportTable>
let $statWrite := file:write($statFile, $statTable, map { 'method': 'xml', 'media-type': 'application/xml' })
let $duration := prof:current-ms()-$start
let $logentry := local:log('Statistics table: ' || $duration || ' ms')

"

let $res := local:test($db, $features, $ets, $testQuery || $startlog || $stat)
let $dummy := file:write($outputFile,$res)
return ($res)
