apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: {{ name }}-{{ chaincode_name }}-{{ peer.chaincode.version }}
  namespace: {{ chaincode_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ name }}-{{ chaincode_name }}-{{ peer.chaincode.version }}
  chart:
    git: {{ git_url }}
    ref: {{ git_branch }}
    path: {{ charts_dir }}/external-chaincode    
  values:
    metadata:
      namespace: {{ chaincode_ns }}
      network:
        version: {{ network.version }}
      images:
        external_chaincode: {{ chaincode_image }}
        alpineutils: {{ alpine_image }}

    chaincode:
      org: {{ org_name }}
      name: {{ peer.chaincode.name }}
      version: {{ peer.chaincode.version }}
      ccid: {{ ccid.stdout | replace(',','') }} 
      tls_disabled: {{ peer.chaincode.tls_disabled }}
{% if peer.chaincode.tls_disabled == false %}      
      crypto_mount_path: {{ peer.chaincode.crypto_mount_path }}
{% endif %}

    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ network.env.type }}{{ namespace }}-auth
      chaincodesecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/chaincode/{{ peer.chaincode.name }}/certificate/v{{ peer.chaincode.version }}
      serviceaccountname: vault-auth
      imagesecretname: regcred

    service:
      servicetype: ClusterIP
