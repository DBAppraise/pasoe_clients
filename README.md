# pasoe_clients

README
======

PASOE clients and scripts to drive workload on PASOE

The target PASOE instance should have the "Orders" service running with a
sports2000 database for its backend.

By default this package will launch clients to create traffic on that PASOE
server. Each of the PASOE "transports" will be randomly selected in the
following proportions:

	SOAP	  5%
	REST	 15%
	WEBH	 30%
	APSV	 50%

The mix can be modified by editing driver.p.

Each transport makes requests for a count of orders for a random custNum by
calling the "Orders" service on PASOE.

By default, connections are made to localhost and port 8810. That can be
changed by modifying pasoe_cnx.i.

It is perfectly ok to deploy multiple different sets of clients on various
remote servers and to run them simultaneously if that sort of thing is
interesting for some reason. You might, for instance, be investigating
differences in performance and latency related to different configuration
and deployment choices.


Contents:

  - driver.sh		shell script that launches an instance of the driver
			this script takes a "thread number" argument (i.e. "001"
			that is used to keep instances unique and to create
			discrete log files

  - driver.p		the dot-p that actually makes the calls

  - pasoe_cnx.i		an include file that specifies the target server and
			port number


  - apsv_orders.p	sample code that demonstrates calling "Orders" directly
			with a dot-p and the APSV transport

  - apsv_orders.sh	shell script to invoke apsv_orders.p

  - rest_orders.sh	shell script that uses "curl" to call Orders using the
			REST transport

  - soap_orders.sh	shell script that builds an XML file used by "curl" to
			call Orders using the SOAP transport

  - webh_orders.sh	shell script that uses "curl" to call Orders using a
			web handler (the "WEB" or "WEBH" transport)

  - apsv_gsv.p		runs "gsv.p" on the PASOE server to demonstrate the
			behavior of global shared variables in a PASOE service

  - count_orders.p	directly report on number of orders per customer in order
			to validate results returned from calling "Orders"

  - log			directory where log files are written

  - tmp			directory containing flags, debug logs, add scratch files

  - pasoe_clients.tar   the tarball which contained the contents described herein

  - README.md		this file
