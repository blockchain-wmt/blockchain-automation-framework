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
{% if network.env.labels is defined %}
      labels:  
{% for key in network.env.labels.keys() %}
         {{ key }}: {{ network.env.labels[key] | quote }}
{% endfor %}
{% endif %}
    peer:
      name: {{ peer_name }}
      address: {{ peer_address }}
      localmspid: {{ name }}MSP
      loglevel: debug
      tlsstatus: true
    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ network.env.type }}{{ namespace | e }}-auth
      chaincodesecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/peers/{{ peer_name }}.{{ namespace }}/chaincode
      adminsecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/users/admin 
      orderersecretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/orderer
      serviceaccountname: vault-auth
      imagesecretname: regcred
      secretgitprivatekey: {{ vault.secret_path | default('secret') }}/credentials/{{ namespace }}/git?git_password
      tls: false
      chaincodepackageprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/chaincode/{{ component_chaincode.name | lower | e }}/package/v{{ component_chaincode.version }}
    chaincode:
      name: {{ component_chaincode.name | lower | e }}
      version: {{ component_chaincode.version }}
      sequence: {{ component_chaincode.sequence }}
      tls_disabled: {{ component_chaincode.tls_disabled }}
      address: chaincode-{{ component_chaincode.name | lower | e }}-{{ component_chaincode.version }}-{{ name | lower | e }}.{{ namespace }}.svc.cluster.local:7052
