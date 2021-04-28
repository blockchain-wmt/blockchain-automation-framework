apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: {{ component_name }}
  namespace: {{ name | lower | e }}-net
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ component_name }}
  chart:
    git: {{ git_url }}
    ref: {{ git_branch }}
    path: {{ charts_dir }}/install_external_chaincode
  values:
    metadata:
      namespace: {{ namespace }}
      network:
        version: {{ network.version }}
      images:
        fabrictools: {{ fabrictools_image }}
        alpineutils: {{ alpine_image }}
    peer:
      name: {{ peer_name }}
      address: {{ peer_address }}
      localmspid: {{ name }}MSP
      loglevel: debug
      tlsstatus: true
    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ namespace | e }}-auth
      chaincodesecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/peers/{{ peer_name }}.{{ namespace }}/chaincode
      adminsecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/users/admin 
      orderersecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/orderer
      serviceaccountname: vault-auth
      imagesecretname: regcred
      secretgitprivatekey: {{ vault.secret_path | default('secret') }}/credentials/{{ namespace }}/git?git_password
      tls: false
    chaincode:
      name: {{ component_chaincode.name | lower | e }}
      version: {{ component_chaincode.version }}
      sequence: {{ component_chaincode.sequence }}
      tls_disabled: {{ component_chaincode.tls_disabled }}
      address: chaincode-{{ component_chaincode.name | lower | e }}-{{ component_chaincode.version }}-{{ name | lower | e }}.{{ namespace }}.svc.cluster.local:7052
