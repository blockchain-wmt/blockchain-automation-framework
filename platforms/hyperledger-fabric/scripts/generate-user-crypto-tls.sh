#!/bin/bash
# if [ $# -lt 7 ]; then
# 	echo "Usage : . $0 orderer|peer <namespace> <nodename> <user-identities> <affiliation> <subject> <ca-server-url>"
# 	exit
# fi

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
echo "inputs to script ===>" $#
CURRENT_DIR=${PWD}

CA_TYPE="{{ item.services.ca.tls_ca.type }}"
# Input parameters
FULLY_QUALIFIED_ORG_NAME=$2
component_ns=$2
ORG_NAME=$3
TYPE_FOLDER=$1
USER_IDENTITIES=$4
AFFILIATION=$5
CA_TYPE=$6
CWS_SERVER_URL=$7
external_url_suffix=$8


ALTERNATIVE_ORG_NAMES="$component_ns"."$external_url_suffix"

if [ "$1" != "peer" ]; then
	ORG_CYPTO_FOLDER="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}"
	ROOT_TLS_CERT="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}/ca/ca.${FULLY_QUALIFIED_ORG_NAME}-cert.pem"
else
	ORG_CYPTO_FOLDER="/crypto-config/$1Organizations/${FULLY_QUALIFIED_ORG_NAME}"
	ROOT_TLS_CERT="/crypto-config/$1Organizations/${FULLY_QUALIFIED_ORG_NAME}/ca/ca.${FULLY_QUALIFIED_ORG_NAME}-cert.pem"
fi

CAS_FOLDER="${HOME}/cwscli/cas/ca-${ORG_NAME}"
ORG_HOME="${HOME}/cwscli/${ORG_NAME}"

## Register and enroll users
CUR_USER=0
TOTAL_USERS=$(echo ${USER_IDENTITIES})
while [ ${CUR_USER} -lt ${TOTAL_USERS} ]; do
	
	# Get the user identity
	USER="Admin"
	ORG_USER="${USER}@${ALTERNATIVE_ORG_NAMES}"
	ORG_USERPASS="${USER}@${FULLY_QUALIFIED_ORG_NAME}-PW-123"
    PASSWORD=$ORG_USERPASS

	OUTPUT_PATH=${ORG_HOME}/client${USER}/tls
	mkdir -p $OUTPUT_PATH
	# Get TLS cert for user and copy to appropriate location
	retry cws-ca-client create --ca.type=$CA_TYPE --cname=${ORG_USER} -u=$CWS_SERVER_URL

	retry cws-ca-client download -f='pkcs#12' --ca.type=$CA_TYPE --cname=$ORG_USER -u=$CWS_SERVER_URL --includechain=1 --includeprivatekey=1 --password=$PASSWORD --output=${OUTPUT_PATH}/cert

	# client key
	retry openssl pkcs12 -in $OUTPUT_PATH/cert -nocerts -out $OUTPUT_PATH/client-tls.key -nodes -password pass:$PASSWORD
	sed -ne '/-BEGIN PRIVATE KEY-/,/-END PRIVATE KE-/p'  $OUTPUT_PATH/client-tls.key >  $OUTPUT_PATH/client.key
	# client certificate
	retry openssl pkcs12 -in $OUTPUT_PATH/cert -nokeys -out  $OUTPUT_PATH/client-tls.crt -nodes -password pass:$PASSWORD
	sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'  $OUTPUT_PATH/client-tls.crt >  $OUTPUT_PATH/cert-chain.crt 
	
	cat $OUTPUT_PATH/cert-chain.crt | awk -v OUTPUT="$OUTPUT_PATH"  '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){i++}; out=OUTPUT"/cert"i".crt"; print >out}'

	# Copy the TLS key and cert to the appropriate place
	mv $OUTPUT_PATH/cert1.crt $OUTPUT_PATH/client.crt
	mv $OUTPUT_PATH/cert2.crt $OUTPUT_PATH/ca.crt
    mkdir -p ${ORG_CYPTO_FOLDER}/users/${USER}@${component_ns}/tls
	cp ${ORG_HOME}/client${USER}/tls/* ${ORG_CYPTO_FOLDER}/users/${USER}@${component_ns}/tls

	CUR_USER=$((CUR_USER + 1))
done
cd ${CURRENT_DIR}
