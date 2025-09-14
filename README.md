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

```shell
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<-'EOF'
[Service]
Environment="HTTP_PROXY=http://192.168.101.51:7890"
Environment="HTTPS_PROXY=http://192.168.101.51:7890"
Environment="NO_PROXY=localhost,127.0.0.1,192.168.101.0/24"
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
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://192.168.101.101:8929'
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

```yaml
services:
  jenkins:
    image: jenkins/jenkins
    container_name: jenkins
    restart: always
    environment:
      - HTTP_PROXY=http://192.168.101.51:7890
      - HTTPS_PROXY=http://192.168.101.51:7890
      - NO_PROXY=localhost,127.0.0.1,,192.168.101.0/24
    ports:
      - 8080:8080
      - 50000:50000
    volumes:
      - ./data/:/var/jenkins_home/
```

```shell
 mkdir jenkins
 cd jenkins
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
