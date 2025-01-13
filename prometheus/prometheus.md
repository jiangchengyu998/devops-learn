# 简介
Prometheus 是一个开源监控系统，用于收集、存储和监控时间序列数据。它使用 HTTP 协议进行通信，并支持多种数据格式，如 Prometheus 自定义格式、OpenMetrics、InfluxDB 格式等。

alertmanager 是 Prometheus 的报警组件，用于接收来自 Prometheus 的报警信息，并进行报警处理。

node-exporter 是 Prometheus 的节点监控组件，用于监控主机的系统资源、进程、网络等指标。

其他应用程序可以提供数据给prometheus, prometheus会收集这些数据并保存到prometheus中。

grafana 是一个开源的监控可视化工具，用于展示 Prometheus 收集的数据。它提供了丰富的图表和仪表板，用于监控应用程序、服务器、网络等。

# 安装 Prometheus
```shell
wget https://github.com/prometheus/prometheus/releases/download/v2.53.3/prometheus-2.53.3.linux-amd64.tar.gz
tar -zxvf prometheus-2.53.3.linux-amd64.tar.gz
cp prometheus-2.53.3.linux-amd64/prometheus /usr/local/bin/
prometheus --config.file=prometheus.yml --storage.tsdb.path=/data/prometheus --web.listen-address=0.0.0.0:9090 --web.external-url=http://192.168.101.102:9090
```
prometheus.yml  
```yaml
global:
  scrape_interval: 1s
  evaluation_interval: 1s
rule_files:
  - rules.yml
alerting:
  alertmanagers:
  - static_configs:
    - targets:
       - 192.168.101.102:9093

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["192.168.101.102:9090"]
  - job_name: simple_server
    static_configs:
      - targets: ["192.168.101.102:8090"]
  - job_name: node_exporter
    static_configs:
      - targets: ["192.168.101.102:9100"]
  - job_name: 'spring-boot-app'
    metrics_path: '/actuator/prometheus'  # Spring Boot 暴露的 Prometheus 路径
    static_configs:
      - targets: ['192.168.101.102:8082']  # 替换为你的 Spring Boot 应用地址
  - job_name: 'spring-boot-app-1'
    metrics_path: '/actuator/prometheus'  # Spring Boot 暴露的 Prometheus 路径
    static_configs:
      - targets: ['192.168.101.102:8083']  # 替换为你的 Spring Boot 应用地址
```

# 安装 node-exporter

这个会通过9100端口上报数据给Prometheus
```shell
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar -zxvf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
node_exporter --web.listen-address=0.0.0.0:9100
```

# 使用go写一个prometheus client 添加这个指标ping_request_count
server.go
```go
package main

import (
   "fmt"
   "net/http"

   "github.com/prometheus/client_golang/prometheus"
   "github.com/prometheus/client_golang/prometheus/promhttp"
)

var pingCounter = prometheus.NewCounter(
   prometheus.CounterOpts{
       Name: "ping_request_count",
       Help: "No of request handled by Ping handler",
   },
)

func ping(w http.ResponseWriter, req *http.Request) {
   pingCounter.Inc()
   fmt.Fprintf(w, "pong")
}

func main() {
   prometheus.MustRegister(pingCounter)

   http.HandleFunc("/ping", ping)
   http.Handle("/metrics", promhttp.Handler())
   http.ListenAndServe(":8090", nil)
}
```
启动server.go
```shell
go mod init prom_example
go mod tidy
go run server.go  # 第二次启动只需执行这个命令
```

# 使用go编写一个webhook
main.go
```go
package main

import (
        "fmt"
        "io/ioutil"
        "log"
        "net/http"
)

// WebhookHandler 处理 Alertmanager 的 Webhook 请求
func WebhookHandler(w http.ResponseWriter, r *http.Request) {
        // 只处理 POST 请求
        if r.Method != http.MethodPost {
                http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
                return
        }

        // 读取请求体
        body, err := ioutil.ReadAll(r.Body)
        if err != nil {
                http.Error(w, "Failed to read request body", http.StatusInternalServerError)
                return
        }
        defer r.Body.Close()

        // 打印接收到的请求体（即报警通知数据）
        fmt.Println("Received Webhook request:")
        fmt.Println(string(body))

        // 响应 Alertmanager 的请求
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("Webhook received successfully"))
}

func main() {
        // 设置 Webhook 路由
        http.HandleFunc("/webhook", WebhookHandler)

        // 启动服务器并监听请求
        port := ":8081"
        fmt.Printf("Starting server on port %s...\n", port)
        if err := http.ListenAndServe(port, nil); err != nil {
                log.Fatalf("Failed to start server: %v", err)
        }
}
```
启动
```shell
go run main.go
```


# 安装 alertmanager
```shell
wget https://github.com/prometheus/alertmanager/releases/download/v0.28.0-rc.0/alertmanager-0.28.0-rc.0.linux-amd64.tar.gz
tar -zxvf alertmanager-0.28.0-rc.0.linux-amd64.tar.gz
cp alertmanager-0.28.0-rc.0.linux-amd64/alertmanager /usr/local/bin/
alertmanager --config.file=alertmanager.yml --web.listen-address=0.0.0.0:9093 --web.external-url=http://192.168.101.102:9093
```
alertmanager.yml
```yaml
global:
  resolve_timeout: 10s
route:
  receiver: webhook_receiver
  group_interval: 10s
  repeat_interval: 10s
receivers:
    - name: webhook_receiver
      webhook_configs:
        - url: 'http://192.168.101.102:8081/webhook'
          send_resolved: false
```
rules.yml
```yaml
groups:
 - name: Request Spike Alert
   rules:
   - alert: RequestSpike
     expr: increase(ping_request_count[2s]) > 0
     for: 0s
     labels:
       severity: warning
     annotations:
       summary: "Request count spike detected"
       description: "The request count increased by more than 5 within 10 seconds. Current rate:"
```
# 安装 grafana
```shell
wget https://dl.grafana.com/oss/release/grafana-11.4.0.linux-amd64.tar.gz
tar -zxvf grafana-11.4.0.linux-amd64.tar.gz
cd grafana-11.4.0/bin/grafana-server/bin
./grafana-server
```
默认端口3000
在grafana中添加数据源，选择prometheus，地址为：http://192.168.101.102:9090

# 测试
test.sh
```shell
#!/bin/bash

for (( i=1;i<10000;i++ ));
do
  curl http://192.168.101.102:8090/ping
  # curl http://192.168.101.102:8082/hello
  # curl http://192.168.101.102:8083/hello
  echo ""
  echo "sleep 0.5s"
  sleep 0.1
done
```

