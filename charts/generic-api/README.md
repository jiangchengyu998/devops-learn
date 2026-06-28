# generic-api

最小通用 Helm chart，默认生成三个资源：

- `Deployment`
- `Service`
- `HTTPRoute`
- 可选 `ServiceMonitor`

镜像默认监听容器端口 `80`。日常只需要改镜像和域名：

```bash
helm install my-api ./charts/generic-api \
  --set image.repository=registry.example.com/my-api \
  --set image.tag=1.0.0 \
  --set route.hostname=api.example.com
```

## values.yaml

```yaml
replicaCount: 1

image:
  repository: registry.example.com/my-api
  tag: "1.0.0"
  pullPolicy: IfNotPresent

container:
  port: 80

env:
  - name: APP_ENV
    value: prod

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 500m
    memory: 512Mi

service:
  port: 80
  annotations: {}

prometheus:
  path: /metrics
  port: http
  interval: 30s
  scrapeTimeout: 10s
  scheme: http
  annotations:
    enabled: false
  serviceMonitor:
    enabled: false
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
  hostname: api.example.com
  path: /
```

## 常用覆盖

开启 Prometheus Operator 的 `ServiceMonitor`：

```bash
helm install my-api ./charts/generic-api \
  --set prometheus.serviceMonitor.enabled=true
```

如果应用像 `one-click-deploy` 一样暴露 `/api/metrics`：

```bash
helm install my-api ./charts/generic-api \
  --set prometheus.serviceMonitor.enabled=true \
  --set prometheus.path=/api/metrics
```

如果集群使用传统 Prometheus 注解抓取，也可以只打开 Service 注解：

```bash
helm install my-api ./charts/generic-api \
  --set prometheus.annotations.enabled=true
```

不需要 Gateway API 路由时可以关闭 `HTTPRoute`：

```bash
helm install my-api ./charts/generic-api \
  --set route.enabled=false
```
