apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: {{ name }}-{{ peer_name }}
  namespace: {{ peer_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ name }}-{{ peer_name }}
  chart:
    git: {{ git_url }}
    ref: {{ git_branch }}
    path: {{ charts_dir }}/peernode    
  values:
    metadata:
      namespace: {{ peer_ns }}
      images:
        couchdb: {{ couchdb_image }}
        peer: {{ peer_image }}
        alpineutils: {{ alpine_image }}
        
    peer:
      name: {{ peer_name }}
      gossippeeraddress: {{ peer.gossippeeraddress }}
{% if provider == 'none' %}
      gossipexternalendpoint: {{ peer_name }}.{{ peer_ns }}:7051
{% else %}
      gossipexternalendpoint: {{ peer_name }}.{{ peer_ns }}.{{item.external_url_suffix}}:8443
{% endif %}
      localmspid: {{ name }}MSP
      loglevel: info
      tlsstatus: true
      builder: hyperledger/fabric-ccenv:{{ network.version }}
      couchdb:
        username: {{ name }}-user
{% if peer.core_yaml is defined and peer.core_yaml.initialize_from == 'file' %}
      core_yaml:
        initialize_from: file
        tpl: {{ peer.core_yaml.tpl }}
{% if peer.core_yaml.tpl == False %}
        base64: {{ core_yaml_file.stdout | b64encode }}
{% endif %}
{% if peer.core_yaml.configpath is defined %}
        configpath: conf/{{ peer_name }}_{{ name }}_core.yaml
{% endif %}
{% endif %}

    storage:
      peer:
        storageclassname: {{ name }}sc
        storagesize: 512Mi
      couchdb:
        storageclassname: {{ name }}sc
        storagesize: 1Gi

    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ network.env.type }}{{ namespace }}-auth
      secretprefix: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/peers/{{ peer_name }}.{{ namespace }}
      secretambassador: {{ vault.secret_path | default('secret') }}/crypto/peerOrganizations/{{ namespace }}/ambassador
      serviceaccountname: vault-auth
      imagesecretname: regcred
      secretcouchdbpass: {{ vault.secret_path | default('secret') }}/credentials/{{ namespace }}/couchdb/{{ name }}?user

    service:
      servicetype: ClusterIP
      ports:
        grpc:
          clusteripport: {{ peer.grpc.port }}
{% if peer.grpc.nodePort is defined %}
          nodeport: {{ peer.grpc.nodePort }}
{% endif %}
        events:
          clusteripport: {{ peer.events.port }}
{% if peer.events.nodePort is defined %}
          nodeport: {{ peer.events.nodePort }}
{% endif %}
        couchdb:
          clusteripport: {{ peer.couchdb.port }}
{% if peer.couchdb.nodePort is defined %}
          nodeport: {{ peer.couchdb.nodePort }}
{% endif %}
          
    proxy:
      provider: "{{ network.env.proxy }}"
      external_url_suffix: {{ item.external_url_suffix }}
