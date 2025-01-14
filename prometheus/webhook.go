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