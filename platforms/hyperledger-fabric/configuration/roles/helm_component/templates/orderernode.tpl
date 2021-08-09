apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: {{ org_name }}-{{ orderer.name }}
  namespace: {{ namespace }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ org_name }}-{{ orderer.name }}
  chart:
    git: {{ git_url }}
    ref: {{ git_branch }}
    path: {{ charts_dir }}/orderernode
  values:
    metadata:
      namespace: {{ namespace }}
      images:
        orderer: {{ orderer_image }}
        alpineutils: {{ alpine_image }}

    orderer:
      name: {{ orderer.name }}
      loglevel: info
      localmspid: {{ org_name }}MSP
      tlsstatus: true
      keepaliveserverinterval: 10s
{% if orderer.orderer_yaml is defined and orderer.orderer_yaml.initialize_from == 'file' %}
      orderer_yaml:
        initialize_from: file
        tpl: {{ orderer.orderer_yaml.tpl }}
{% if orderer.orderer_yaml.tpl == false %}
        base64: {{ orderer_yaml_file | b64encode }}
{% endif %}
{% if orderer.orderer_yaml.configpath is defined %}
        configpath: conf/{{  orderer.name }}_{{ org_name }}_orderer.yaml
{% endif %}
{% endif %}      
    
    consensus:
      name: {{ orderer.consensus }}

    storage:
      storageclassname: {{ org_name }}sc
      storagesize: 512Mi  

    service:
      servicetype: ClusterIP
      ports:
        grpc:
          clusteripport: {{ orderer.grpc.port }}
{% if orderer.grpc.nodePort is defined %}
          nodeport: {{ orderer.grpc.nodePort }}
{% endif %}
        metrics:
          enabled: {{ orderer.metrics.enabled }}
{% if orderer.metrics.clusteripport is defined %}
          clusteripport: {{ orderer.metrics.clusteripport }}
{% else %}
          clusteripport: 9443
{% endif %}

    vault:
      address: {{ vault.url }}
      role: vault-role
      authpath: {{ network.env.type }}{{ namespace }}-auth
      secretprefix: {{ vault.secret_path | default('secret') }}/crypto/ordererOrganizations/{{ namespace }}/orderers/{{ orderer.name }}.{{ namespace }}
      imagesecretname: regcred
      serviceaccountname: vault-auth
{% if orderer.consensus == 'kafka' %}
    kafka:
      readinesscheckinterval: 10
      readinessthreshold: 10
      brokers:
{% for i in range(consensus.replicas) %}
      - {{ consensus.name }}-{{ i }}.{{ consensus.type }}.{{ namespace }}.svc.cluster.local:{{ consensus.grpc.port }}
{% endfor %}
{% endif %}

    proxy:
      provider: {{ network.env.proxy }}
      external_url_suffix: {{ item.external_url_suffix }}

    genesis: |-
{{ genesis | indent(width=6, first=True) }}
