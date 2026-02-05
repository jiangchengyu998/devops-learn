# devops-learn
https://learn.lianglianglee.com/

在 Alibaba Cloud Linux 3.2104 LTS 64位 系统上安装 Docker，可以按照以下步骤操作：

1. **卸载旧版本（如果有）**  
   ```bash
   sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
   ```

2. **安装依赖包**  
   ```bash
   sudo yum install -y yum-utils device-mapper-persistent-data lvm2
   ```

3. **添加 Docker 仓库**  
   ```bash
   sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
   ```

4. **安装 Docker**  
   ```bash
   sudo yum install -y docker-ce docker-ce-cli containerd.io
   ```

5. **启动 Docker 并设置开机自启**  
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

6. **验证 Docker 是否安装成功**  
   ```bash
   docker version
   ```

如需加速拉取镜像，可配置阿里云加速器。

这个仓库自己用来记录学习运维相关的知识的。

### 将 CentOS7 系统的 yum 镜像源替换为阿里云的镜像源

备份现有的仓库配置
```shell
sudo cp -r /etc/yum.repos.d /etc/yum.repos.d.bak
```

删除现有的仓库配置
```shell
sudo rm -f /etc/yum.repos.d/CentOS-Base.repo
sudo rm -f /etc/yum.repos.d/CentOS-CR.repo
sudo rm -f /etc/yum.repos.d/CentOS-Debuginfo.repo
sudo rm -f /etc/yum.repos.d/CentOS-fasttrack.repo
sudo rm -f /etc/yum.repos.d/CentOS-Media.repo
sudo rm -f /etc/yum.repos.d/CentOS-Sources.repo
sudo rm -f /etc/yum.repos.d/CentOS-Vault.repo
sudo rm -f /etc/yum.repos.d/CentOS-x86_64-kernel.repo
```

创建新的阿里云镜像源配置文件
```shell
sudo curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
```

清理并更新 YUM 缓存
```shell
sudo yum clean all
sudo yum makecache
```

验证更新
```shell
yum update
yum repolist
```

### 设置桥接虚拟机的固定IP和关闭防火墙
```shell
TYPE=Ethernet
BOOTPROTO=none
NAME=ens33
DEVICE=ens33
ONBOOT=yes
IPADDR=192.168.101.100
NETMASK=255.255.255.0
GATEWAY=192.168.101.1
DNS1=8.8.8.8
DNS2=8.8.4.4

sudo systemctl restart network


sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl status firewalld
```

### 给docker 设置代理
      - HTTP_PROXY=http://100.95.91.54:7890
      - HTTPS_PROXY=http://100.95.91.54:7890
      - NO_PROXY=localhost,127.0.0.1,100.64.0.0/10,.ydphoto.com
```shell
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<-'EOF'
[Service]
Environment="HTTP_PROXY=http://192.168.101.51:7890"
Environment="HTTPS_PROXY=http://192.168.101.51:7890"
Environment="NO_PROXY=localhost,127.0.0.1,100.64.0.0/10,192.168.101.0/24,.ydphoto.com"
EOF

systemctl daemon-reload
systemctl restart docker


```

设置docker 的配置文件
```shell
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://o240zio5.mirror.aliyuncs.com"]
}
EOF
sudo systemctl restart docker
```

### 如何安装 gitlab
docker-compose.yml
```yaml  
services:
  gitlab:
    image: 'gitlab/gitlab-ce:latest'
    container_name: gitlab
    restart: always
    user: root
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://192.168.101.511:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
    ports:
      - '8929:8929'
      - '2224:2224'
    volumes:
      - './config:/etc/gitlab'
      - './logs:/var/log/gitlab'
      - './data:/var/opt/gitlab'
```

将上面的文件放到gitlab 目录，执行下面的命令
```shell
 mkdir gitlab
 cd gitlab
 docker-compose up -d
 
 # 查看root 账户密码
 docker exec -it gitlab cat /etc/gitlab/initial_root_password
```

### tar.gz  文件解压
```shell
tar -zxvf filename.tar.gz
#解压的指定目录
tar -zxvf example.tar.gz -C /path/to/destination
```
解释：
z：表示通过 gzip 解压文件。
x：表示解压文件。
v：表示显示详细的解压过程。
f：表示后面跟的是文件名。


### 安装Jenkins

```shell
docker volume create jenkins-data
mkdir jenkins
cd jenkins
```

docker-compose.yml
```yaml
services:
   jenkins:
      image: jenkins/jenkins:jdk21
      container_name: jenkins
      user: root
      restart: always
      ports:
         - 8080:8080
         - 50000:50000
      volumes:
         - ./data/:/var/jenkins_home/
         - /var/run/docker.sock:/var/run/docker.sock
         - /usr/bin/docker:/usr/bin/docker
         - /usr/local/bin/aliyun:/usr/local/bin/aliyun
         - /root/.aliyun:/root/.aliyun
         - /etc/localtime:/etc/localtime:ro
         - /etc/timezone:/etc/timezone:ro
      environment:
         - JAVA_OPTS=-Xms1024m -Xmx4096m
      mem_limit: 4g
 
```

```shell

 docker-compose up -d
 
 # 查看root 账户密码
 docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

如果想要一些可执行软件在Jenkins里面执行，那就把可执行文件放到宿主机的 data 目录，例如
```shell
[root@localhost data]# ll | awk '$9 == "maven" || $9 == "sonar-scanner" || $9 == "jdk" {print $9}'
jdk
maven
sonar-scanner
```

插件下载慢，咋办？
```shell
# 修改数据卷中的hudson.model.UpdateCenter.xml文件
<?xml version='1.1' encoding='UTF-8'?>
<sites>
    <site>
        <id>default</id>
        <url>https://updates.jenkins.io/update-center.json</url>
    </site>
</sites>
# 将下载地址替换为http://mirror.esuni.jp/jenkins/updates/update-center.json
<?xml version='1.1' encoding='UTF-8'?>
<sites>
    <site>
        <id>default</id>
        <url>http://mirror.esuni.jp/jenkins/updates/update-center.json</url>
    </site>
</sites>
# 清华大学的插件源也可以
# https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json

```

### sonarqube 安装

```yaml
services:
  db:
    image: postgres
    container_name: db
    restart: always
    ports:
      - "5432:5432"
    networks:
      - sonarnet
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
  sonarqube:
    image: sonarqube:8.9.6-community
    container_name: sonarqube
    restart: always
    depends_on:
      - db
    ports:
      - "9000:9000"
    networks:
      - sonarnet
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
      HTTP_PROXY: http://192.168.101.51:7890
      HTTPS_PROXY: http://192.168.101.51:7890
      NO_PROXY: localhost,127.0.0.1,,192.168.101.0/24
networks:
  sonarnet:
    driver: bridge
```
修改内存大小
```shell
vim /etc/sysctl.conf
vm.max_map_count=262144
sysctl -p
```
启动
```shell
docker-compose up -d
# 默认的账号密码都是admin
# 生成了一个 token 
6da0d36ca3a51f8fa2fcad8cff37fd474f2d1a77
```

### 卸载docker
```shell
sudo systemctl stop docker
sudo systemctl disable docker
sudo yum remove docker docker-common docker-snapshot docker-engine
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
sudo rm -rf /var/run/docker
rm -rf /var/log/docker
yum remove docker-buildx-plugin docker-compose-plugin -y 
yum remove docker-ce docker-ce-cli containerd.io -y 
sudo yum autoremove -y 
reboot 
docker --version
```

```shell
ssh-keyscan -p 22 8.138.212.208 >> /var/jenkins_home/.ssh/known_hosts

```


```java
import org.apache.hc.client5.http.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.client5.http.impl.io.PoolingHttpClientConnectionManager;
import org.apache.hc.client5.http.impl.io.PoolingHttpClientConnectionManagerBuilder;
import org.apache.hc.client5.http.ssl.NoopHostnameVerifier;
import org.apache.hc.client5.http.ssl.SSLConnectionSocketFactory;
import org.apache.hc.client5.http.ssl.TrustAllStrategy;
import org.apache.hc.core5.ssl.SSLContextBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

import javax.net.ssl.SSLContext;

@Configuration
public class RestTemplateConfig {

    @Bean
    public RestTemplate restTemplate() throws Exception {

        // 1. 信任所有证书
        SSLContext sslContext = SSLContextBuilder.create()
                .loadTrustMaterial(null, TrustAllStrategy.INSTANCE)
                .build();

        // 2. SSL Socket Factory（不校验 hostname）
        SSLConnectionSocketFactory sslSocketFactory =
                new SSLConnectionSocketFactory(
                        sslContext,
                        NoopHostnameVerifier.INSTANCE
                );

        // 3. 关键点：通过 ConnectionManager 注入
        PoolingHttpClientConnectionManager connectionManager =
                PoolingHttpClientConnectionManagerBuilder.create()
                        .setSSLSocketFactory(sslSocketFactory)
                        .build();

        // 4. 构建 HttpClient
        CloseableHttpClient httpClient = HttpClients.custom()
                .setConnectionManager(connectionManager)
                .build();

        // 5. RestTemplate
        HttpComponentsClientHttpRequestFactory requestFactory =
                new HttpComponentsClientHttpRequestFactory(httpClient);

        return new RestTemplate(requestFactory);
    }
}



```
-XX:+UseG1GC
-Xlog:gc*,gc+heap=info:stdout:time,uptime,level,tags


好，这个切入点**非常专业** 👍
一句先给你结论：

> **jq ≈ JSON 世界里的 SQL + awk + sed（合体版）**
> 如果你会 SQL，用 jq 会非常快上手。

下面我用 **「SQL → jq」一一对照**，全部配 **k8s 实战 JSON**，你可以直接 copy 用。

---

## 一、整体心智模型对照（先立住）

| SQL       | jq               |   |
| --------- | ---------------- | - |
| 表（table）  | JSON 数组          |   |
| 行（row）    | 数组里的对象           |   |
| 列（column） | 对象字段             |   |
| SELECT    | `.` / 管道 `       | ` |
| WHERE     | `select()`       |   |
| FROM      | 输入流              |   |
| JOIN      | 手动（map / reduce） |   |
| GROUP BY  | `group_by()`     |   |
| COUNT     | `length`         |   |
| ORDER BY  | `sort_by()`      |   |

👉 **jq 是“流式 SQL”**，不是声明式

---

## 二、SELECT：取字段

### SQL

```sql
SELECT name, podIP FROM pods;
```

### jq（kubectl）

```bash
kubectl get pods -o json \
| jq '.items[] | {name: .metadata.name, ip: .status.podIP}'
```

输出：

```json
{
  "name": "nginx",
  "ip": "10.244.1.12"
}
```

👉 `.items[]` ≈ **FROM pods**

---

### 只要值（像 SQL 返回列）

```bash
jq -r '.items[] | "\(.metadata.name) \(.status.podIP)"'
```

---

## 三、WHERE：条件过滤（最爽的地方）

### SQL

```sql
SELECT name FROM pods WHERE phase = 'Running';
```

### jq

```bash
jq -r '.items[]
  | select(.status.phase=="Running")
  | .metadata.name'
```

📌 `select()` 就是 jq 的 WHERE

---

### 多条件 WHERE

```sql
WHERE phase='Running' AND node='node-1'
```

```bash
jq '.items[]
  | select(.status.phase=="Running" and .spec.nodeName=="node-1")
  | .metadata.name'
```

---

## 四、COUNT / 聚合

### SQL

```sql
SELECT COUNT(*) FROM pods;
```

### jq

```bash
jq '.items | length'
```

---

### 按状态统计（GROUP BY）

### SQL

```sql
SELECT phase, COUNT(*)
FROM pods
GROUP BY phase;
```

### jq

```bash
jq '.items
  | group_by(.status.phase)
  | map({phase: .[0].status.phase, count: length})'
```

输出：

```json
[
  { "phase": "Pending", "count": 1 },
  { "phase": "Running", "count": 5 }
]
```

🧠 **这是 jq 进阶分水岭，用熟了你就赢麻了**

---

## 五、ORDER BY / LIMIT

### SQL

```sql
SELECT name FROM pods ORDER BY name LIMIT 3;
```

### jq

```bash
jq -r '.items
  | sort_by(.metadata.name)
  | .[:3]
  | .[].metadata.name'
```

---

### ORDER BY 数字字段

```bash
jq '.items | sort_by(.status.startTime)'
```

---

## 六、IN / EXISTS（SQL 常见）

### SQL

```sql
WHERE phase IN ('Running', 'Pending')
```

### jq

```bash
jq '.items[]
  | select(.status.phase=="Running" or .status.phase=="Pending")
  | .metadata.name'
```

或更像 SQL 的写法：

```bash
jq '.items[]
  | select(.status.phase | IN("Running","Pending"))
  | .metadata.name'
```

---

## 七、数组字段（容器 / 端口）——jq 完胜 jsonpath

### SQL（概念上）

```sql
SELECT pod, image FROM containers;
```

### jq

```bash
jq -r '.items[]
  | .metadata.name as $pod
  | .spec.containers[]
  | "\($pod) \(.image)"'
```

输出：

```
nginx nginx:1.25
nginx busybox:1.36
```

📌 `as $var` ≈ SQL 的临时变量 / 子查询别名

---

## 八、JOIN（jq 可以，但要理智）

### SQL

```sql
SELECT pod.name, node.name
FROM pod JOIN node ON pod.node = node.name;
```

### jq（示意）

```bash
jq -n '
  ($pods.items[]) as $p
  | ($nodes.items[])
  | select($p.spec.nodeName == .metadata.name)
  | {pod: $p.metadata.name, node: .metadata.name}
'
```

⚠️ 真实生产中：

* jq JOIN **可做**
* 但复杂 JOIN → **上 Python / Go**

---

## 九、UPDATE / 转换数据（SQL 很弱，jq 很强）

### SQL

```sql
SELECT name, UPPER(phase) FROM pods;
```

### jq

```bash
jq '.items[]
  | {name: .metadata.name, phase: (.status.phase | ascii_upcase)}'
```

---

### 增加字段

```bash
jq '.items[]
  | . + {env: "prod"}'
```

---

## 十、实战对比总结（说人话）

### 如果你在 k8s 里：

| 场景      | 推荐             |
| ------- | -------------- |
| 简单取字段   | jsonpath       |
| 条件 + 统计 | **jq**         |
| 脚本自动化   | **jq**         |
| 表格给人看   | custom-columns |
| 超复杂逻辑   | Python         |

一句狠话版总结：

> **jsonpath 是镊子，jq 是瑞士军刀**

---

## 十一、给你一套「SQL → jq 速查表」

| SQL        | jq             |
| ---------- | -------------- |
| SELECT a,b | `{a:.a, b:.b}` |
| WHERE      | `select()`     |
| COUNT      | `length`       |
| GROUP BY   | `group_by()`   |
| ORDER BY   | `sort_by()`    |
| LIMIT      | `.[start:end]` |
| AS         | `as $var`      |

---

如果你愿意，我可以下一步直接帮你做：

* 🔥 **k8s 日常运维 jq 命令集（Pod / Node / Deployment）**
* 🔥 **jq + bash + Jenkins 实战流水线**
* 🔥 **把你 SQL 思维完整迁移成 jq 思维**

你更想哪一个？

