{{- define "springboot-api.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "springboot-api.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "springboot-api.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "springboot-api.labels" -}}
app.kubernetes.io/name: {{ include "springboot-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "springboot-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "springboot-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
