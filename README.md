# devops-learn

个人 DevOps 学习与实验仓库，主要记录 Linux、Docker、Jenkins、Kubernetes、Helm、Traefik、Prometheus、Tailscale 等工具的部署实践和常用命令。

## 目录导览

| 路径 | 内容 |
| --- | --- |
| [docs/base-ops.md](docs/base-ops.md) | 原 README 中的基础运维笔记：Docker、yum 源、Jenkins、SonarQube 等 |
| [Linux/](Linux/) | Linux 常用命令与 Ubuntu 记录 |
| [charts/](charts/) | 可复用 Helm chart 示例 |
| [prometheus/](prometheus/) | Prometheus、Alertmanager、Grafana、Webhook 示例与启动脚本 |
| [traefix/](traefix/) | Traefik Gateway API 配置 |
| [tailscale/](tailscale/) | Tailscale DERP 与证书相关笔记 |
| [freestyle_job/](freestyle_job/) | Jenkins freestyle job 配置截图与说明 |
| [pipeline_job/](pipeline_job/) | Jenkins pipeline 相关笔记 |
| [one_key_deploy/](one_key_deploy/) | 常用部署和 Docker 命令 |
| [avatar1/](avatar1/) | Avatar 相关素材和记录 |

## 快速开始

### Helm chart 渲染

```bash
helm template demo-generic ./charts/generic-api \
  --set image.repository=registry.example.com/demo \
  --set image.tag=1.0.0 \
  --set route.hostname=demo.example.com

helm template demo-springboot ./charts/springboot-api \
  --set image.repository=registry.example.com/spring-demo \
  --set image.tag=1.0.0 \
  --set route.hostname=spring.example.com
```

### Prometheus 本地示例

```bash
cd prometheus
go run ./cmd/metrics-demo
go run ./cmd/webhook
```

默认端口：

| 服务 | 地址 |
| --- | --- |
| metrics-demo | `http://127.0.0.1:8090/ping`、`/metrics` |
| webhook | `http://127.0.0.1:8081/webhook` |

### Prometheus 一键脚本

脚本默认使用 `/data/services` 保存日志和 PID，可通过环境变量覆盖：

```bash
cd prometheus
BASE_DIR=/tmp/devops-services SERVICE_HOST=127.0.0.1 ./start_services.sh
./stop_services.sh
```

常用环境变量：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `BASE_DIR` | `/data/services` | 日志、PID、Prometheus 数据目录根路径 |
| `SERVICE_HOST` | `192.168.101.102` | Web URL 和 Prometheus 抓取示例使用的主机 |
| `GRAFANA_HOME` | `/usr/local/grafana-v11.4.0` | Grafana 安装目录 |
| `WEBHOOK_ADDR` | `:8081` | Webhook 示例监听地址 |
| `METRICS_ADDR` | `:8090` | metrics-demo 示例监听地址 |

## 维护约定

- 新增笔记优先放到对应主题目录，根 README 只保留导航和最常用入口。
- 示例配置尽量使用占位符或环境变量，避免把本机 IP、密码和路径散落在多个文件里。
- Shell 脚本保持可重复执行；涉及后台进程时写入 PID 文件并提供停止脚本。
- Helm chart 默认值保持最小可运行，生产参数通过 `values.yaml` 覆盖。

