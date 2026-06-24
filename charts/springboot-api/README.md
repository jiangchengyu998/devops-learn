# springboot-api

简单版 Spring Boot Helm chart，只生成三个资源：

- `Deployment`
- `Service`
- `HTTPRoute`

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

service:
  port: 8080

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

不需要 Gateway API 路由时可以关闭 `HTTPRoute`：

```bash
helm upgrade --install my-api ./charts/springboot-api \
  --set route.enabled=false
```
