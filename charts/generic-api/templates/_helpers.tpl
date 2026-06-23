{{- define "generic-api.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "generic-api.fullname" -}}
{{- $name := include "generic-api.name" . -}}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "generic-api.labels" -}}
app.kubernetes.io/name: {{ include "generic-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "generic-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "generic-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
