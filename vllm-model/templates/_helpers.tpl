{{- define "vllm-model.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "vllm-model.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "vllm-model.namespace" -}}
{{- if .Values.namespaceOverride -}}
{{- .Values.namespaceOverride -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{- define "vllm-model.labels" -}}
app.kubernetes.io/name: {{ include "vllm-model.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "vllm-model.selectorLabels" -}}
app: {{ include "vllm-model.fullname" . }}
{{- end -}}

{{- define "vllm-model.gpuCount" -}}
{{- with .Values.resources -}}
{{- with .limits -}}
{{- index . "nvidia.com/gpu" | default "" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return PVC name for a volume item.
If pvc.name is set, use it.
Otherwise use <release-fullname>-<volume-name>.
*/}}
{{- define "vllm-model.pvcName" -}}
{{- $root := index . 0 -}}
{{- $volume := index . 1 -}}
{{- if $volume.pvc.name -}}
{{- $volume.pvc.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "vllm-model.fullname" $root) $volume.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
