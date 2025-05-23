/* apsv_orders.p
 *
 * pro -p ./apsv_orders.p -rand 2
 *
 */

{pasoe_cnx.i}

define variable h as handle  no-undo.
define variable n as integer no-undo.
define variable c as integer no-undo.

create server h.
h:connect( substitute( "-URL http://&1:&2/apsv", pasoe_host, pasoe_port )).

c = random( 1, 100 ).

run orders.p on h ( c, output n ).

message substitute( "customer &1 has &2 order&3", c, n, ( if n = 1 then "" else "s" )).

/* pause. */
/* quit. */

finally:
  h:disconnect().
  delete object h.
end.
