/* driver.p
 *
 * run in the background and keep PASOE busy doing random "stuff"
 *
 * bpro -p driver.p -rand 2 -param 001
 *
 */

{pasoe_cnx.i}

/* usually found in lib/protop.i and declared as "new global shared"...
 */

define variable pt_tmpdir    as character   no-undo initial "./tmp".
define variable pt_logdir    as character   no-undo initial "./log".

define variable logFileName  as character   no-undo.
define variable flgFileName  as character   no-undo.
define variable dbgFileName  as character   no-undo.

define variable procName     as character   no-undo initial "getOrders".
define variable transport    as character   no-undo.
define variable XID          as character   no-undo initial "000".			/* "thread" or instance number				*/

define variable rr           as integer     no-undo.					/* a random number, used to select the transport	*/
define variable nn           as integer     no-undo.					/* the number of orders for the selected customer	*/
define variable custNum      as integer     no-undo.					/* a randomly selected customer number			*/

define variable startTime    as datetime    no-undo.					/* when did we start the call to PASOE?			*/
define variable runTime      as integer     no-undo.					/* how long did it take (milliseconds)			*/

/* for APSV server connection
 */

define variable apsvSrvr     as handle      no-undo.

/* used by REST, SOAP, and WEBH calls
 */

define variable result       as longchar    no-undo.

define variable respHeaders  as character   no-undo.

/* specific to SOAP requests
 */

define variable soapHeaders  as character   no-undo.
define variable soapRequest  as character   no-undo.

define variable soapTemplate as character   no-undo.

soapHeaders = substitute( "&1&2&3", soapHeaders, "Content-Type: text/xml;charset=UTF-8", chr(13) + chr(10)).
soapHeaders = substitute( "&1&2&3", soapHeaders, "SOAPAction: ''", chr(13) + chr(10)).

soapTemplate =
  '<?xml version="1.0" encoding="utf-8"?>' +
  '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
    '<soap:Body>' +
      '<orders xmlns="urn:tempuri-org:OrderMaint">' +
        '<cnum>&1</cnum>' +								/* &1 is for SUBSTITUTE() to plugin the custNum		*/
      '</orders>' +
    '</soap:Body>' +
  '</soap:Envelope>'
.


function logIt returns logical ( input tt as character, cn as integer, nn as integer, rt as integer, respHeaders as character, result as longchar ):

  define variable xstatus as character no-undo.

  xstatus = trim( entry( 1, respHeaders, "~n" )).

  if xstatus matches "HTTP*200" then
    message now substitute( "[&1] custNum: &2 has &3 orders. runTime = &4", tt, cn, nn, rt ).
   else
    message now substitute( "[&1] call failed with status: &2 runTime = &4~n&3", tt, xstatus, substring( result, 1, 4096 ), rt ).

  return true.

end.


/* we probably ought to ensure that the parameter fits the expected values...
 */

if session:parameter <> ? and session:parameter <> "" then
  XID = session:parameter.

/* ensure that the tmp and log directories exist
 */

file-info:file-name = trim( pt_tmpdir, '"' ).						/* make certain that we have a temp directory!		*/
if file-info:full-pathname = ? then
  os-command silent value( "mkdir " + pt_tmpdir ).

file-info:file-name = trim( pt_logdir, '"' ).						/* make certain that we have a log directory!		*/
if file-info:full-pathname = ? then
  os-command silent value( "mkdir " + pt_logdir ).

assign
  logFileName = substitute( "&1/&2.&3.&4", pt_logdir, procName, XID, "log" )
  flgFileName = substitute( "&1/&2.&3.&4", pt_tmpdir, procName, XID, "flg" )
  dbgFileName = substitute( "&1/&2.&3.&4", pt_tmpdir, procName, XID, "dbg" )
.

/* load the ProTop socket library
 */

run ssg/sausage02.p persistent.

/* this is a (very) abbreviated version of the lib/protoplib.p:mkFlag() function
 */

file-info:file-name = flgFileName.
if file-info:full-pathname <> ? then
  do:
    message now "Flag file:" flgFileName "exists!".
    message now "It would appear that there is already a" procName "running and that " file-info:full-pathname " is it's flag file.".
    message now "Cowardly refusing to start another.".
    quit.
  end.
 else
  do:
    output to value( flgFileName ) unbuffered append.
    message now substitute( "Starting &1 background daemon", procName ).
    message now substitute( "log = &1  flag = &2  dbgLvlName= &3", logFileName, flgFileName, dbgFileName ).
    output close.
  end.

/* ok, the flag is set so open the log file!
 */

output to value( logFileName ) unbuffered append.					/* if a 2nd copy starts, try to make it obvious		*/

message now substitute( "Starting &1 background daemon", procName ).
message now substitute( "log = &1  flag = &2  dbgLvlName= &3", logFileName, flgFileName, dbgFileName ).


/* just do this once, why create it and close it with every call?
 */

create server apsvSrvr.
apsvSrvr:connect( substitute( "-URL http://&1:&2/apsv", pasoe_host, pasoe_port )).

/* the processing loop
 */
  
do while true:

  file-info:file-name = flgFileName.                                    		/* are we being politely asked to stop?				*/
  if file-info:full-pathname = ? then                                   		/* (if the flag disappears we are being asked to stop)		*/
    do:
      message now flgFileName "has disappeared.".
      message now substitute( "Gracefully shutting down &1.", procName ).
      leave.
    end.

  assign
    nn        = 0
    rr        = random( 1, 100 )
    custNum   = random( 1, 100 )
    startTime = now
    result = "".
  .

  fix-codepage( result ) = 'utf-8'.

  /* randomly call the different PASOE transports
   */

  if       rr >  0 and rr <=   5 then transport = "SOAP".				/* 5%	SOAP		*/
   else if rr >  5 and rr <=  20 then transport = "REST".				/* 15%	REST		*/
   else if rr > 20 and rr <=  50 then transport = "WEBH".				/* 30%	WEBH		*/
   else if rr > 50 and rr <= 100 then transport = "APSV".				/* 50%	APSV		*/

  if transport = "SOAP" then								/* ...<orderCount>1</orderCount>...				*/
    do:
      soapRequest = substitute( soapTemplate, custNum ).
      run postURL( pasoe_host, pasoe_port, "/soap", "", "", soapHeaders, soapRequest, "", output result, output respHeaders ).
      nn = integer( entry( 1, substring( result, r-index( result, "<orderCount>" ) + 12 ), '<' )) no-error.
    end.
   else if transport = "REST" then							/* {"response":{"orderCount":2}}				 */
    do:
      run getURL( pasoe_host, pasoe_port, substitute( "/rest/restProxyService/orders?customer=&1", custNum ), "", "", "", "", "", output result, output respHeaders ).
      nn = integer( trim( substring( result, r-index( result, ":" ) + 1 ), '~}' )) no-error.
    end.
   else if transport = "WEBH" then							/* {"CustomerNum":69,"Orders":2}				 */
    do:
      run getURL( pasoe_host, pasoe_port, substitute( "/web/Orders/&1", custNum ), "", "", "", "", "", output result, output respHeaders ).
      nn = integer( trim( substring( result, r-index( result, ":" ) + 1 ), '~}' )) no-error.
    end.
   else if transport = "APSV" then
    do:
      run orders.p on apsvSrvr ( custNum, output nn ).
      respHeaders = "HTTP 200".								/* kludge-o-matic...						*/
    end.

  runTime = interval( now, startTime, "milliseconds" ).
  logIt ( transport, custNum, nn, runTime, respHeaders, result ).

  pause ( random( 1, 10 ) / 10.0 ) no-message.

end.


/* clean up
 */

apsvSrvr:disconnect().
delete object apsvSrvr.

/* just in case we somehow got here without someone deleting the flg file
 */
            
file-info:file-name = flgFileName.
if file-info:full-pathname <> ? then
  os-delete value( file-info:full-pathname ).
  
message now "==Quit==".
output close.

quit.


/* *really* I mean it this time!
 */

finally:
  apsvSrvr:disconnect().
  delete object apsvSrvr.
end.
