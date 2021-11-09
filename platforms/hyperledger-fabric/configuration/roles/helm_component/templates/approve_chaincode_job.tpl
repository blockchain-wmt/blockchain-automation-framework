apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: {{ component_name }}
  namespace: {{ namespace }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ component_name }}
  chart:
    git: {{ git_url }}
    ref: {{ git_branch }}
    path: {{ charts_dir }}/approve_chaincode
  values:
    metadata:
      namespace: {{ namespace }}
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
      authpath: {{ network.env.type }}{{ namespace | e }}-auth
      adminsecretprefix: secret/crypto/peerOrganizations/{{ namespace }}/users/admin 
      orderersecretprefix: secret/crypto/peerOrganizations/{{ namespace }}/orderer
      serviceaccountname: vault-auth
      imagesecretname: regcred
      tls: false
    orderer:
      address: {{ participant.ordererAddress }}
    chaincode:
      builder: hyperledger/fabric-ccenv:{{ network.version }}
      name: {{ component_chaincode.name | lower | e }}
      version: {{ component_chaincode.version }}
      sequence: {{ component_chaincode.sequence | default('1') }}
      commitarguments: {{ component_chaincode.arguments | quote}}
      endorsementpolicies:  {{ component_chaincode.endorsements | quote }}
{% if component_chaincode.repository is defined %}
      repository:
        hostname: "{{ component_chaincode.repository.url.split('/')[0] | lower }}"
        git_username: "{{ component_chaincode.repository.username}}"
        url: {{ component_chaincode.repository.url }}
        branch: {{ component_chaincode.repository.branch }}
        path: {{ component_chaincode.repository.path }}
{% if component_chaincode.repository.collections_config is defined %}
        collectionsconfig:  {{ component_chaincode.repository.collections_config }} 
{% else %}
        collectionsconfig:  ""
{% endif %}
{% endif %}
{% if peer.chaincode.pdc is defined and peer.chaincode.pdc.enabled %}
      pdc:
        enabled: true
        collectionsconfig: "{{ lookup('file', '{{ peer.chaincode.pdc.collections_config }}') | b64encode }}"
{% else %}
      pdc:
        enabled: false
        collectionsconfig: ""
{% endif %}
    channel:
      name: {{ item.channel_name | lower }}
