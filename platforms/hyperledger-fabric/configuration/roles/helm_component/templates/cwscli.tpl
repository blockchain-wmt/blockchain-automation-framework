apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: {{ component_name }}-cwscli
  namespace: {{ component_name }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ component_name }}-cwscli
  chart:
    git: {{ git_url }}
    ref: {{ git_branch }}
    path: {{ charts_dir }}/cwscli
  values:
    metadata:
      namespace: {{ component_name }}
      name: cwscli

    replicaCount: 1

    image:
      repository: docker.prod.walmart.com/blockchain/wbp-proxy-ca
      tag: 0.0.1
      pullPolicy: IfNotPresent
      
    storage:
      storageclassname: {{ component | lower }}sc
      storagesize: 512Mi
