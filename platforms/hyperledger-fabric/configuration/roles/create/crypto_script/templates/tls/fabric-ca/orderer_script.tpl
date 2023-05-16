#!/bin/bash

set -x

CURRENT_DIR=${PWD}
FULLY_QUALIFIED_ORG_NAME="{{ component_ns }}"
EXTERNAL_URL_SUFFIX="{{ item.external_url_suffix }}"
ALTERNATIVE_ORG_NAMES=("{{ component_ns }}.{{ item.external_url_suffix }}")
ORG_NAME="{{ component_name }}"
SUBJECT_PEER="{{ component_subject }}"
CA="{{ ca_url }}"

ORG_CYPTO_FOLDER="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}"

ROOT_TLS_CERT="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}/ca/ca.${FULLY_QUALIFIED_ORG_NAME}-cert.pem"

ORG_HOME="${HOME}/ca-tools/${ORG_NAME}"
rm -rf ${ORG_HOME}/cas/orderers/tls
## Register and enroll node and populate its MSP folder
PEER="{{ peer_name }}.${FULLY_QUALIFIED_ORG_NAME}"
CSR_HOSTS=${PEER}
mkdir -p ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls
for i in "${ALTERNATIVE_ORG_NAMES[@]}"
do
	CSR_HOSTS="${CSR_HOSTS},{{ peer_name }}.${i}"
done
echo "enrolling $PEER with csr hosts ${CSR_HOSTS}"
mkdir -p ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/tlscacerts/
# Enroll to get peers TLS cert
fabric-ca-client enroll -d --enrollment.profile tls -u https://${PEER}:${PEER}-pw@${CA} -M ${ORG_HOME}/cas/orderers/tls --csr.hosts "${CSR_HOSTS}" --tls.certfiles ${ROOT_TLS_CERT} --csr.names "${SUBJECT_PEER}"

# Copy the TLS key and cert to the appropriate place
ls ${ORG_HOME}/cas/orderers/tls/keystore/
cp ${ORG_HOME}/cas/orderers/tls/keystore/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls/server.key
cp ${ORG_HOME}/cas/orderers/tls/signcerts/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls/server.crt
cp ${ORG_HOME}/cas/orderers/tls/tlscacerts/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls/ca.crt

rm -rf ${ORG_HOME}/cas/orderers/tls

# Create the TLS CA directories of the MSP folder if they don't exist.
mkdir ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/tlscacerts

if [ "{{ proxy }}" != "none" ]; then
	mv ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/cacerts/*.pem ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/cacerts/ca-${FULLY_QUALIFIED_ORG_NAME}-${EXTERNAL_URL_SUFFIX}-8443.pem
fi
cp ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/cacerts/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/tlscacerts/

cd ${CURRENT_DIR}