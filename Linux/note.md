### linux yum/apt-get 配置文件位置
```text
对于 CentOS 来讲，配置文件在/etc/yum.repos.d/CentOS-Base.repo里。
对于 Ubuntu 来讲，配置文件在/etc/apt/sources.list里。
```

### netstat 常用命令
```shell
netstat -anp  # 显示所有连接及监听端口，并显示进程ID和进程名称
-a : 显示所有连接及监听端口
-n : 以数字形式显示地址和端口号
-p : 显示进程ID和进程名称
-t : 显示TCP连接
-u : 显示UDP连接
-l : 仅显示监听状态的连接
-e : 显示内核的错误信息
-c : 每隔一段时间刷新显示

```