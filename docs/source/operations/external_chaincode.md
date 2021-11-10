<a name = "external-chaincode"></a>
# Install, approve, commit and deploy external chaincode using BAF

Once a Hyperledger Fabric network is up, using BAF, BAF users might want to Install, approve, commit and deploy external chaincodes. BAF supports this task by executing the following steps:

 - [Update core.yaml with externalBuilder details](#update_core_yaml)
 - [Update Chaincode Server with these details](#chaincode_server)
 - [Modify configuration file](#modify_conf)
 - [Execute playbook](#execute_playbook)

<a name = "update_core_yaml"></a>
## Update core.yaml with externalBuilder details
Make sure the `chaincode` section of core.yaml consists of the following details:

```yaml
###############################################################################
#
#    Chaincode section
#
###############################################################################
chaincode:
  .
  .
  .
  # List of directories to treat as external builders and launchers for
  # chaincode. The external builder detection processing will iterate over the
  # builders in the order specified below.
  externalBuilders: 
  - name: external-builder
    path: /var/hyperledger/production/buildpacks/marbles 
  -
  -

  .
  .
  .
```
**NOTE:** The above values are sample vaules. *The `externalBuilders.path` should start be in the format - `/var/hyperledger/production/buildpacks/<CHAINCODE_NAME>`*

Refer [this guide](./update_running_core_yaml_peer.md) for updating a running core.yaml for a peer.

Refer [this link](https://github.com/hyperledger/fabric-samples/tree/main/asset-transfer-basic/chaincode-external/sampleBuilder/bin) for sample buildpack and [this guide](https://hyperledger-fabric.readthedocs.io/en/release-2.2/cc_launcher.html) for related documentation.


<a name = "chaincode_server"></a>
## Update Chaincode Server with these details
For BAF to be able to execute the external chaincode server it expects the following to be available:
- Chaincode server docker image
- Following env vars:
    - `CHAINCODE_CCID`: CCID generated while installing the chaincode
    - `CHAINCODE_ADDRESS`: Host and port details where the shim server will be listening
    - `CHAINCODE_TLS_DISABLED`: Boolean flag for if TLS is disabled
    - `CHAINCODE_TLS_KEY`: If TLS is enabled, path to the Client key
    - `CHAINCODE_TLS_CERT`: If TLS is enabled, path to the Client certificate
    - `CHAINCODE_CLIENT_CA_CERT`: If TLS is enabled, path to the Root CA cetificate

A sample server snippet in GOLANG:
```go
// ===================================================================================
// Main
// ===================================================================================
func main() {

	server := &shim.ChaincodeServer{
		CCID:    os.Getenv("CHAINCODE_CCID"),
		Address: os.Getenv("CHAINCODE_ADDRESS"),
		CC:      new(SimpleChaincode),
		TLSProps: getTLSProperties(),
	}

	// Start the chaincode external server
	err := server.Start()

	if err != nil {
		fmt.Printf("Error starting Marbles02 chaincode: %s", err)
	}
}


// TLS Function
func getTLSProperties() shim.TLSProperties {
	// Check if chaincode is TLS enabled
	tlsDisabledStr := getEnvOrDefault("CHAINCODE_TLS_DISABLED", "false")
	key := getEnvOrDefault("CHAINCODE_TLS_KEY", "")
	cert := getEnvOrDefault("CHAINCODE_TLS_CERT", "")
	clientCACert := getEnvOrDefault("CHAINCODE_CLIENT_CA_CERT", "")

	// convert tlsDisabledStr to boolean
	tlsDisabled := getBoolOrDefault(tlsDisabledStr, false)
	var keyBytes, certBytes, clientCACertBytes []byte
	var err error

	if !tlsDisabled {
		keyBytes, err = ioutil.ReadFile(key)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
		certBytes, err = ioutil.ReadFile(cert)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
	}
	// Did not request for the peer cert verification
	if clientCACert != "" {
		clientCACertBytes, err = ioutil.ReadFile(clientCACert)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
	}

	return shim.TLSProperties{
		Disabled: tlsDisabled,
		Key: keyBytes,
		Cert: certBytes,
		ClientCACerts: clientCACertBytes,
	}
}

func getEnvOrDefault(env, defaultVal string) string {
	value, ok := os.LookupEnv(env)
	if !ok {
		value = defaultVal
	}
	return value
}

// Note that the method returns default value if the string
// cannot be parsed!
func getBoolOrDefault(value string, defaultVal bool) bool {
	parsed, err := strconv.ParseBool(value)
	if err!= nil {
		return defaultVal
	}
	return parsed
}
```

<a name = "modify_conf"></a>
## Modify configuration file
Refer [this guide](./fabric_networkyaml.md) for details on editing the configuration file.

While modifying the configuration file(`network.yaml`) the belwo defined can be added under `network.organizations.services.peers[i].chaincode` as follows:
- `name`: Name of the chaincode
- `version`: version of the chaincode
- `external_chaincode`: Boolean Flag | for is the chaincode external
- `buildpack_path`: Path to the supplied buildpack to be copied to the peer node
- `image`: Docker image path for the desired docker registry
- `tls_disabled`: Boolean Flag | for is TLS disabled
- `crypto_mount_path`: If TLS is enabled, path to mount TLS certs and key in the chaincode server pod
Refer [this guide](./custom_core_yaml_peer.md) for details on editing the core.yaml file with template vars.

**NOTE:** The template vars are the variables defined in the Helm value file for the corresponding Helm Chart

    network:
      channels:
      - channel:
        ..
        ..
        participants:
      organizations:
        - organization:
          services:
            peers:
              name:
              type: 
              gossippeeraddress:
              cli:
              grpc:
                port: 
              chaincode:
                name: 
                version: 
                external_chaincode:
                tls_disabled: 
                buildpack_path: 
                image:
                pdc: # private data collection config
                  enabled:  # true/false
                  collections_config: # path to the config file
                private_registry: # true/false, this allows kubernetes to pull image from private registry, such as github.
                registry:
                  server:
                  username:
                  password:
                crypto_mount_path: 
          ..
          .. 

<a name = "execute_playbook"></a>
## Execute playbook

The [external-chaincode.yaml](https://github.com/hyperledger-labs/blockchain-automation-framework/tree/develop/platforms/shared/configuration/external-chaincode.yaml) playbook can be used install, approve, commit and deploy external chaincodes. This can be done using the following command

```
ansible-playbook platforms/shared/configuration/external-chaincode.yaml --extra-vars "@path-to-network.yaml"
```

For `network.yaml` reference, see `network-fabricv2-external-chaincode.yaml` file [here](https://github.com/hyperledger-labs/blockchain-automation-framework/tree/develop/platforms/hyperledger-fabric/configuration/samples).