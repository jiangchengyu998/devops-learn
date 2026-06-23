# generic-api

最小通用 Helm chart，只生成三个资源：

- `Deployment`
- `Service`
- `HTTPRoute`

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

service:
  port: 80

route:
  gatewayName: traefik-gateway
  gatewayNamespace: kube-system
  hostname: api.example.com
  path: /
```
