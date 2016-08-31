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
declare namespace wms='http://www.opengis.net/wms'; 
declare namespace uuid='java.util.UUID';

import module namespace functx = 'http://www.functx.com';
import module namespace http = 'http://expath.org/ns/http-client';
import module namespace ggeo = 'de.interactive_instruments.etf.bsxm.GmlGeoX';

declare variable $limitErrors external := 1000;
declare variable $validationErrors external := ''; 
declare variable $db external; 
declare variable $records external; 
declare variable $testObjectId external;
declare variable $logFile external;
declare variable $statFile external;
declare variable $encoding external;
declare variable $schemaisoap external;
declare variable $schema19139 external;

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
   'TIMEOUT' = not accessible within timeout limits 
   HTTP status code = resource not available, the status code may point to the reason
   media type = accessible :)
declare function local:check-resource-uri($uri as xs:string, $timeoutInS as xs:integer) as xs:string
{
	if (starts-with($uri,'http://') or starts-with($uri,'https://')) then
		try { 
			let $response := http:send-request(<http:request method='get' timeout='{$timeoutInS}' status-only='true'/>, $uri) 
			return
			if ($response/@status=('200','204')) then
		  		$response/http:header[@name='Content-Type']/@value
			else
				$response/@status
		} catch * 
		{ 
			'TIMEOUT' 
		}
	else
		'notHTTP'
};

declare function local:check-resource-uris($uris as xs:string*, $timeoutInS as xs:integer) as map(*)
{
	map:merge( for $uri in $uris return map { $uri : local:check-resource-uri($uri, $timeoutInS) } )
};

(: Start logging :)
let $logentry := local:log('Testing ' || count($records) || ' records')

(: Statistics and assertions follow below :)
