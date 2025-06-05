```shell
#!/bin/bash

# 传入参数：项目 ID 和 用户组
PROJECT_ID=$1
GROUP_EMAIL=$2

if [[ -z "$PROJECT_ID" || -z "$GROUP_EMAIL" ]]; then
  echo "用法: $0 <PROJECT_ID> <GROUP_EMAIL>"
  echo "例如: $0 my-project-id dev-team@example.com"
  exit 1
fi

echo "查询项目 [$PROJECT_ID] 中用户组 [$GROUP_EMAIL] 的角色和权限..."

# 获取绑定到该用户组的角色列表
ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" \
  --format="json" | \
  jq -r --arg GROUP "group:$GROUP_EMAIL" '
    .bindings[] |
    select(.members[]? == $GROUP) |
    .role' | sort -u)

if [[ -z "$ROLES" ]]; then
  echo "未找到该用户组绑定的角色。"
  exit 0
fi

# 遍历每个角色并列出权限
for ROLE in $ROLES; do
  echo -e "\n🔹 角色: $ROLE"
  if [[ "$ROLE" == roles/* ]]; then
    # 预定义角色
    gcloud iam roles describe "$ROLE" --format="value(includedPermissions)"
  else
    # 自定义角色
    gcloud iam roles describe "$ROLE" --project="$PROJECT_ID" --format="value(includedPermissions)"
  fi
done

```



# 证书提取

```shell
#!/bin/bash

input_file="bundle.pem"  # 修改为你的文件名
temp_dir=$(mktemp -d)

# 分割证书
csplit -f "$temp_dir/cert_" -b "%02d.pem" "$input_file" '/-----BEGIN CERTIFICATE-----/' '{*}' >/dev/null 2>&1

for cert_file in "$temp_dir"/*.pem; do
    subject=$(openssl x509 -in "$cert_file" -noout -subject | sed 's/subject= //')
    issuer=$(openssl x509 -in "$cert_file" -noout -issuer | sed 's/issuer= //')
    is_ca=$(openssl x509 -in "$cert_file" -noout -text | grep -A1 "Basic Constraints" | grep -i "CA:TRUE")

    if [[ "$subject" == "$issuer" ]]; then
        echo "Found ROOT CA: $cert_file"
        cp "$cert_file" root_ca.pem
    elif [[ -n "$is_ca" ]]; then
        echo "Found INTERMEDIATE CA: $cert_file"
        cp "$cert_file" inter_ca.pem
    else
        echo "Found CER (leaf certificate): $cert_file"
        cp "$cert_file" cer.pem
    fi
done

# 清理临时目录
rm -r "$temp_dir"

```
