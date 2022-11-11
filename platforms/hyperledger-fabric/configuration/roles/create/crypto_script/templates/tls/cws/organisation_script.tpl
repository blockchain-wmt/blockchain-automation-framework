#!/bin/bash
function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
  local delay=10
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}


function cwstls(){
	CNAME=$1  
	CSR_HOSTS=$2
	OUTPUT_PATH=$3
	PASSWORD="${CNAME}-PW-123"
	mkdir -p ${OUTPUT_PATH}
	if [[ -z "$CSR_HOSTS" ]]; then
	   retry cws-ca-client create --ca.type=$CA_TYPE --cname=$CNAME -u=$CWS_SERVER_URL
    else
        retry cws-ca-client create --ca.type=$CA_TYPE --cname=$CNAME -u=$CWS_SERVER_URL --san=$CSR_HOSTS
	fi
	retry cws-ca-client download -f='pkcs#12' --ca.type=$CA_TYPE --cname=$CNAME -u=$CWS_SERVER_URL --includechain=1 --includeprivatekey=1 --password=$PASSWORD --output=${OUTPUT_PATH}/cert

	# client key
	retry openssl pkcs12 -in $OUTPUT_PATH/cert -nocerts -out $OUTPUT_PATH/client-tls.key -nodes -password pass:$PASSWORD
	sed -ne '/-BEGIN PRIVATE KEY-/,/-END PRIVATE KE-/p'  $OUTPUT_PATH/client-tls.key >  $OUTPUT_PATH/server.key
	# client certificate
	retry openssl pkcs12 -in $OUTPUT_PATH/cert -nokeys -out  $OUTPUT_PATH/client-tls.crt -nodes -password pass:$PASSWORD
	sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'  $OUTPUT_PATH/client-tls.crt >  $OUTPUT_PATH/cert-chain.crt 
	
	cat $OUTPUT_PATH/cert-chain.crt | awk -v OUTPUT="$OUTPUT_PATH"  '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){i++}; out=OUTPUT"/cert"i".crt"; print >out}'

	# Copy the TLS key and cert to the appropriate place
	mv $OUTPUT_PATH/cert1.crt $OUTPUT_PATH/server.crt
	mv $OUTPUT_PATH/cert2.crt $OUTPUT_PATH/ca.crt
}

set -x
CWS_SERVER_URL="{{ item.services.ca.tls_ca.url }}"
CA_TYPE="{{ item.services.ca.tls_ca.type }}"

CURRENT_DIR=${PWD}
FULLY_QUALIFIED_ORG_NAME="{{ component_ns }}"
ALTERNATIVE_ORG_NAMES=("{{ component_ns }}.svc.cluster.local" "{{ component_name }}.net" "{{ component_ns }}.{{ item.external_url_suffix }}")
ORG_NAME="{{ component_name }}"
EXTERNAL_URL_SUFFIX="{{ item.external_url_suffix }}"
AFFILIATION="{{ component_name }}"
SUBJECT="C={{ component_country }},ST={{ component_state }},L={{ component_location }},O={{ component_name }}"
SUBJECT_PEER="{{ component_subject }}"
CA="{{ ca_url }}"

ORG_ADMIN_USER="Admin@${FULLY_QUALIFIED_ORG_NAME}"

ORG_HOME="/crypto-config/peerOrganizations/${FULLY_QUALIFIED_ORG_NAME}"

NO_OF_PEERS={{ peer_count | e }}

CNAME=$ORG_ADMIN_USER."{{ component_ns }}.{{ item.external_url_suffix }}"
# Get TLS cert for admin and copy to appropriate location
ADMIN_CERT_LOCATION="${ORG_HOME}/users/$ORG_ADMIN_USER/tls"
cwstls $CNAME "" $ADMIN_CERT_LOCATION

## Register and enroll peers and populate their MSP folder
COUNTER=0
while [  ${COUNTER} -lt ${NO_OF_PEERS} ]; do
	PEER="peer${COUNTER}.${FULLY_QUALIFIED_ORG_NAME}.${EXTERNAL_URL_SUFFIX}"
	CSR_HOSTS=${PEER}
	for i in "${ALTERNATIVE_ORG_NAMES[@]}"
	do
		CSR_HOSTS="${CSR_HOSTS},peer${COUNTER}.${i}"
	done
	# Enroll to get peers TLS cert
	cwstls ${PEER} "${CSR_HOSTS}" "${ORG_HOME}/peers/peer${COUNTER}.${FULLY_QUALIFIED_ORG_NAME}/tls"

	let COUNTER=COUNTER+1
done

cd ${CURRENT_DIR}
