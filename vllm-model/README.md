# vllm-model Helm Chart

A lightweight Helm chart to deploy a single **vLLM OpenAI-compatible server** (one model per release) on Kubernetes.  
Optimized for GPU workloads and GitOps workflows (Flux HelmRelease friendly).

[![Publish vllm-model Helm chart to GHCR](https://github.com/qosikz/charts-public/actions/workflows/publish-vllm-model.yaml/badge.svg)](https://github.com/qosikz/charts-public/actions/workflows/publish-vllm-model.yaml)

---

## What this chart deploys

- **Deployment** (one vLLM instance, configurable replicas)
- **Service** (default: `LoadBalancer`, port `8000`)
- Optional behavior:
  - Private registry image pull secrets
  - PVC, HostPath, emptyDir, ConfigMap and Secret volumes
  - Startup/Liveness probes
  - Soft replica spreading across nodes via `topologySpreadConstraints`
  - Ingress

---

## Prerequisites

- Kubernetes cluster
- (Optional/Typical) GPU nodes + NVIDIA device plugin if you request `nvidia.com/gpu`
- (Optional) A Kubernetes Secret with HuggingFace token if the model requires it

Example:
```bash
kubectl -n <namespace> create secret generic hf-token --from-literal=hf_token="<YOUR_HF_TOKEN>"
```
---

## Installation

### Helm CLI (quick start)

```bash
helm install qwen-8b . -n <namespace> --create-namespace \
  --set replicaCount=1 \
  --set 'args[0]=--model' \
  --set 'args[1]=Qwen/Qwen3-8B' \
  --set 'resources.limits.cpu=8' \
  --set 'resources.limits.memory=32Gi' \
  --set 'resources.limits.nvidia\.com/gpu=1'
```

### Upgrade

```bash
helm upgrade qwen-8b . -n <namespace> -f values-qwen-8b.yaml
```

---

## Flux usage (recommended pattern)

Use one HelmRelease per model, each with its own values file.

High-level idea:
- GitRepository points to the repo containing the chart
- HelmRelease references the chart from GitRepository
- Model-specific configuration lives in HelmRelease.spec.values or values-\<model\>.yaml

---

## Configuration

### Default values

| Name | Description | Value |
| ---- | ----------- | ----- |
| namespaceOverride | Override namespace used for rendered resources. If empty, uses release namespace. | "" |
| replicaCount | Number of replicas for the Deployment. | 1 |
| nameOverride | Override chart name used in resource naming helpers. | "" |
| fullnameOverride | Override full resource name. | "" |
| image.repository | Container image repository. | vllm/vllm-openai |
| image.tag | Container image tag. | v0.14.1 |
| image.pullPolicy | Kubernetes image pull policy. | IfNotPresent |
| imagePullSecrets | Kubernetes image pull secrets for private registries. | [] |
| args | Container args. | [] |
| command | Container command. | [] |
| env.enabled | Enable container environment variables. | false |
| env.items | Environment variables rendered into the container. | [] |
| podAnnotations | Annotations applied to pod template metadata. | {prometheus.io/scrape: "true"} |
| containerPort | Container port exposed by vLLM. | 8000 |
| volumes.enabled | Enable pod volumes and PVC rendering. | false |
| volumes.items | Pod volumes. Supports pvc, hostPath, emptyDir, configMap, secret and persistentVolumeClaim. | [] |
| volumeMounts.enabled | Enable container volume mounts. | false |
| volumeMounts.items | Container volume mounts. | [] |
| probes.startup.enabled | Enable startup probe. | true |
| probes.startup.path | Startup probe HTTP path. | /health |
| probes.startup.port | Startup probe port. | 8000 |
| probes.startup.periodSeconds | Startup probe period. | 5 |
| probes.startup.timeoutSeconds | Startup probe timeout. | 2 |
| probes.startup.failureThreshold | Startup probe failure threshold. | 360 |
| probes.liveness.enabled | Enable liveness probe. | true |
| probes.liveness.path | Liveness probe HTTP path. | /health |
| probes.liveness.port | Liveness probe port. | 8000 |
| probes.liveness.periodSeconds | Liveness probe period. | 20 |
| probes.liveness.timeoutSeconds | Liveness probe timeout. | 3 |
| probes.liveness.failureThreshold | Liveness probe failure threshold. | 3 |
| resources | Container resources (CPU/memory/GPU). Must be set for GPU workloads. | {} |
| tolerations | Pod tolerations for scheduling onto GPU nodes. | [{key: gpu, operator: Exists, effect: NoSchedule}] |
| nodeSelector | Node selector for targeting specific nodes. | {} |
| scheduling.spread.enabled | Enable topology spread constraints. | false |
| scheduling.spread.topologyKey | Topology key to spread across (nodes by default). | kubernetes.io/hostname |
| scheduling.spread.maxSkew | Maximum skew allowed between topology domains. | 1 |
| scheduling.spread.whenUnsatisfiable | Spread behavior when constraints can’t be satisfied (ScheduleAnyway = soft, DoNotSchedule = strict). | ScheduleAnyway |
| podSecurityContext.enabled | Enable Pod-level securityContext (applies to the whole Pod). | false |
| podSecurityContext.runAsUser | UID to run all containers in the Pod as (unless overridden at container level). | |
| podSecurityContext.runAsGroup | GID to run all containers in the Pod as (unless overridden at container level). | |
| podSecurityContext.fsGroup | Filesystem group ID applied to mounted volumes (helps with write permissions on volumes). | |
| podSecurityContext.fsGroupChangePolicy | Controls when Kubernetes changes volume ownership/permissions (OnRootMismatch is usually best). |  |
| podSecurityContext.runAsNonRoot | Enforce running as a non-root user. | |
| podSecurityContext.supplementalGroups | Additional group IDs added to the process (useful for shared volume permissions). | |
| containerSecurityContext.enabled | Enable container-level securityContext (applies only to the main container). | false |
| containerSecurityContext.allowPrivilegeEscalation | Allow privilege escalation in the container. | |
| containerSecurityContext.readOnlyRootFilesystem | Mount the container root filesystem as read-only. | |
| containerSecurityContext.runAsUser | UID to run the container as (overrides podSecurityContext.runAsUser for this container). | |
| containerSecurityContext.runAsGroup | GID to run the container as (overrides podSecurityContext.runAsGroup for this container). | |
| containerSecurityContext.capabilities.drop | Linux capabilities to drop (e.g. ["ALL"]). | |

### Service values

| Name | Description | Value |
| ---- | ----------- | ----- |
| service.enabled | Create Service. | true |
| service.type | Kubernetes Service type. | LoadBalancer |
| service.port | Service port. | 8000 |
| service.targetPort | Service target port. | 8000 |
| service.protocol | Service protocol. | TCP |
| service.loadBalancerIP | Requested static LB IP (depends on LB implementation, e.g. kube-vip). | "" |
| service.annotations | Service annotations. | {prometheus.io/scrape: "true"} |
| service.labels | Extra labels applied to the Service. | {type: vllm} |

### Ingress values

| Name | Description | Value |
| ---- | ----------- | ----- |
| ingress.enabled | Create Ingress. Requires service.enabled=true. | false |
| ingress.className | IngressClass name. | "" |
| ingress.annotations | Ingress annotations. | {} |
| ingress.hosts | Ingress hosts and paths. | [] |
| ingress.tls | Ingress TLS configuration. | [] |
