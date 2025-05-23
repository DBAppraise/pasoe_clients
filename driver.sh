#!/bin/sh
#

if [ -z "${1}" ]
then
	TNUM="000"
else
	TNUM="${1}"
fi

export PROPATH=.:/home/protop

_progres -b -p ./driver.p -rand 2 -param "${TNUM}" -clientlog tmp/getOrders.${TNUM}.debug > tmp/getOrders.${TNUM}.err 2>&1 &
