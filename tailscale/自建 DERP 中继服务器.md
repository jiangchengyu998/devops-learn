# 提供方案二：自建 DERP 中继服务器的超级详细步骤。

这个过程需要一些 Linux 基础，但只要严格按照步骤操作，成功率很高。自建 DERP 是解决 Tailscale 国内访问速度慢的最有效方法。

# 准备工作
一台国内的云服务器：

推荐：阿里云、腾讯云、华为云的轻量应用服务器，性价比高。

核心要求：必须要有公网 IP！地域选择离你和目标用户较近的，如“华东-上海”。

配置：最低配置即可（1核1G，带宽 3-5Mbps 起步，按流量计费更划算）。系统选择 Ubuntu 20.04/22.04 或 Debian 11。

一个域名（可选但强烈推荐）：

你可以购买一个新域名，或者使用已有的任何域名。

它的作用是给中继服务器一个 SSL 证书，让连接更安全稳定。如果没有域名，只能用 IP 地址，步骤会复杂一些且安全性降低。

详细步骤
我们假设您的云服务器公网 IP 是 123.123.123.123，准备的域名是 derp.ydphoto.com（请务必替换成你自己的）。

# 第 1 步：服务器基础环境配置
登录服务器：
```shell
ssh root@123.123.123.123
```

更新系统并安装所需工具：
```shell
apt update && apt upgrade -y
apt install curl wget git -y
```
# 第 2 步：安装并配置 Tailscale
安装 Tailscale：

bash
```shell
curl -fsSL https://tailscale.com/install.sh | sh
```
启动 Tailscale 并登录：

bash
```shell
tailscale up
```
执行后，命令行会给出一个验证链接，复制它到浏览器中打开，用你的 Google/Github 等账号登录授权。

授权成功后，这台服务器就加入你的 Tailscale 网络了。记下它分配到的 Tailscale 内网 IP（例如 100.101.102.103）。

# 第 3 步：部署 DERP 服务器
我们将使用官方推荐的 Golang 方式运行。

安装 Go 语言环境：

bash
```shell
wget https://golang.org/dl/go1.21.4.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version # 检查安装是否成功
```
编译并运行 DERP：
可能要设置代理
bash
```shell
go install tailscale.com/cmd/derper@main
```
编译完成后，二进制文件会在 ~/go/bin/derper。

# 第 4 步：配置域名与 SSL 证书
解析域名：

到你的域名DNS管理后台（如阿里云解析、Cloudflare），添加一条 A 记录：

主机记录：derp (你的子域名)

记录值：123.123.123.123 (你的服务器公网IP)

获取 SSL 证书（使用 certbot）：

bash
# 安装 snapd 和 certbot(使用其他方式创建证书了 [证书创建.md](%E8%AF%81%E4%B9%A6%E5%88%9B%E5%BB%BA.md))
apt install snapd -y
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# 获取证书（会自动验证域名所有权并修改 Nginx 配置）
certbot certonly --standalone -d derp.ydphoto.com
按照提示操作，成功后证书会放在 /etc/letsencrypt/live/derp.ydphoto.com/ 目录下。

# 第 5 步：创建系统服务并启动
我们需要让 DERP 服务在后台稳定运行。

创建服务配置文件：

bash
```shell
vim /etc/systemd/system/derper.service
```
将以下内容复制进去（重要：修改 -hostname 为你的域名）：
old
```text
[Unit]
Description=Tailscale DERP Server
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/derper -a :443 \
    -c /root/derp-keys \
    -hostname derp.ydphoto.com \
    -http-port -1 \ # 关闭 HTTP 端口，强制使用 HTTPS
    -certmode manual \
    -certdir /etc/letsencrypt/live/derp.ydphoto.com/
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```
new
```text
[Unit]
Description=Tailscale DERP Server
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/derper -a :3443 \
    -c /root/derp-keys \
    -hostname derp.ydphoto.com \
    -http-port -1 \
    -certmode disabled 
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```
启动并启用服务：

bash
```shell
systemctl daemon-reload
systemctl enable derper
systemctl start derper
systemctl status derper # 检查状态，看到 active (running) 表示成功
```
systemctl daemon-reload
systemctl restart derper
systemctl status derper 

systemctl daemon-reload
systemctl restart derper
systemctl status derper # 检查状态，现在应该能正常启动了
journalctl -u derper -n 100 --no-pager

开放防火墙端口：

bash
## 开放 443 和 3478/UDP 端口（STUN 端口）
ufw allow 443/tcp
ufw allow 3478/udp
ufw reload
# 第 6 步：配置 Tailscale ACL，告诉客户端使用你的自建中继
这是最后一步，也是最关键的一步。

登录 Tailscale Admin 控制台：https://login.tailscale.com/admin/acls

找到你的 Access Controls 配置文件（ACL）。

在文件开头添加以下定义（告诉全局存在这个中继）：

json
```json
// 在 "acls" 数组之前添加
"derpMap": {
  "Regions": {
    "900": { // 900+ 是自定义区域ID，避免和官方（1-16）冲突
      "RegionID": 900,
      "RegionCode": "myderp",
      "RegionName": "My Shanghai DERP",
      "Nodes": [
        {
          "Name": "901",
          "RegionID": 900,
          "HostName": "derp.ydphoto.com",
          "IPv4": "8.138.212.208", // 你的服务器公网IP
          "DERPPort": 443,
        }
      ]
    }
  }
},
```
重要：如果之前有 "derpMap": {} 的配置，请用这个替换掉它。
（可选）强制客户端使用你的中继：
在 ACL 的 "acls" 部分，你可以添加策略，让特定设备优先使用你的中继。

json
```json
"acls": [ 
{
    "Action": "accept",
    "Users": ["*"],
    "Sources": ["*"],
    "Destinations": ["*:*"]
  }
],
```
保存配置。

验证是否成功
在客户端机器上执行诊断命令：

bash
```shell
tailscale netcheck
```
查看输出结果：

如果成功，你会在 Report: 部分看到类似 DERP 900: (myderp) ... 的字样，并且延迟是国内的水平（通常 < 50ms）。

如果还显示 DERP 1: (us-east) ... 且延迟很高，说明客户端还没切换过来。可以尝试重启客户端：tailscale down && tailscale up。

常见问题排查 (Troubleshooting)
netcheck 看不到自建 DERP：

检查 ACL 配置语法是否正确，JSON 格式不能有错误。

检查服务器 443 端口是否开放：telnet derp.ydphoto.com 443。

查看 DERP 服务日志：journalctl -u derper -f。

连接速度依然慢：

确保 netcheck 结果显示你确实连接到了自建 DERP（RegionID 900）。

检查云服务器的带宽是否跑满。

完成以上所有步骤后，你的所有 Tailscale 设备在无法直连时，都会通过你这台国内的服务器进行中转，速度将会得到巨大提升，延迟从之前的 200-300ms 降至 20-50ms，体验完全不同！

# nginx 的配置
```shell
vim /etc/nginx/sites-available/myapp.conf
```
old
```text
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ~^(.+)\.ydphoto\.com$; # 使用正则匹配所有子域名

    # 使用通配符证书，一劳永逸
    ssl_certificate /etc/ssl/ydphoto.com/fullchain.pem;
    ssl_certificate_key /etc/ssl/ydphoto.com/privkey.pem;

    # 根据不同的子域名，代理到不同的后端服务
    location / {
        if ($host = "www.ydphoto.com") {
            proxy_pass http://100.115.212.87:8929;
        }
        if ($host = "derp.ydphoto.com") {
            proxy_pass http://100.115.212.87:80;
        }
    }
}
```

new for derp
```text
# 配置块1：处理 DERP 服务的 HTTPS 流量
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name derp.ydphoto.com; # 关键：匹配DERP子域名

    # 使用 DERP 子域名的专属证书
    ssl_certificate /etc/ssl/ydphoto.com/fullchain.pem;
    ssl_certificate_key /etc/ssl/ydphoto.com/privkey.pem;

    location / {
        proxy_pass https://localhost:3443; # 转发给DERP服务
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 这些是 WebSocket 和 HTTP2 协议支持的重要设置，DERP 需要它们
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }
}

# 配置块2：处理您网站（WWW）的 HTTPS 流量
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.ydphoto.com; # 关键：匹配WWW子域名

    # 使用 WWW 子域名的专属证书
    ssl_certificate /etc/ssl/ydphoto.com/fullchain.pem;
    ssl_certificate_key /etc/ssl/ydphoto.com/privkey.pem;

    location / {
        proxy_pass http://100.115.212.87:8929; # 转发给您的网站服务（假设运行在8080端口）
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 可选：强制将HTTP流量重定向到HTTPS，提升安全性
server {
    listen 80;
    listen [::]:80;
    server_name derp.ydphoto.com www.ydphoto.com;

    # 将所有HTTP请求重写到HTTPS版本
    return 301 https://$host$request_uri;
}
```

```shell
systemctl reload nginx
```
systemctl daemon-reload
systemctl restart derper
systemctl status derper

tailscale down
tailscale up
tailscale netcheck
tailscale debug derp myderp


curl -k https://derp.ydphoto.com:3443/derpmap/local

nc -u 8.138.212.208 3478