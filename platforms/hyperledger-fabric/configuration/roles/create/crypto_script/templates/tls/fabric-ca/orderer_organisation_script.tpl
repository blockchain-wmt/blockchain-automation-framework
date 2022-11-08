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

# Get TLS cert for admin and copy to appropriate location
fabric-ca-client enroll -d --enrollment.profile tls -u https://${ORG_ADMIN_USER}:${ORG_ADMIN_PASS}@${CA} -M ${ORG_HOME}/admin/tls --tls.certfiles ${ROOT_TLS_CERT}  --csr.names "${SUBJECT_PEER}"

# Copy the TLS key and cert to the appropriate place
mkdir -p ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls
cp ${ORG_HOME}/admin/tls/keystore/* ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/client.key
cp ${ORG_HOME}/admin/tls/signcerts/* ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/client.crt
cp ${ROOT_TLS_CERT} ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/ca.crt

cd ${CURRENT_DIR}
