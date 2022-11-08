#!/bin/bash

set -x

CURRENT_DIR=${PWD}
FULLY_QUALIFIED_ORG_NAME="{{ component_ns }}"
EXTERNAL_URL_SUFFIX="{{ item.external_url_suffix }}"
ALTERNATIVE_ORG_NAMES=("{{ component_ns }}.{{ item.external_url_suffix }}")
ORG_NAME="{{ component_name }}"
SUBJECT="C={{ component_country }},ST={{ component_state }},L={{ component_location }},O={{ component_name }}"
SUBJECT_PEER="{{ component_subject }}"
CA="{{ ca_url }}"
CA_ADMIN_USER="${ORG_NAME}-admin"
CA_ADMIN_PASS="${ORG_NAME}-adminpw"

ORG_ADMIN_USER="Admin@${FULLY_QUALIFIED_ORG_NAME}"
ORG_ADMIN_PASS="Admin@${FULLY_QUALIFIED_ORG_NAME}-pw"

ORG_CYPTO_FOLDER="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}"

ROOT_TLS_CERT="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}/ca/ca.${FULLY_QUALIFIED_ORG_NAME}-cert.pem"

CAS_FOLDER="${HOME}/ca-tools/cas/ca-${ORG_NAME}"
ORG_HOME="${HOME}/ca-tools/${ORG_NAME}"

## Register and enroll node and populate its MSP folder
PEER="{{ peer_name }}.${FULLY_QUALIFIED_ORG_NAME}"
CSR_HOSTS=${PEER}
for i in "${ALTERNATIVE_ORG_NAMES[@]}"
do
	CSR_HOSTS="${CSR_HOSTS},{{ peer_name }}.${i}"
done
echo "Registering and enrolling $PEER with csr hosts ${CSR_HOSTS}"


# Register the peer
fabric-ca-client register -d --id.name ${PEER} --id.secret ${PEER}-pw --id.type orderer --tls.certfiles ${ROOT_TLS_CERT} --home ${CAS_FOLDER}

# Enroll to get peers TLS cert
fabric-ca-client enroll -d --enrollment.profile tls -u https://${PEER}:${PEER}-pw@${CA} -M ${ORG_HOME}/cas/orderers/tls --csr.hosts "${CSR_HOSTS}" --tls.certfiles ${ROOT_TLS_CERT} --csr.names "${SUBJECT_PEER}"


# Enroll again to get the peer's enrollment certificate (default profile)
fabric-ca-client enroll -d -u https://${PEER}:${PEER}-pw@${CA} -M ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp --tls.certfiles ${ROOT_TLS_CERT} --csr.names "${SUBJECT_PEER}"


if [ "{{ proxy }}" != "none" ]; then
    mkdir -p ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/cacerts/
	mv ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/cacerts/*.pem ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/cacerts/ca-${FULLY_QUALIFIED_ORG_NAME}-${EXTERNAL_URL_SUFFIX}-8443.pem
fi
cp ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/cacerts/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/tlscacerts/

# Copy the peer org's admin cert into target MSP directory
mkdir -p ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/admincerts

cp ${ORG_CYPTO_FOLDER}/msp/admincerts/${ORG_ADMIN_USER}-cert.pem ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/admincerts

cd ${CURRENT_DIR}
