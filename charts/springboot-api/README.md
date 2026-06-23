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

service:
  port: 8080

route:
  gatewayName: traefik-gateway
  gatewayNamespace: kube-system
  hostname: HOSTNAME
  path: /
```
