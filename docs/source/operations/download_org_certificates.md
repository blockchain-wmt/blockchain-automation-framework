<a name = "download-org-certificates-from-vault"></a>
# Download Org certificates from Vault

- [Download Org certificates from Vault]("download-org-certificates-from-vault")
  - [Prerequisites](#prerequisites)
  - [Modifying Configuration File](#modifying-configuration-file)
  - [Run playbook](#run-playbook)

<a name = "prerequisites"></a>
## Prerequisites
To download the org certificates, peers in the network needs to be present already. The corresponding crypto materials should also be present in their respective Hashicorp Vault. 

---

<a name = "modifying-configuration-file"></a>
## Modifying Configuration File

While modifying the configuration file(`network.yaml`) for downloading certificates, put the list of organizations you want to download

    network:
      organizations:
        - organization:
          name: 
          type: # orderer / peer
          orgCertsDir:
          vault:
            url: 
            root_token: 

orgCertsDir need to be present in the organization which you want to download the certificates, otherwise it will be skipped.

<a name = "run-playbook"></a>
## Run playbook

The [download-org-certificates.yaml] playbook is used to download public certificates from the existing network. This can be done using the following command

```
ansible-playbook platforms/hyperledger-fabric/configuration/download-org-certificates.yaml -e 'ansible_python_interpreter=/usr/bin/python3' -e "@./build/network.yaml" -vvv
```
