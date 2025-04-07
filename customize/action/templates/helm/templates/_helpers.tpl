{{/*
Expand the name of the chart.
*/}}
{{- define "helm-chart.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm-chart.fullname" -}}
{{- if .Chart.name }}
{{- .Chart.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm-chart.labels" -}}
helm.sh/chart: {{ include "helm-chart.chart" . }}
{{ include "helm-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "helm-chart.maintainers" . }}
{{- end }}

{{/*
Selector labels maintainers
*/}}
{{- define "helm-chart.maintainers" -}}
{{- with index .Chart.Maintainers 0 -}}
app.kubernetes.io/maintainer-name: {{ .Name | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create container exposed ports for deployment
*/}}
{{- define "helpers.list-additional-container-ports"}}
{{- if .Values.##ENVIORNMENT_STAGE## }}
{{- if .Values.##ENVIORNMENT_STAGE##.additionalPorts }}
{{- range $key, $val := .Values.##ENVIORNMENT_STAGE##.additionalPorts }}
- name: {{ $key }}
  containerPort: {{ $val }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create container exposed ports for service
*/}}
{{- define "helpers.list-additional-service-ports"}}
{{- if .Values.##ENVIORNMENT_STAGE## }}
{{- if .Values.##ENVIORNMENT_STAGE##.additionalPorts }}
{{- range $key, $val := .Values.##ENVIORNMENT_STAGE##.additionalPorts }}
- name: {{ $key }}
  port: {{ $val }}
  targetPort: {{ $key }}
  protocol: TCP    
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "helm-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create env cm variables for different env
*/}}
{{- define "helpers.include-envfrom" }}
  {{- if .Values.##ENVIORNMENT_STAGE## }}
    {{- $envs := .Values.##ENVIORNMENT_STAGE##.env }}
    {{- $secrets := .Values.##ENVIORNMENT_STAGE##.secrets }}
    {{- if or $envs $secrets }}
envFrom:
      {{- if $envs }}
  - configMapRef:
      name: ##APPLICATION_NAME##-configmap
      {{- end }}
      {{- if $secrets }}
  - secretRef:
      name: ##APPLICATION_NAME##-secrets
      {{- end }}
    {{- end }}
  {{- else if or .Values.envFromConfigMap .Values.envFromSecrets }}
    {{- $envFromConfigMap := .Values.envFromConfigMap }}
    {{- $envFromSecrets := .Values.envFromSecrets }}
    {{- if or $envFromConfigMap $envFromSecrets }}
envFrom:
      {{- if $envFromConfigMap }}
        {{- $configMaps := splitList "," $envFromConfigMap -}}
        {{- range $index, $configMap := $configMaps -}} 
        {{- "\n" -}}
  - configMapRef:
      name: {{ $configMap | trim }}
        {{- end -}}
      {{- end }}
      {{- if $envFromSecrets }}
        {{- $secrets := splitList "," $envFromSecrets -}}
        {{- range $index, $secret := $secrets -}} 
        {{- "\n" -}}
  - secretRef:
      name: {{ $secret | trim }}
        {{- end -}}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}



{{/*
Create env secret variables for secrets
*/}}
{{- define "helpers.env-secrets"}}
{{- if .Values.##ENVIORNMENT_STAGE## }}
{{- if .Values.##ENVIORNMENT_STAGE##.secrets }}
{{- range $key, $val := .Values.##ENVIORNMENT_STAGE##.secrets }}
  {{ $key }}: "{{ $val | b64enc }}"
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create env variables for config map
*/}}
{{- define "helpers.env-configmap"}}
{{- if .Values.##ENVIORNMENT_STAGE## }}
{{- if .Values.##ENVIORNMENT_STAGE##.env }}
{{- range $key, $val := .Values.##ENVIORNMENT_STAGE##.env }}
  {{ $key }}: "{{ $val }}"
{{- end }}
{{- end }}
{{- end }}
{{- end }}
