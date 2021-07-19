<a name = "metrics-fabric"></a>
# Enable metrics operations server on Hyperledger Fabric nodes

- Step 1: Update peer/orderer configuration to enable operations endpoint.
- Step 2: Enable prometheus metrics collection in the peer/orderer configuration.
- Step 3: Configure the network spec file as expected.
- Step 4: Run the playbook to update peer/orderer configuration.

For example, in case of both the orderer and peer node:


	network:
	  version: 1.4.8

    organizations:
      ...
        services:
          peers:
            - peer:
              metrics:
                enabled: false
                nodeport: 30001
