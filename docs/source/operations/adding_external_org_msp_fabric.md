<a name = "adding-org-msp-to-existing-channel-in-fabric"></a>
# Adding an external organization's MSP in existing channel

- [Adding an external organization's MSP in existing channel](#adding-an-external-organizations-msp-in-existing-channel)
  - [Prerequisites](#prerequisites)
  - [Modifying Configuration File](#modifying-configuration-file)
  - [Run playbook](#run-playbook)


<a name = "prerequisites"></a>
## Prerequisites
To add an external organization's MSP to an existing channel, a fully configured Fabric network must be present already, i.e. a Fabric network which has Orderers, Peers, Channels (with all Peers already in the channels). 
The corresponding crypto materials should be available for the target organization and stored in vault following this structure:

**msp admincerts** `{{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ organization.name | lower }}-net/users/admin/msp`

**msp cacerts** `{{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ organization.name | lower }}-net/users/admin/msp`

**msp tlscacerts** `{{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ organization.name | lower }}-net/users/admin/msp`

---

<a name = "create_config_file"></a>
## Modifying Configuration File

Refer [this guide](./fabric_networkyaml.md) for details on editing the configuration file.

While modifying the configuration file(`network.yaml`) for adding new organization, all the existing organizations should have `org_status` tag as `existing` and the new organization should have `org_status` tag as `new` under `network.channels` eg.

```yaml
    network:
      channels:
      - channel:
        ..
        ..
        participants:
        - organization:
          ..
          ..
          org_status: existing  # existing for old organization(s)
        - organization:
          name: ccrr
          type: joiner       # creator organization will create the channel and instantiate chaincode, in addition to joining the channel and install chaincode
          org_status: new  # new for the org
          external_org: # indicates it's an external org
            skip_anchor: true # skips anchor peer definition for the org
            skip_check: true # skips the pod check for the org
```

and under `network.organizations` as
  
```yaml
    network:
      organizations:
        - organization:
          ..
          ..
          org_status: existing  # existing for old organizations
        - organization:
          name: 
          type:
          org_status: new # new external org to be added
          external_url_suffix:
          cloud_provider:  # Options: aws, azure, gcp, minikube
          aws:
            access_key: "aws_access_key"        # AWS Access key, only used when cloud_provider=aws
            secret_key: "aws_secret_key"        # AWS Secret key, only used when cloud_provider=aws
          k8s:
            region: 
            context:
            config_file:
          vault:
            url:
            root_token:

          services:
            ca:
              grpc:
                port: 7054
            peers:
              - peer:
                name: peer0
```

The `network.yaml` file should contain the specific `network.organization` patch along with the orderer information.

For reference, see `network-fabric-add-organization.yaml` file [here](https://github.com/hyperledger-labs/blockchain-automation-framework/tree/master/platforms/hyperledger-fabric/configuration/samples).

<a name = "run_network"></a>
## Run playbook

The [add-organization-msp.yaml](https://github.com/hyperledger-labs/blockchain-automation-framework/tree/master/platforms/shared/configuration/add-organization-msp.yaml) playbook is used to add an organization's MSP to an existing channel. This can be done using the following command

```bash
ansible-playbook platforms/shared/configuration/add-external-org-msp.yaml --extra-vars "@path-to-network.yaml" -e "fetch_certs='true'" -e "add_new_org='true'"
```

---
**NOTE:** This playbook should be executed by the organization who is a creator of the respective channel and has access to the orderer service. Make sure that the `org_status` label was set as `new` when the network is deployed for the first time. If you have additional applications, please deploy them as well.
