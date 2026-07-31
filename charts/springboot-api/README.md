# springboot-api

简单版 Spring Boot Helm chart，默认生成三个资源：

- `Deployment`
- `Service`
- `HTTPRoute`
- 可选 `ServiceMonitor`

默认容器端口和 Service 端口都是 `8080`。日常只需要改镜像和域名：

```bash
helm install my-api ./charts/springboot-api \
  --set image.repository=192.168.50.18:5000/my-api \
  --set image.tag=1.0.0 \
  --set route.hostname=api.example.com
```

## values.yaml

```yaml
replicaCount: 1

image:
  repository: 192.168.50.18:5000/API-NAME
  tag: "TAG"
  pullPolicy: Always

container:
  port: 8080

env:
  - name: SPRING_PROFILES_ACTIVE
    value: prod

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: "1"
    memory: 1Gi

probes:
  enabled: true
  path: /actuator/health
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3

otelJavaAgent:
  enabled: true
  serviceName: my-api
  collector:
    endpoint: http://opentelemetry-collector.observability.svc.cluster.local:4317
    protocol: grpc
  exporters:
    traces: otlp
    metrics: otlp
    logs: otlp
  logCorrelation:
    enabled: true
    patternLevel: "%5p [trace_id=%X{trace_id:-},span_id=%X{span_id:-}]"
  resourceAttributes: ""
  image:
    repository: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java
    tag: latest
    pullPolicy: IfNotPresent
  sourcePath: /javaagent.jar
  mountPath: /otel-auto-instrumentation
  fileName: javaagent.jar
  javaToolOptions: ""
  resources: {}

service:
  port: 8080
  annotations: {}

prometheus:
  path: /actuator/prometheus
  port: http
  interval: 30s
  scrapeTimeout: 10s
  scheme: http
  annotations:
    enabled: false
  serviceMonitor:
    enabled: true
    namespace: ""
    namespaceSelector: {}
    labels: {}
    annotations: {}
    relabelings: []
    metricRelabelings: []

route:
  enabled: true
  gatewayName: traefik-gateway
  gatewayNamespace: kube-system
  hostname: HOSTNAME
  path: /
```

## 常用覆盖

开启 Spring Boot 健康检查：

```bash
helm upgrade --install my-api ./charts/springboot-api \
  --set probes.enabled=true
```

开启 Prometheus Operator 的 `ServiceMonitor`：

```bash
helm upgrade --install my-api ./charts/springboot-api \
  --set prometheus.serviceMonitor.enabled=true
```

如果应用像 `one-click-deploy` 一样暴露 `/api/metrics`：

```bash
helm upgrade --install my-api ./charts/springboot-api \
  --set prometheus.serviceMonitor.enabled=true \
  --set prometheus.path=/api/metrics
```

开启 OpenTelemetry Java Agent：

```bash
helm upgrade --install my-api ./charts/springboot-api \
  --set otelJavaAgent.enabled=true \
  --set otelJavaAgent.serviceName=my-api
```

开启后，chart 会同时设置 Logback MDC 关联日志，业务请求日志里会出现类似：

```text
INFO [trace_id=...,span_id=...] ... ItemService.list page=35 size=10 totalElements=6420
```

注意：应用启动阶段的日志通常还没有请求 span，所以启动日志里没有 traceId 是正常的；访问接口后的业务日志才应该带 traceId。

开启后 chart 会增加一个 init container，把 `/javaagent.jar` 复制到共享的 `emptyDir`，并给应用容器注入：

```yaml
JAVA_TOOL_OPTIONS: -javaagent:/otel-auto-instrumentation/javaagent.jar
```

如果集群使用传统 Prometheus 注解抓取，也可以只打开 Service 注解：

```bash
helm upgrade --install my-api ./charts/springboot-api \
  --set prometheus.annotations.enabled=true
```

不需要 Gateway API 路由时可以关闭 `HTTPRoute`：

```bash
helm upgrade --install my-api ./charts/springboot-api \
  --set route.enabled=false
```
