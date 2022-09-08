# prepare certificates for peers before installing chaincode

This role copy the orderer ca certficate to peers for preparing chaincode installation

## main.yaml

## Tasks

### 1. Check if orderer ca file exists in the host directory (check_orderer_certs.yaml)

This tasks check if the orderer ca file {{ first orderer org name }}-ca.crt (use the first orderer org in the list) exists or not in platforms/hyperledger-fabric/configuration/build/

If file doesn't exist, check if it's in the vault; if it doesn't exist in the vault, stop the process. Otherwise, download it to location in the host.

### 2. Check if the orderer ca is in vault for each peer (setup_peer.yaml)

This task check if the each peer has the orderer ca set up, if so, skip the proces; otherwise upload the orderer ca to the vault for the peer.
