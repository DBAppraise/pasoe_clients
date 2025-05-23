/* apsv_gsv.p
 *
 * pro -p ./apsv_gsv.p
 *
 */

{pasoe_cnx.i}

define variable h as handle no-undo.
define variable n as integer no-undo.

create server h.
h:connect( substitute( "-URL http://&1:&2/apsv", pasoe_host, pasoe_port )).

run gsv.p on h ( output n ).

display n.
pause.

quit.

finally:
  h:disconnect().
  delete object h.
end.
