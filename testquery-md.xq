declare namespace csw='http://www.opengis.net/cat/csw/2.0.2';
declare namespace gsr='http://www.isotc211.org/2005/gsr';
declare namespace gss='http://www.isotc211.org/2005/gss';
declare namespace gts='http://www.isotc211.org/2005/gts';
declare namespace gmx='http://www.isotc211.org/2005/gmx'; 
declare namespace srv='http://www.isotc211.org/2005/srv';
declare namespace gco='http://www.isotc211.org/2005/gco';
declare namespace gmd='http://www.isotc211.org/2005/gmd';
declare namespace gml='http://www.opengis.net/gml/3.2';
declare namespace gml31='http://www.opengis.net/gml';
declare namespace xsi='http://www.w3.org/2001/XMLSchema-instance'; 
declare namespace xlink='http://www.w3.org/1999/xlink'; 
declare namespace etf='http://www.interactive-instruments.de/etf/2.0';
declare namespace atom='http://www.w3.org/2005/Atom';
declare namespace wfs='http://www.opengis.net/wfs/2.0'; 
declare namespace wcs='http://www.opengis.net/wcs/2.0'; 
declare namespace sos='http://www.opengis.net/sos/2.0'; 
declare namespace wms='http://www.opengis.net/wms'; 
declare namespace uuid='java.util.UUID';

import module namespace functx = 'http://www.functx.com';
import module namespace http = 'http://expath.org/ns/http-client';

declare variable $limitErrors external := 1000;
declare variable $validationErrors external := ''; 
declare variable $db external; 
declare variable $records external; 
declare variable $idMap external;
declare variable $testObjectId external;
declare variable $logFile external;
declare variable $statFile external;
declare variable $encoding external;
declare variable $schemapath external;

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
  (if ($count>=$limitErrors) then local:addMessage('TR.tooManyErrors', map { 'count': string($limitErrors) }) else (),
   if ($count>0) then local:addMessage($template, map { 'count': string($count) }) else ())
};

declare function local:status($stati as xs:string*) as xs:string 
{
  if ($stati='FAILED') then 'FAILED' else if ($stati='SKIPPED') then 'SKIPPED' else if ($stati='WARNING') then 'WARNING' else if ($stati='INFO') then 'INFO' else if ($stati='PASSED_MANUAL') then 'PASSED_MANUAL' else if ($stati='PASSED') then 'PASSED' else if ($stati='NOT_APPLICABLE') then 'NOT_APPLICABLE' else 'UNDEFINED'
};

(: 'notHTTP' = not a HTTP(S) URL
   'idNotFound' = a bare name Xpointer was provided, but not found
   'EXCEPTION ...' = an exception occurred
   HTTP status code = resource not available, the status code may point to the reason
   media type = accessible :)
declare function local:check-resource-uri($uri as xs:string, $timeoutInS as xs:integer, $redirect as xs:boolean) as xs:string
{
   if ($uri=('http://','https://')) then
		'notHTTP'
	else if (starts-with($uri,'http://') or starts-with($uri,'https://')) then
		try { 
		   let $loginfo := local:log('Checking URL: ''' || $uri || '''')
		   let $query := "import module namespace http = 'http://expath.org/ns/http-client'; declare variable $timeoutInS external; declare variable $redirect external; declare variable $uri external; http:send-request(<http:request method='get' timeout='{$timeoutInS}' status-only='true' follow-redirect='{$redirect}'/>, $uri)"
			let $response := xquery:eval($query, map{ 'timeoutInS' : $timeoutInS, 'uri': $uri, 'redirect': $redirect }, map{ 'timeout': $timeoutInS })
			return
			if ($response/@status=('200','204')) then
			   let $contenttype := $response/http:header[lower-case(@name)='content-type']/@value
		  		return
		  		if ($contenttype) then $contenttype else 'application/octet-stream'
			else if ($redirect and $response/@status=('301','302','303','307')) then
				local:check-resource-uri($response/http:header[@name='Location']/@value, $timeoutInS, $redirect)				
			else
				$response/@status
		} catch * 
		{ 
			let $logerror := local:log('Exception: ' || $err:description || ' URL: ' || $uri)
			return 'EXCEPTION ' || $err:description 
		}
	else if (starts-with($uri,'#')) then
		let $response := $records[@id=substring($uri,2)] 
		return
		if ($response) then
			'application/xml'
		else
			'idNotFound'
	else
		'notHTTP'
};

declare function local:check-http-uris($uris as xs:string*, $timeoutInS as xs:integer, $max as xs:integer, $errors as xs:integer, $map as map(*), $redirect as xs:boolean) as map(*)
{
  if (count($uris)=0) then $map
  else if ($errors ge $limitErrors) then map:merge(( $map, for $uri in $uris return map{ $uri: 'SKIPPED' } )) (: too many errors already identified, skipping the remaining URIs :)
  else
   let $result := local:check-resource-uri($uris[1], $timeoutInS, $redirect) 
   let $newmap := map:merge( ($map, map{ $uris[1] : $result }) )
   let $newerrors := if (matches($result,'(EXCEPTION|\d{3})')) then $errors+1 else $errors
   return local:check-http-uris($uris[position() gt 1], $timeoutInS, $max, $newerrors, $newmap, $redirect)
};

declare function local:check-resource-uris($uris as xs:string*, $timeoutInS as xs:integer, $redirect as xs:boolean) as map(*)
{
  let $remote := $uris[starts-with(.,'http://') or starts-with(.,'https://')]
  let $local := $uris[starts-with(.,'#')]
  return
  map:merge((
   local:check-http-uris($remote, $timeoutInS, count($remote), 0, map{}, $redirect),
   for $uri in $local[map:contains($idMap,substring(.,2))] return map { $uri : 'application/gml+xml' },  
   for $uri in $local[not(map:contains($idMap,substring(.,2)))] return map { $uri : 'idNotFound' },  
   for $uri in $uris[not(starts-with(.,'#') or starts-with(.,'http://') or starts-with(.,'https://'))] return map { $uri : 'notHTTP' }
  ))
};

declare function local:get-document($url as xs:string) as element()*
{
  let $finalURI := local:get-final-url($url, 30, true())
  let $loginfo := local:log('Final URL: ''' || $finalURI || '''')


  let $fixedURL := local:replaceCharacters($finalURI)
  (:~ let $decodedURI := web:decode-url($finalURI)
  let $loginfo2 := local:log('Decoded: ''' || $decodedURI || '''')

  let $encodedURI := fn:encode-for-uri($decodedURI)
  let $loginfo3 := local:log('Encoded: ''' || $encodedURI || '''') ~:)


  return fn:doc(fn:string($fixedURL))/element()
};

declare function local:replaceCharacters($uri as xs:string) as xs:string
{
  let $characters := ('\[', '\]', ' ')
  let $replacement := ('%5B', '%5D', '+')

  let $fixedURI := functx:replace-multi($uri, $characters, $replacement)
  
  return $fixedURI
};


declare function local:get-final-url($uri as xs:string, $timeoutInS as xs:integer, $redirect as xs:boolean) as xs:string
{
    let $loginfo := local:log('Checking URL: ''' || $uri || '''')
    let $query := "import module namespace http = 'http://expath.org/ns/http-client'; declare variable $timeoutInS external; declare variable $redirect external; declare variable $uri external; http:send-request(<http:request method='get' timeout='{$timeoutInS}' status-only='true' follow-redirect='{$redirect}'/>, $uri)"
    let $response := xquery:eval($query, map{ 'timeoutInS' : $timeoutInS, 'uri': $uri, 'redirect': $redirect }, map{ 'timeout': $timeoutInS })
    
    return
      if ($response/@status=('200','204')) then
        $uri
      else if ($redirect and $response/@status=('301','302','303','307')) then
        local:get-final-url($response/http:header[@name='Location']/@value, $timeoutInS, $redirect)				
      else
        $response/@status
};

(:
@throws: an error that explains why the code list could not be accessed
:)
declare function local:get-code-list-values($url as xs:string) as xs:string*
{
let $clname := functx:substring-after-last-match($url, 'http(s)?://inspire.ec.europa.eu/((metadata-)?codelist/)?')
let $clurl := $url || '/' || $clname || '.en.atom'
let $valid_clurl := try { local:check-resource-uri($clurl, 30, false()) } catch * { false() }
return
  if ($valid_clurl = ('notHTTP','idNotFound') or matches($valid_clurl,'\d{3}')) then
     error((),'Code list ' || $url || ' cannot be accessed.')
  else if (starts-with($valid_clurl, 'EXCEPTION')) then
    error((),'Access to code list ' || $url || ' failed or timed out.')
  else if (not(starts-with($valid_clurl,'text/xml') or starts-with($valid_clurl,'application/xml') or starts-with($valid_clurl,'application/atom+xml'))) then
    error((),'Unknown resource type encountered when accessing the atom representation of code list ' || $url || ' at URL ' || $clurl || '.')
  else
      try { 
        let $normalizedUrl := functx:substring-after-last-match($url, 'http(s)?:')
        let $clfeed := fn:doc($clurl)
        let $codeUris := $clfeed//atom:entry/atom:id/text()
        let $codes := for $codeUri in $codeUris
          let $normalizedCodeUri := functx:substring-after-last-match($codeUri, 'http(s)?:')
          return fn:substring-after($normalizedCodeUri, $normalizedUrl || '/')
        return
          $codes
        } catch * { 
          error((),'Code list ' || $url || ' cannot be accessed.')
      }
};

(:
@throws: an error that explains why the code list could not be accessed
:)
declare function local:get-codes-in-atom-format($url as xs:string, $langId as xs:string) as element()*
{
let $clname := if ($url = 'http://inspire.ec.europa.eu/theme') then 'theme' else functx:substring-after-last-match($url, 'http(s)?://inspire.ec.europa.eu/((metadata\-)?codelist/)?')
let $clurl := $url || '/' || $clname || '.' || $langId || '.atom'
let $valid_clurl := try { local:check-resource-uri($clurl, 30, false()) } catch * { false() }
return
  if ($valid_clurl = ('notHTTP','idNotFound') or matches($valid_clurl,'\d{3}')) then
     error((),'Code list ' || $url || ' cannot be accessed.')
  else if (starts-with($valid_clurl, 'EXCEPTION')) then
    error((),'Access to code list ' || $url || ' failed or timed out.')
  else if (not(starts-with($valid_clurl,'text/xml') or starts-with($valid_clurl,'application/xml') or starts-with($valid_clurl,'application/atom+xml'))) then
    error((),'Unknown resource type encountered when accessing the atom representation of code list ' || $url || ' at URL ' || $clurl || '.')
  else
      try { 
        let $root := fn:doc($clurl)/element()
        return
          $root//atom:entry
    } catch * { 
      error((),'Code list ' || $url || ' cannot be accessed.')
    }
};

(:
@throws: an error that explains why the invocation failed
:)
declare function local:get-code-titles($url as xs:string, $langIds as xs:string*) as xs:string*
{
  let $codesAsAtomEntries := (
    for $lang in $langIds
    return
      local:get-codes-in-atom-format($url,$lang)
  )
  return $codesAsAtomEntries/atom:title/text()
};

declare function local:is-valid-date-or-dateTime($dateString as xs:string?) as xs:boolean
{
   if (not($dateString)) then
   	false()
   else
	let $date := 
    try {
      let $tmp := xs:date($dateString)
      return
        (: NOTE: apparently, the value of the xs:date must be evaluated to be parsed by BaseX :)
       'DATE ' || $tmp
    } catch * {
      'INVALID'
    }
    	let $year := 
    try {
      let $tmp := xs:gYear($dateString)
      return
        (: NOTE: apparently, the value of the xs:date must be evaluated to be parsed by BaseX :)
       'DATE ' || $tmp
    } catch * {
      'INVALID'
    }
    	let $yearMonth := 
    try {
      let $tmp := xs:gYearMonth($dateString)
      return
        (: NOTE: apparently, the value of the xs:date must be evaluated to be parsed by BaseX :)
       'DATE ' || $tmp
    } catch * {
      'INVALID'
    }
  let $dateTime :=
    try {
      let $tmp := xs:dateTime($dateString)
      return 
       (: NOTE: apparently, the value of the xs:date must be evaluated to be parsed by BaseX :)
       'DATETIME ' || $tmp
    } catch * {
      'INVALID'
    }
  return
    if(starts-with($date,'DATE') or starts-with($year,'DATE') or starts-with($yearMonth,'DATE') or starts-with($dateTime,'DATETIME')) then
      true()
    else
      false()
};

(: Start logging :)
let $logentry := local:log('Testing ' || count($records) || ' records')

(: Statistics and assertions follow below :)
