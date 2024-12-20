# devops-learn

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
EOF
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
version: '3.1'
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

