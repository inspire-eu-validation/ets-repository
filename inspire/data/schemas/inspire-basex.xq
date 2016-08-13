declare namespace base3='http://inspire.ec.europa.eu/schemas/base/3.2';
declare namespace base='http://inspire.ec.europa.eu/schemas/base/3.3';
declare namespace gml='http://www.opengis.net/gml/3.2';
declare namespace wfs='http://www.opengis.net/wfs/2.0';
declare namespace xsi='http://www.w3.org/2001/XMLSchema-instance';
declare namespace xlink='http://www.w3.org/1999/xlink';
declare namespace etf='http://www.interactive-instruments.de/etf/1.0';

declare function local:disabled($label as xs:string?, $type as xs:string?) as xs:string?
{
  if (matches($label,$tests_to_execute)) then
   if ($type=('Automated','Automated/Manual')) then ()
   else if ($type='Disabled') then "skipped - currently disabled in this Executable Test Suite"
   else if ($type='Manual') then "manual test"
   else ()
  else "skipped - disabled by the user for this test run"
};

declare function local:execqueries($db as document-node()*, $features as element()*, $ets as element()*, $testQuery as xs:string) as element()*
{
let $query := $testQuery ||
(
let $test-module-results :=
for $module in $ets//*[local-name()='TestModule']
let $test-case-results :=
for $case in $module//*[local-name()='TestCase']
  let $test-step-results :=
    for $step in $case//*[local-name()='TestStep']
      let $assertion-results := 
        for $assertion in $step//*[local-name()='TestAssertion']
          return
if (local:disabled($assertion/etf:label, $assertion/etf:type)) then "
  let $startmessage := prof:void(local:start(" || $assertion/@id || ")) 
  let $endmessage := prof:void(local:end(" || $assertion/@id || ",'NOT_APPLICABLE'))
  let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': skipped')
  return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME." || $assertion/@id || "'>
    <parent ref='" || $step/@id || "'/>
    <resultStatus>NOT_APPLICABLE</resultStatus>
    <startTimestamp>" || fn:current-dateTime() || "</startTimestamp>
    <duration>0</duration>
    <resultedFrom ref='" || $assertion/@id || "'/>
    <messages/>
  </TestAssertionResult>" 
else "(
let $startmessage := prof:void(local:start(" || $assertion/@id || ")) 
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
let $endmessage := prof:void(local:end(" || $assertion/@id || ",$status))
let $logentry := local:log('Test Assertion ''" || $assertion/etf:label || "'': ' || $duration || ' ms')
return 
  <TestAssertionResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME." || $assertion/@id || "'>
    <parent ref='" || $step/@id || "'/>
    <resultStatus>{$status}</resultStatus>
    <startTimestamp>{$timestampAssertion}</startTimestamp>
    <duration>{$duration}</duration>
    <resultedFrom ref='" || $assertion/@id || "'/>
    <messages>{$messages}</messages>
  </TestAssertionResult>)"

      return "
let $timestampStep := fn:current-dateTime()
let $startmessage := prof:void(local:start(" || $step/@id || ")) 
let $logentry := local:log('Test Step ''" || $step/etf:label || "'' started')
let $assertionresults := (" || string-join( $assertion-results, ',' ) || ")
let $status := local:status($assertionresults/etf:resultStatus)
let $endmessage := prof:void(local:end(" || $step/@id || ",$status))
let $logentry := local:log('Test Step ''" || $step/etf:label || "'' finished')
return 
<TestStepResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME." || $step/@id || "'>
<parent ref='" || $case/@id || "'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampStep}</startTimestamp>
<duration>{sum($assertionresults/duration)}</duration>
<resultedFrom ref='" || $step/@id || "'/>
<testAssertionResults>{$assertionresults}</testAssertionResults>
</TestStepResult>"

   return "
let $timestampCase := fn:current-dateTime()
let $startmessage := prof:void(local:start(" || $case/@id || "))
let $logentry := local:log('Test Case ''" || $case/etf:label || "'' started')
let $teststepresults := (" || string-join( $test-step-results, ',' ) || ")
let $status := local:status($teststepresults/etf:resultStatus)
let $endmessage := prof:void(local:end(" || $case/@id || ",$status))
let $logentry := local:log('Test Case ''" || $case/etf:label || "'' finished')
return 
<TestCaseResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME." || $case/@id || "'>
<parent ref='" || $module/@id || "'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampCase}</startTimestamp>
<duration>{sum($teststepresults/duration)}</duration>
<resultedFrom ref='" || $case/@id || "'/>
<testStepResults>{$teststepresults}</testStepResults>
</TestCaseResult>"

return "
let $timestampModule := fn:current-dateTime()
let $startmessage := prof:void(local:start(" || $module/@id || "))
let $logentry := local:log('Test Module ''" || $module/etf:label || "'' started')
let $testcaseresults := (" || string-join( $test-case-results, ',' ) || ")
let $status := local:status($testcaseresults/etf:resultStatus)
let $endmessage := prof:void(local:end(" || $module/@id || ",$status))
let $logentry := local:log('Test Module ''" || $module/etf:label || "'' finished')
return
<TestModuleResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='FIXME." || $module/@id || "'>
<parent ref='" || $ets/@id || "'/>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampModule}</startTimestamp>
<duration>{sum($testcaseresults/duration)}</duration>
<resultedFrom ref='" || $module/@id || "'/>
<testCaseResults>{$testcaseresults}</testCaseResults>
</TestModuleResult>"

return "
let $timestampSuite := fn:current-dateTime()
let $startmessage := prof:void(local:start(" || $ets/@id || "))
let $logentry := local:log('Test Suite ''" || $ets/etf:label || "'' started')
let $testmoduleresults := (" || string-join( $test-module-results, ',' ) || ")
let $status := local:status($testmoduleresults/etf:resultStatus)
let $endmessage := prof:void(local:end(" || $ets/@id || ",$status))
let $logentry := local:log('Test Suite ''" || $ets/etf:label || "'' finished')
return
<TestTaskResult xmlns='http://www.interactive-instruments.de/etf/1.0' id='" || $testTaskResultId || "'>
<resultStatus>{$status}</resultStatus>
<startTimestamp>{$timestampSuite}</startTimestamp>
<duration>{sum($testmoduleresults/duration)}</duration>
<resultedFrom ref='" || $ets/@id || "'/>
<attachements>
<Attachment>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='TODO'/>
</Attachment>
</attachements>
<testModuleResults>{$testmoduleresults}</testModuleResults>
</TestTaskResult>")

(: TODO remove after testing :)
let $dummy := file:write($projDir || file:dir-separator() || 'dump.xq', $query, map { "method": "text", "media-type": "text/plain" })

return try {
  xquery:eval($query, map {'features' := $features, 'idMap' := map:new($features ! map:entry(fn:string(gml:identifier), .)), 'validationErrors' := $validationErrors, 'db' := $db, 'files_to_test' := $files_to_test, 'tests_to_execute' := $tests_to_execute, 'limitErrors' := $limitErrors, 'limitMessages' := $limitMessages, 'testObjectId' := $testObjectId, 'executableTestSuiteId' := $executableTestSuiteId, 'testTaskResultId' := $testTaskResultId, 'testObjectTypeIds' := $testObjectTypeIds, 'translationTemplateBundleId' := $translationTemplateBundleId})
} catch * {      
<TestTaskResult xmlns="http://www.interactive-instruments.de/etf/1.0" id='{$ets/@id}'>
<resultStatus>UNDEFINED</resultStatus>
<startTimestamp>{fn:current-dateTime()}</startTimestamp>
<duration>0</duration>
<resultedFrom ref='{$ets/@id}'/>
<attachements>
<Attachment>
<label>Log file</label>
<encoding>UTF-8</encoding>
<mimeType>text/plain</mimeType>
<referencedData href='TODO'/>
</Attachment>
</attachements>
<testModuleResults/>
</TestTaskResult>
}
};

declare function local:test($db as document-node()*, $features as element()*, $ets as element()*, $testQuery as xs:string) as element()
{
<DsResultSet xmlns="http://www.interactive-instruments.de/etf/1.0">
<executableTestSuites>{$ets}</executableTestSuites>
<testTaskResults>{local:execqueries($db, $features, $ets, $testQuery)}</testTaskResults>
</DsResultSet>
};

(: Parameters as strings :)
declare variable $files_to_test external := ".*";
declare variable $tests_to_execute external := ".*";
declare variable $maximum_number_of_error_messages_per_test external := "50";
declare variable $schema_file external := "schema.xsd";

(: ETF test driver parameters :)
declare variable $projDir external := "/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data/inspire-gml";
declare variable $outputFile external := "/Users/portele/Documents/Dropbox/ETF/ets-repository/inspire/data/inspire-gml/result.xml";
declare variable $dbBaseName external := "hy-n";
declare variable $dbCount external := 1;
declare variable $dbDir external;
declare variable $validationErrors external := "";
declare variable $testObjectId external := "EID00000000-0000-0000-0000-0000000000001";
declare variable $executableTestSuiteId external := "EID00000000-0000-0000-0000-0000000000002";
declare variable $testTaskResultId external := "EID00000000-0000-0000-0000-0000000000003";
declare variable $testObjectTypeIds external := ("EID00000000-0000-0000-0000-000000000000A", "EID00000000-0000-0000-0000-000000000000B");
declare variable $translationTemplateBundleId external := "EID00000000-0000-0000-0000-0000000000005";

(: Project internals :)
declare variable $assertionsFile := "ets-inspire-gml.xml";
declare variable $testQueryFile := "testquery.xq";

declare variable $limitMessages := xs:int( $maximum_number_of_error_messages_per_test );
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

try { let $x := xs:int($maximum_number_of_error_messages_per_test)
return ()
} catch * {
error($paramerror,concat("Parameter $maximum_number_of_error_messages_per_test must be an integer value. You have set the value to '",data($maximum_number_of_error_messages_per_test),"'&#xa;"))
},

if (file:exists($projDir)) then if (file:is-dir($projDir)) then () else error($paramerror,concat("System error: Internal parameter $projDir must be the path of an existing directory in the file system. The current value is '",data($projDir),"', which is a file, not a directory. Please contact an administrator.&#xa;")) else error($paramerror,concat("Internal parameter $projDir must be the path of an existing directory in the file system. The current value is '",data($projDir),"'. Please contact an administrator.&#xa;")),

if (file:exists($outputFile)) then if (file:is-file($outputFile)) then () else error($paramerror,concat("System error: Internal parameter $outputFile is an existing directory, not a file. The current value is '",data($outputFile),"'. Please contact an administrator.&#xa;")) else (),

for $i in 0 to $count return if (db:exists($dbBaseName || '-' || $i)) then () else error($paramerror,concat("System error: XML database '",concat($dbBaseName,"-",$i),"' was specified, but not found. Please contact an administrator.&#xa;")),

let $db := for $i in 0 to $count return db:open($dbBaseName || '-' || $i)[matches(db:path(.),$files_to_test)]

let $features := $db/wfs:FeatureCollection/wfs:member/* | $db/gml:FeatureCollection/gml:featureMember/* | $db/gml:FeatureCollection/gml:featureMembers/* | $db/base:SpatialDataSet/base:member/* | $db/base3:SpatialDataSet/base3:member/*

let $assertionsFile := concat($projDir, file:dir-separator(),$assertionsFile)
let $ets :=
try{
	doc($assertionsFile)/element()
} catch * {
	error($paramerror,concat("Systemfehler: Die Datei mit den Assertions '",data($assertionsFile),"' wurde nicht gefunden oder sie ist nicht valide. Bitte kontaktieren Sie den Administrator.&#xa;"))
}
let $testQueryFile := concat($projDir, file:dir-separator(),$testQueryFile)
let $testQuery :=
try{
	file:read-text($testQueryFile, "UTF-8")
} catch * {
	error($paramerror,concat("Systemfehler: Die Testquery-Datei '",data($assertionsFile),"' konnte nicht geöffnet. Bitte kontaktieren Sie den Administrator.&#xa;"))
}

let $res := local:test($db, $features, $ets, $testQuery)
let $dummy := file:write($outputFile,$res)
return ($res)
