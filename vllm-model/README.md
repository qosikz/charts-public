# vllm-model Helm Chart

A lightweight Helm chart to deploy a single **vLLM OpenAI-compatible server** (one model per release) on Kubernetes.  
Optimized for GPU workloads and GitOps workflows (Flux HelmRelease friendly).

---

## What this chart deploys

- **Deployment** (one vLLM instance, configurable replicas)
- **Service** (default: `LoadBalancer`, port `8000`)
- Optional behavior:
  - HostPath volume for HuggingFace cache
  - Startup/Liveness probes
  - Soft replica spreading across nodes via `topologySpreadConstraints`

---

## Prerequisites

- Kubernetes cluster
- (Optional/Typical) GPU nodes + NVIDIA device plugin if you request `nvidia.com/gpu`
- A Kubernetes Secret with HuggingFace token (default: `hf-token`, key: `hf_token`)

Example:
```bash
kubectl -n <namespace> create secret generic hf-token --from-literal=hf_token="<YOUR_HF_TOKEN>"
```
---

## Installation

### Helm CLI (quick start)

```bash
helm install qwen-8b . -n <namespace> --create-namespace \
  --set model="Qwen/Qwen3-8B" \
  --set replicaCount=1
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
| image.tag | Container image tag. | v0.13.0 |
| image.pullPolicy | Kubernetes image pull policy. | IfNotPresent |
| model | Required. Model identifier (e.g., Qwen/Qwen3-8B). | "" |
| extraArgs | Additional CLI args appended after model. | [] |
| env.enabled | Enable env | false |
| env.items| Secret key for HuggingFace token. | [] |
| podAnnotations | Annotations applied to pod template metadata. | {prometheus.io/scrape: "true"} |
| containerPort | Container port exposed by vLLM. | 8000 |
| volumes.enabled | Enable volume. | true |
| volumes.items | Volume name. | [] |
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
