<a name = "upload-org-certificates-to-vault"></a>
# Upload Org certificates from Local to Vault

- [Download Org certificates from Vault]("upload-org-certificates-to-vault")
  - [Prerequisites](#prerequisites)
  - [Modifying Configuration File](#modifying-configuration-file)
  - [Run playbook](#run-playbook)

<a name = "prerequisites"></a>
## Prerequisites
To upload the org certificates, Vault needs to be present already. The corresponding crypto materials should also be present in their respective directory. 

---

<a name = "modifying-configuration-file"></a>
## Modifying Configuration File

While modifying the configuration file(`network.yaml`) for downloading certificates, put the list of organizations you want to download

    # network config for upload certificate
    network:
      channels: # if channels is defined, orderer/endorsers certificates will be uploaded
        - channel:
          orderer: # if orderer is defined, orderer cacert will be uploaded
            name: 
          participants:
            - organization:
              name: 
          endorsers: # if endorsers is defined, endorsers admin msp cacert will be uploaded
            name:
            -
            -
      organizations:
        - organization:
          name: 
          type: peer
          orgCerts:
            path: # certificates directory
            forceUpdate: # if it's true, force update the certificate for this org. otherwise if the certificates exists in vault already, update will be ignored.
          vault:
            url: 
            root_token: 
          components:  # list of peer names or orderer names	
            - peer0



---
Sample folder structure:

```
`-- crypto
    |-- ordererOrganizations
    |   |-- intord-net
    |   |   |-- ca
    |   |   |   `-- ca.crt.pem
    |   |   `-- orderers
    |   |       `-- intord1.intord-net
    |   |           `-- msp
    |   |               `-- tlscacerts.pem
    |   `-- orderer-net
    |       `-- orderer
    |           `-- ca.crt.pem
    `-- peerOrganizations
        |-- carrier-net
        |   |-- peers
        |   |   |-- peer0.carrier-net
        |   |   |   `-- msp
        |   |   |       `-- tlscacerts.pem
        |   |   `-- peer1.carrier-net
        |   |       `-- msp
        |   |           `-- tlscacerts.pem
        |   `-- users
        |       `-- admin
        |           `-- msp
        |               |-- admincerts.pem
        |               |-- cacerts.pem
        |               `-- tlscacerts.pem
```

orgCerts.path need to be present in the organization which you want to upload the certificates, otherwise it will be skipped.

<a name = "run-playbook"></a>
## Run playbook

The [upload-org-certificates.yaml] playbook is used to upload public certificates for a network to vault. This can be done using the following command

```
ansible-playbook platforms/hyperledger-fabric/configuration/upload-org-certificates.yaml -e 'ansible_python_interpreter=/usr/bin/python3' -e "@./build/network.yaml" -vvv
```
