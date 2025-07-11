#!/bin/bash

# 等待 sandbox-runtime 健康检查通过
while ! curl -s http://localhost:8330/healthz -o /dev/null -w "%{http_code}" | grep -q "200"; do
    echo "[code server] Waiting for sandbox-runtime to be ready..."
    sleep 1
done

echo "sandbox-runtime is ready, starting code server..."
CODE_SERVER_CONFIG='/home/ubuntu/.config/code-server/config.yaml'
CODE_SERVER_PORT=8329
echo "export CODE_SERVER_PORT=\"$CODE_SERVER_PORT\"" >> /home/ubuntu/.env
# 生成 code server auth 使用的随机密码并写入到环境变量
if ! grep -q "CODE_SERVER_PASSWORD=" "/home/ubuntu/.env"; then
CODE_SERVER_PASSWORD=$(openssl rand -base64 8 | md5sum | head -c16)
echo "bind-addr: 0.0.0.0:$CODE_SERVER_PORT" >> $CODE_SERVER_CONFIG
echo "password: $CODE_SERVER_PASSWORD" >> $CODE_SERVER_CONFIG
echo "export CODE_SERVER_PASSWORD=\"$CODE_SERVER_PASSWORD\"" >> /home/ubuntu/.env
source /home/ubuntu/.env
fi
su -l ubuntu -c "code-server --config $CODE_SERVER_CONFIG --disable-workspace-trust"
