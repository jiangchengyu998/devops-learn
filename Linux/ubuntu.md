
## 关闭防火墙
```shell
if command -v ufw >/dev/null 2>&1; then
  echo "检测到 ufw 防火墙，正在关闭..."
  sudo ufw disable
elif systemctl list-units --type=service | grep -q firewalld; then
  echo "检测到 firewalld 防火墙，正在关闭..."
  sudo systemctl stop firewalld
  sudo systemctl disable firewalld
else
  echo "未检测到常见防火墙（ufw/firewalld），可能已经未启用。"
fi

```
## 在Ubuntu 中，我想hanke 用户拥有超级权限，怎么做
```shell
# 把 hanke 加入 sudo 组
sudo usermod -aG sudo hanke

# 使组更改即时生效（切换到该用户的新 shell）
su - hanke

# 验证（会显示包含 sudo 的组）
groups

# 测试 sudo 是否可用（会提示输入 hanke 的密码）
sudo whoami
# 正常应输出: root

```

## ubuntu 添加交换空间
```shell
#查看当前交换空间
sudo swapon --show
free -h
#创建交换文件
sudo fallocate -l 4G /swapfile
# 或者
sudo dd if=/dev/zero of=/swapfile bs=1M count=4096

#设置正确权限
sudo chmod 600 /swapfile

#格式化为 Swap
sudo mkswap /swapfile
#格式化为 Swap
sudo swapon /swapfile

#启用 Swap
sudo swapon /swapfile
#立即生效，可以用：
sudo swapon --show
free -h

#开机自动挂载 Swap
#编辑 /etc/fstab 文件：
sudo vim /etc/fstab

#在文件末尾添加：
/swapfile none swap sw 0 0

#保存并退出，重启后验证：

free -h
```