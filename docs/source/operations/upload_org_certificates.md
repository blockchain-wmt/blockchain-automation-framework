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
      organizations:
        - organization:
          name: 
          type: # orderer / peer
          orgCertsDir: # directory that certificates to be downloaded to
          vault:
            url: 
            root_token: 
          components:  # list of peer names or orderer names
            - peer0



Sample file structure in the defined directory:

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

orgCertsDir need to be present in the organization which you want to upload the certificates, otherwise it will be skipped.

<a name = "run-playbook"></a>
## Run playbook

The [upload-org-certificates.yaml] playbook is used to upload public certificates for a network to vault. This can be done using the following command

```
ansible-playbook platforms/hyperledger-fabric/configuration/upload-org-certificates.yaml -e 'ansible_python_interpreter=/usr/bin/python3' -e "@./build/network.yaml" -vvv
```
