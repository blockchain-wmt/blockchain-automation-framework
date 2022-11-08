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

set -x
CWS_SERVER_URL="{{ item.services.ca.tls_ca.url }}"
CA_TYPE="{{ item.services.ca.tls_ca.type }}"
FULLY_QUALIFIED_ORG_NAME="{{ component_ns }}"
ALTERNATIVE_ORG_NAMES=("{{ component_ns }}.{{ item.external_url_suffix }}")
PEER="{{ peer_name }}.${FULLY_QUALIFIED_ORG_NAME}"
ORG_CYPTO_FOLDER="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}"
OUTPUT_PATH=${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls
PASSWORD="${PEER}-PW-123"
mkdir -p ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls

PEER="{{ peer_name }}.${ALTERNATIVE_ORG_NAMES}"
CSR_HOSTS="{{ peer_name }}.${FULLY_QUALIFIED_ORG_NAME}"
for i in "${ALTERNATIVE_ORG_NAMES[@]}"
do
	CSR_HOSTS="${CSR_HOSTS},{{ peer_name }}.${i}"
done
#creating TLS certificates
retry cws-ca-client create --ca.type=$CA_TYPE --cname=$PEER -u=$CWS_SERVER_URL --san=$CSR_HOSTS

retry cws-ca-client download -f='pkcs#12' --ca.type=$CA_TYPE --cname=$PEER -u=$CWS_SERVER_URL --includechain=1 --includeprivatekey=1 --password=$PASSWORD --output=${OUTPUT_PATH}/cert

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
cd ${CURRENT_DIR}


