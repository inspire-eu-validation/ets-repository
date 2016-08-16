declare namespace base3='http://inspire.ec.europa.eu/schemas/base/3.2';
declare namespace base='http://inspire.ec.europa.eu/schemas/base/3.3';
declare namespace gml='http://www.opengis.net/gml/3.2';
declare namespace wfs='http://www.opengis.net/wfs/2.0';
declare namespace xsi='http://www.w3.org/2001/XMLSchema-instance';
declare namespace xlink='http://www.w3.org/1999/xlink';
declare namespace etf='http://www.interactive-instruments.de/etf/1.0';
declare namespace uuid='java.util.UUID';

declare function local:test($db as document-node()*, $features as element()*, $ets as element()*, $testQuery as xs:string) as element()
{
<DsResultSet xmlns="http://www.interactive-instruments.de/etf/1.0">
<executableTestSuites>{$ets}</executableTestSuites>
<testTaskResults>{let $query := $testQuery || (let $test-module-results :=
for $module in $ets//*[local-name()='TestModule']
let $test-case-results :=
for $case in $module//*[local-name()='TestCase']
  let $dep := if ($case/etf:dependency) 
    then "let $dependencyResult := local:passed('" || $case/etf:dependency/etf:dependsOn/@ref || "')" 
    else "let $dependencyResult := true()"
  let $test-step-results :=
    for $step in $case//*[local-name()='TestStep']
      let $assertion-results := 
        for $assertion in $step//*[local-name()='TestAssertion']
          let $type := $assertion/etf:type
          let $disabled := if (not(matches($assertion/etf:label,$tests_to_execute)) or $type/@ref='EID92f22a19-2ec2-43f0-8971-c2da3eaafcd2' (:disabled :)) then 'NOT_APPLICABLE' else if ($type/@ref='EIDb48eeaa3-6a74-414a-879c-1dc708017e11' (: manual :)) then 'PASSED_MANUAL' else ()
          return
if ($disabled) then "
  let $startmessage := prof:void(local:start('" || $assertion/@id || "')) 
  let $endmessage := prof:void(local:end('" || $assertion/@id || "','" || $disabled || "'))
  let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': " || $disabled || "')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='" || $step/@id || "'/>
    <resultStatus>" || $disabled || "</resultStatus>
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
  return ('FAILED', local:addMessage('systemError', map { '$text': $text }))
}
let $status_returned := $result[1]
let $messages := $result[position()>1]
let $status := if ($status_returned = ('PASSED','FAILED','WARNING','PASSED_MANUAL','INFO','SKIPPED')) then $status_returned else 'UNDEFINED'
let $duration := prof:current-ms()-$start
let $endmessage := prof:void(local:end('" || $assertion/@id || "',$status))
let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': ' || $status || ' - ' ||$duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='" || $step/@id || "'/>
    <resultStatus>{$status}</resultStatus>
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
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
    <parent ref='" || $step/@id || "'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='" || $assertion/@id || "'/>
    <messages/>
  </TestAssertionResult>"

      return "
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start('" || $step/@id || "')) 
let $assertionresults := (" || string-join( $assertion-results, ',' ) || ")
let $status := if ($dependencyResult) then local:status($assertionresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('" || $step/@id || "',$status))
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='" || $case/@id || "'/>
<resultStatus>{$status}</resultStatus>
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
let $status := if ($dependencyResult) then local:status($teststepresults/etf:resultStatus) else 'SKIPPED'
let $endmessage := prof:void(local:end('" || $case/@id || "',$status))
let $logentry := local:log('Test Case ''" || $case/etf:label || "'' finished: ' || $status)
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='" || $module/@id || "'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='" || $case/@id || "'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>"

return "
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start('" || $module/@id || "'))
let $testcaseresults := (" || string-join( $test-case-results, ',' ) || ")
let $status := local:status($testcaseresults/etf:resultStatus)
let $endmessage := prof:void(local:end('" || $module/@id || "',$status))
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='{uuid:randomUUID()}'>
<parent ref='" || $ets/@id || "'/>
<resultStatus>{$status}</resultStatus>
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
let $status := local:status($testmoduleresults/etf:resultStatus)
let $endmessage := prof:void(local:end('" || $ets/@id || "',$status))
let $logentry := local:log('Test Suite ''" || $ets/etf:label || "'' finished: ' || $status)
return
<TestTaskResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='" || $testTaskResultId || "'>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{sum($testmoduleresults/duration)}</duration>
<resultedFrom ref='" || $ets/@id || "'/>
<testObject ref='{$testObjectId}'/>
<attachements>
{ if (file:exists('" || $logFile || "')) then 
<Attachment>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='" || file:path-to-uri($logFile) || "'/>
</Attachment>
else ()}
{ if (file:exists('" || $statFile || "')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='" || file:path-to-uri($statFile) || "'/>
</Attachment>
else ()}
{ if (file:exists('" || $queryFile || "')) then 
<Attachment xmlns='http://www.interactive-instruments.de/etf/1.0'>
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
  xquery:eval($query, map {'features' := $features, 'idMap' := map:new($features ! map:entry(fn:string(gml:identifier), .)), 'validationErrors' := $validationErrors, 'db' := $db, 'files_to_test' := $files_to_test, 'tests_to_execute' := $tests_to_execute, 'limitErrors' := $limitErrors, 'limitMessages' := $limitMessages, 'testObjectId' := $testObjectId, 'executableTestSuiteId' := $executableTestSuiteId, 'testTaskResultId' := $testTaskResultId, 'testObjectTypeIds' := $testObjectTypeIds, 'translationTemplateBundleId' := $translationTemplateBundleId, 'logFile' := $logFile, 'statFile' := $statFile })
} catch * {      
<TestTaskResult xmlns="http://www.interactive-instruments.de/etf/1.0" id='{$testTaskResultId}'>
<resultStatus>UNDEFINED</resultStatus>
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
<Attachment xmlns="http://www.interactive-instruments.de/etf/1.0">
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='{file:path-to-uri($logFile)}'/>
</Attachment>
}
{ if (file:exists($statFile)) then 
<Attachment xmlns="http://www.interactive-instruments.de/etf/1.0">
<label>Feature statistics</label>
<encoding>UTF-8</encoding>
<mimeType>application/xml</mimeType>
<referencedData href='{file:path-to-uri($statFile)}'/>
</Attachment>
else ()}
{ if (file:exists($queryFile)) then 
<Attachment xmlns="http://www.interactive-instruments.de/etf/1.0">
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
declare variable $maximum_number_of_error_messages_per_test external := "50";
declare variable $schema_file external;

(: ETF test driver parameters :)
declare variable $validationErrors external := "";
declare variable $testObjectId external := uuid:randomUUID();
declare variable $executableTestSuiteId external := 'EID545f9e49-009b-4114-9333-7ca26413b5d4';
declare variable $testTaskResultId external := uuid:randomUUID();
declare variable $testObjectTypeIds external := "FIXME" ;
declare variable $translationTemplateBundleId external := "FIXME" ;
declare variable $projDir external := "/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire";
declare variable $tmpDir external := $projDir || file:dir-separator() || "tmp";
declare variable $outputFile external := $tmpDir || file:dir-separator() || $testTaskResultId || "-result.xml";
declare variable $logFile external :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-log.txt";
declare variable $statFile external :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-stat.xml";
declare variable $queryFile external :=  $tmpDir || file:dir-separator() || $testTaskResultId || "-query.xq";
declare variable $dbBaseName external := "hy-test";
declare variable $dbCount external := 1;
declare variable $dbDir external;

(: Project internals :)
declare variable $testQueryFile := "testquery.xq";

declare variable $etsno := 2;
declare variable $etsFile := 
  if ($etsno = 1) then "data-encoding" || file:dir-separator() || "inspire-gml" || file:dir-separator() || "ets-inspire-gml.xml"
  else if ($etsno = 2) then "data" || file:dir-separator() || "schemas" || file:dir-separator() || "ets-schemas.xml"
  else if ($etsno = 3) then "data" || file:dir-separator() || "data-consistency" || file:dir-separator() || "ets-data-consistency.xml"
  else if ($etsno = 4) then "data" || file:dir-separator() || "information-accessibility" || file:dir-separator() || "ets-information-accessibility.xml"
  else if ($etsno = 5) then "data" || file:dir-separator() || "reference-systems" || file:dir-separator() || "ets-reference-systems.xml"
  else if ($etsno = 6) then "data-hy" || file:dir-separator() || "hy-gml" || file:dir-separator() || "ets-hy-gml.xml"
  else if ($etsno = 7) then "data-hy" || file:dir-separator() || "hy-n-as" || file:dir-separator() || "ets-hy-n-as.xml"
  else if ($etsno = 8) then "data-hy" || file:dir-separator() || "hy-p-as" || file:dir-separator() || "ets-hy-p-as.xml"
  else if ($etsno = 9) then "data-hy" || file:dir-separator() || "hy-dc" || file:dir-separator() || "ets-hy-dc.xml"
  else if ($etsno = 10) then "data-hy" || file:dir-separator() || "hy-ia" || file:dir-separator() || "ets-hy-ia.xml"
  else if ($etsno = 11) then "data-hy" || file:dir-separator() || "hy-rs" || file:dir-separator() || "ets-hy-rs.xml"
  else "data-encoding" || file:dir-separator() || "inspire-gml" || file:dir-separator() || "ets-inspire-gml.xml";

declare variable $limitMessages := xs:int( $maximum_number_of_error_messages_per_test );
declare variable $limitErrors := 100;
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

try { let $x := xs:int($maximum_number_of_error_messages_per_test)
return ()
} catch * {
error($paramerror,concat("Parameter $maximum_number_of_error_messages_per_test must be an integer value. You have set the value to '",data($maximum_number_of_error_messages_per_test),"'&#xa;"))
},

if (file:exists($projDir)) then if (file:is-dir($projDir)) then () else error($paramerror,concat("System error: Internal parameter $projDir must be the path of an existing directory in the file system. The current value is '",data($projDir),"', which is a file, not a directory. Please contact an administrator.&#xa;")) else error($paramerror,concat("Internal parameter $projDir must be the path of an existing directory in the file system. The current value is '",data($projDir),"'. Please contact an administrator.&#xa;")),

if (file:exists($outputFile)) then if (file:is-file($outputFile)) then () else error($paramerror,concat("System error: Internal parameter $outputFile is an existing directory, not a file. The current value is '",data($outputFile),"'. Please contact an administrator.&#xa;")) else (),

for $i in 0 to $count return if (db:exists($dbBaseName || '-' || $i)) then () else error($paramerror,concat("System error: XML database '",concat($dbBaseName,"-",$i),"' was specified, but not found. Please contact an administrator.&#xa;")),

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

let $features := $db/wfs:FeatureCollection/wfs:member/* | $db/gml:FeatureCollection/gml:featureMember/* | $db/gml:FeatureCollection/gml:featureMembers/* | $db/base:SpatialDataSet/base:member/* | $db/base3:SpatialDataSet/base3:member/*

let $staturi := $ets/etf:statisticalReportTableType
let $stattmpl := if (not($staturi)) then () else doc($staturi)
let $stat := if (not($stattmpl)) then "let $logentry := local:log('Statistics table: " || string($staturi) || "')" else "
let $start := prof:current-ms()
let $entries := (" || string-join($stattmpl//etf:StatisticalReportTableType[1]/etf:rowExpressions/etf:expression,', ') || ")
let $statTable :=
<StatisticalReportTable xmlns='http://www.interactive-instruments.de/etf/1.0'>
<type ref='" || $stattmpl//etf:StatisticalReportTableType[1]/@id || "'/>
<entries>
{ for $entry in $entries return <entry xmlns='http://www.interactive-instruments.de/etf/1.0'>{$entry}</entry> }
</entries>
</StatisticalReportTable>
let $statWrite := file:write($statFile, $statTable, map { 'method': 'xml', 'media-type': 'application/xml' })
let $duration := prof:current-ms()-$start
let $logentry := local:log('Statistics table: ' || $duration || ' ms')

"

let $res := local:test($db, $features, $ets, $testQuery || $stat)
let $dummy := file:write($outputFile,$res)
return ($res)
