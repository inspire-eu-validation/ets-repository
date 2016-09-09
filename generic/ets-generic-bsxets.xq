declare namespace gml31='http://www.opengis.net/gml';
declare namespace gml='http://www.opengis.net/gml/3.2';
declare namespace wfs11='http://www.opengis.net/wfs';
declare namespace wfs='http://www.opengis.net/wfs/2.0';
declare namespace xsi='http://www.w3.org/2001/XMLSchema-instance';
declare namespace xlink='http://www.w3.org/1999/xlink';
declare namespace etf='http://www.interactive-instruments.de/etf/2.0';
declare namespace uuid='java.util.UUID';

declare function local:test($db as document-node()*, $features as element()*, $ets as element()*, $testQuery as xs:string) as element()
{
let $query := $testQuery || 
(let $test-module-results :=
for $module in $ets//*[local-name()='TestModule']
let $moduleresultid := 'EID' || uuid:randomUUID()
let $test-case-results :=
for $case in $module//*[local-name()='TestCase']
  let $dep := if ($case/etf:dependencies) 
    then "let $dependencyResult := local:passed('" || $case/etf:dependencies/etf:testCase/@ref || "')" 
    else "let $dependencyResult := true()"
  let $caseresultid := 'EID' || uuid:randomUUID()
  let $test-step-results :=
    for $step in $case//*[local-name()='TestStep']
      let $stepresultid := 'EID' || uuid:randomUUID()
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
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='EID{uuid:randomUUID()}'>
    <parent ref='" || $stepresultid || "'/>
    <resultedFrom ref='" || $assertion/@id || "'/>
    <startTimestamp>" || fn:current-dateTime() || "</startTimestamp>
    <duration>0</duration>
    <status>" || $disabled || "</status>
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
let $duration := xs:integer(prof:current-ms()-$start)
let $endmessage := prof:void(local:end('" || $assertion/@id || "',$status))
let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='EID{uuid:randomUUID()}'>
    <parent ref='" || $stepresultid || "'/>
    { if (empty($messages)) then () else <messages>{$messages}</messages> }
    <resultedFrom ref='" || $assertion/@id || "'/>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <status>{$status}</status>
  </TestAssertionResult>
else
let $startmessage := prof:void(local:start('" || $assertion/@id || "')) 
let $timestampAssertion := fn:current-dateTime()
let $status := 'SKIPPED'
let $endmessage := prof:void(local:end('" || $assertion/@id || "',$status))
let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': ' || $status)
return
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='EID{uuid:randomUUID()}'>
    <parent ref='" || $stepresultid || "'/>
    <resultedFrom ref='" || $assertion/@id || "'/>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <status>{$status}</status>
  </TestAssertionResult>"

      return "
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('" || $step/@id || "')) 
let $assertionresults := (" || string-join( $assertion-results, ',' ) || ")
let $status := if ($dependencyResult) then local:status($assertionresults/etf:status) else 'SKIPPED'
let $endmessage := prof:void(local:end('" || $step/@id || "',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='" || $stepresultid || "'>
<parent ref='" || $caseresultid || "'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
<resultedFrom ref='" || $step/@id || "'/>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{xs:integer(sum($assertionresults/duration))}</duration>
<status>{$status}</status>
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
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='" || $caseresultid || "'>
<parent ref='" || $moduleresultid || "'/>
<testStepResults>{$teststepresults}</testStepResults>
<resultedFrom ref='" || $case/@id || "'/>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{xs:integer(sum($teststepresults/duration))}</duration>
<status>{$status}</status>
</TestCaseResult>"

return "
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start('" || $module/@id || "'))
let $testcaseresults := (" || string-join( $test-case-results, ',' ) || ")
let $status := local:status($testcaseresults/etf:status)
let $endmessage := prof:void(local:end('" || $module/@id || "',$status))
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='" || $moduleresultid || "'>
<parent ref='" || $testTaskResultId || "'/>
<testCaseResults>{$testcaseresults}</testCaseResults>
<resultedFrom ref='" || $module/@id || "'/>
<startTimestamp>{$timestampModule}</startTimestamp>
<duration>{xs:integer(sum($testcaseresults/duration))}</duration>
<status>{$status}</status>
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
<testObject ref='{$testObjectId}'/>
<testModuleResults>{$testmoduleresults}</testModuleResults>
<attachments>
{ if (file:exists('" || $logFile || "')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/2.0' type='LogFile' id='EID{uuid:randomUUID()}'>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='" || file:path-to-uri($logFile) || "'/>
</Attachment>
else ()}
{ if (file:exists('" || $statFile || "')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/2.0' type='StatisticalReport' id='EID{uuid:randomUUID()}'>
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='" || file:path-to-uri($statFile) || "'/>
</Attachment>
else ()}
{ if (file:exists('" || $queryFile || "')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/2.0' type='Query' id='EID{uuid:randomUUID()}'>
<label>XQuery executed against the dataset</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='" || file:path-to-uri($queryFile) || "'/>
</Attachment>
else ()}
</attachments>
<resultedFrom ref='" || $ets/@id || "'/>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{xs:integer(sum($testmoduleresults/duration))}</duration>
<status>{$status}</status>
</TestTaskResult>")

let $writeQuery := file:write($queryFile, $query, map { "method": "text", "media-type": "text/plain" })

return try {
  xquery:eval($query, map {'features': $features, 'idMap': map:merge($features ! map:entry(fn:string(gml:identifier), .)), 'validationErrors': $validationErrors, 'db': $db, 'files_to_test': $files_to_test, 'tests_to_execute': $tests_to_execute, 'limitErrors': $limitErrors, 'testObjectId': $testObjectId, 'logFile': $logFile, 'statFile': $statFile })
} catch * {
let $test-module-results :=
for $module in $ets//*[local-name()='TestModule']
let $moduleresultid := 'EID' || uuid:randomUUID()
let $test-case-results :=
for $case in $module//*[local-name()='TestCase']
let $caseresultid := 'EID' || uuid:randomUUID()
  let $test-step-results :=
    for $step in $case//*[local-name()='TestStep']
      let $stepresultid := 'EID' || uuid:randomUUID()
      let $assertion-results := 
        for $assertion in $step//*[local-name()='TestAssertion']
          return            
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='EID{uuid:randomUUID()}'>
    <parent ref='{$stepresultid}'/>
    <resultedFrom ref='{$assertion/@id}'/>
    <startTimestamp>{fn:current-dateTime()}</startTimestamp>
    <duration>0</duration>
    <status>SKIPPED</status>
  </TestAssertionResult>

      return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{$stepresultid}'>
<parent ref='{$caseresultid}'/>
<testAssertionResults>{$assertion-results}</testAssertionResults>
<resultedFrom ref='{$step/@id}'/>
<startTimestamp>{fn:current-dateTime()}</startTimestamp>
<duration>0</duration>
<status>SKIPPED</status>
</TestStepResult>

    return
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{$caseresultid}'>
<parent ref='{$moduleresultid}'/>
<testStepResults>{$test-step-results}</testStepResults>
<resultedFrom ref='{$case/@id}'/>
<startTimestamp>{fn:current-dateTime()}</startTimestamp>
<duration>0</duration>
<status>SKIPPED</status>
</TestCaseResult>

return 
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/2.0' id='{$moduleresultid}'>
<parent ref='{$testTaskResultId}'/>
<testCaseResults>{$test-case-results}</testCaseResults>
<resultedFrom ref='{$module/@id}'/>
<startTimestamp>{fn:current-dateTime()}</startTimestamp>
<duration>0</duration>
<status>SKIPPED</status>
</TestModuleResult>

let $text := 'System error in the Executable Test Suite. Please contact a system administrator. Error information:
[' || $err:code || '] ' || $err:description || ' 
' || $err:module || ' (' || $err:line-number || '/' || $err:column-number || ')'
let $logentry := file:append($logFile, $text || file:line-separator(), map { 'method': 'text', 'media-type': 'text/plain' })
let $logout := prof:dump($text)
return
<TestTaskResult xmlns="http://www.interactive-instruments.de/etf/2.0" id='{$testTaskResultId}'>
<testObject ref='{$testObjectId}'/>
<testModuleResults>{$test-module-results}</testModuleResults>
<attachments>
<Attachment xmlns="http://www.interactive-instruments.de/etf/2.0" type="LogFile" id="EID{uuid:randomUUID()}">
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='{file:path-to-uri($logFile)}'/>
</Attachment>
{ if (file:exists($statFile)) then 
<Attachment xmlns="http://www.interactive-instruments.de/etf/2.0" type="StatisticalReport" id="EID{uuid:randomUUID()}">
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='{file:path-to-uri($statFile)}'/>
</Attachment>
else ()}
{ if (file:exists($queryFile)) then 
<Attachment xmlns="http://www.interactive-instruments.de/etf/2.0" type="Query" id="EID{uuid:randomUUID()}">
<label>XQuery executed against the dataset</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='{file:path-to-uri($queryFile)}'/>
</Attachment>
else ()}
</attachments>
<resultedFrom ref='{$ets/@id}'/>
<startTimestamp>{fn:current-dateTime()}</startTimestamp>
<duration>0</duration>
<status>FAILED</status>
</TestTaskResult> }
};

(: Parameters as strings :)
declare variable $files_to_test external := ".*";
declare variable $tests_to_execute external := ".*";
declare variable $schema_file external;

(: ETF test driver parameters :)
(: For local testing in the BaseX GUI set $projDir, $etsFile and $dbBaseName to local DB without "-0" suffix :)
declare variable $projDir external := "/Users/portele/Documents/Dropbox/ETF/ets-repository/generic";
declare variable $dbBaseName external := "errors";
declare variable $etsFile external := $projDir || file:dir-separator() || "ets-template-bsxets.xml";
declare variable $validationErrors external := "";
declare variable $testObjectId external := 'EID' || uuid:randomUUID();
declare variable $testTaskResultId external := 'EID' || uuid:randomUUID();
declare variable $tmpDir external := $projDir || file:dir-separator() || "tmp";
declare variable $dbCount external := 1;

(: Project internals :)
declare variable $outputFile := $tmpDir || file:dir-separator() || $testTaskResultId || "-result.xml";
declare variable $logFile :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-log.txt";
declare variable $statFile :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-stat.xml";
declare variable $queryFile :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-query.xq";
declare variable $statisticalReportTableType := $projDir || file:dir-separator() || "include-metadata" || file:dir-separator() || "generic-esrtt.xml";
declare variable $translationTemplateBundle := $projDir || file:dir-separator() || "include-metadata" || file:dir-separator() || "generic-ettb.xml";
declare variable $testQueryFile := $projDir || file:dir-separator() || "generic-query-prolog.xq";
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

let $ets :=
try{
	doc($etsFile)/element()
} catch * {
	error($paramerror,concat("System error: The Executable Test Suite file '",data($etsFile),"' was not found or is invalid. Please contact an administrator.&#xa;"))
}

let $testQuery :=
try{
	file:read-text($testQueryFile, "UTF-8")
} catch * {
	error($paramerror,concat("System error: The system file '",data($testQueryFile),"' could not be opened.  Please contact an administrator.&#xa;"))
}

let $db := for $i in 0 to $count return db:open($dbBaseName || '-' || $i)[matches(db:path(.),$files_to_test)]

let $features := $db/wfs11:FeatureCollection/wfs11:member/* | $db/wfs:FeatureCollection/wfs:member/* | $db/gml:FeatureCollection/gml:featureMember/* | $db/gml:FeatureCollection/gml:featureMembers/* | $db/gml31:FeatureCollection/gml31:featureMember/* | $db/gml31:FeatureCollection/gml31:featureMembers/*

let $startlog := "let $startlog := local:log('Executing Test Suite: " || $etsFile || "')
"

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
let $duration := xs:integer(prof:current-ms()-$start)
let $logentry := local:log('Statistics table: ' || $duration || ' ms')

"

let $res := local:test($db, $features, $ets, $testQuery || $startlog || $stat)
let $dummy := file:write($outputFile,$res)
return ($res)