#!/bin/sh
#

export PASOEHOST=192.168.0.55
export PASOEPORT=8810

# to obtain the wsdl:
# curl http://${PASOEHOST}:${PASOEPORT}/soap/wsdl?targetURI=urn:tempuri-org

RQFILE=tmp/request.txt

if [ -z "${1}" ]
then
	CNUM=$(( $RANDOM % 99 ))
else
	CNUM=${1}
fi

### CNUM is embedded in the file so caching it is a bad idea
###
### if [ ! -f ${RQFILE} ]
### then
	echo '<?xml version="1.0" encoding="utf-8"?>' 					>  ${RQFILE}
	echo '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'	>> ${RQFILE}
	echo '  <soap:Body>' 								>> ${RQFILE}
	echo '    <orders xmlns="urn:tempuri-org:OrderMaint">' 				>> ${RQFILE}
	echo "      <cnum>${CNUM}</cnum>" 						>> ${RQFILE}
	echo '    </orders>' 								>> ${RQFILE}
	echo '  </soap:Body>' 								>> ${RQFILE}
	echo '</soap:Envelope>' 							>> ${RQFILE}
### fi

curl --no-progress-meter --request POST --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction: ''" -T ${RQFILE} http://${PASOEHOST}:${PASOEPORT}/soap
echo ""
