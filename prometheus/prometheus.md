# 简介
Prometheus 是一个开源监控系统，用于收集、存储和监控时间序列数据。它使用 HTTP 协议进行通信，并支持多种数据格式，如 Prometheus 自定义格式、OpenMetrics、InfluxDB 格式等。
alertmanager 是 Prometheus 的报警组件，用于接收来自 Prometheus 的报警信息，并进行报警处理。
node-exporter 是 Prometheus 的节点监控组件，用于监控主机的系统资源、进程、网络等指标。
其他应用程序可以提供数据给prometheus, prometheus会收集这些数据并保存到prometheus中。
grafana 是一个开源的监控可视化工具，用于展示 Prometheus 收集的数据。它提供了丰富的图表和仪表板，用于监控应用程序、服务器、网络等。

