
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