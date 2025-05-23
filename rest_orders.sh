#!/bin/sh
#

export PASOEHOST=192.168.0.55
export PASOEPORT=8810

if [ -z "${1}" ]
then
	CNUM=$(( $RANDOM % 99 ))
else
	CNUM=${1}
fi

curl --no-progress-meter -X GET http://${PASOEHOST}:${PASOEPORT}/rest/restProxyService/orders?customer=${CNUM}
echo ""
