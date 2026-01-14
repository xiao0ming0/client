#!/bin/bash


# 检查是否提供了 UUID, SERVER 和 PORT
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <UUID> <URL> <Client_ID>"
    exit 1
fi


UUID=$1
URL="https://$2/api/v1/client/get"
Client_ID=$3

# 检测操作系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif [ -f /etc/alpine-release ]; then
        OS="alpine"
    else
        OS="unknown"
    fi
}

detect_os

# 根据操作系统设置服务名称和路径
if [ "$OS" = "alpine" ]; then
    # Alpine Linux 使用 OpenRC
    SERVICE_NAME="serverwatch"
    SERVICE_PATH="/etc/init.d/$SERVICE_NAME"
    INIT_SYSTEM="openrc"
else
    # Debian/Ubuntu 等使用 systemd
    SERVICE_NAME="serverwatch.service"
    SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
    INIT_SYSTEM="systemd"
fi

echo "检测到系统: $OS, 使用 $INIT_SYSTEM 作为初始化系统"

# 停止并删除旧服务
if [ "$INIT_SYSTEM" = "systemd" ]; then
    # systemd 服务管理
    if systemctl list-units --full -all 2>/dev/null | grep -Fq "$SERVICE_NAME"; then
        echo "$SERVICE_NAME 已存在，删除旧的服务文件和服务..."
        systemctl stop $SERVICE_NAME 2>/dev/null
        systemctl disable $SERVICE_NAME 2>/dev/null
        rm -f $SERVICE_PATH
        systemctl daemon-reload 2>/dev/null
    fi
elif [ "$INIT_SYSTEM" = "openrc" ]; then
    # OpenRC 服务管理
    if [ -f "$SERVICE_PATH" ]; then
        echo "$SERVICE_NAME 已存在，删除旧的服务文件和服务..."
        rc-service $SERVICE_NAME stop 2>/dev/null
        rc-update del $SERVICE_NAME 2>/dev/null
        rm -f $SERVICE_PATH
    fi
fi

# 使用 curl 获取 IP 地址（静默模式）
ip=$(curl -s ifconfig.co)
if [ -z "$ip" ]; then
    echo "错误：无法获取 IP 地址。" >&2
    exit 1
fi

if [[ "$ip" == *:* ]]; then
    echo "IPv6"
    wget -O client --no-check-certificate --inet6-only "https://raw.githubusercontent.com/xinling123/client/refs/heads/main/client" >/dev/null 2>&1 && chmod +x client
else
    wget -O client --no-check-certificate --inet4-only "https://raw.githubusercontent.com/xinling123/client/refs/heads/main/client" >/dev/null 2>&1 && chmod +x client
fi

# 根据初始化系统创建相应的服务文件
if [ "$INIT_SYSTEM" = "systemd" ]; then
    echo "创建 systemd 服务"
    # 创建 systemd 服务单元文件
    bash -c "cat > $SERVICE_PATH" <<EOL
[Unit]
Description=My Client Service
After=network.target

[Service]
ExecStart=/root/client UUID=$UUID URL=$URL Client_ID=$Client_ID
Restart=always

[Install]
WantedBy=multi-user.target
EOL
    
    # 重新加载 systemd 守护进程
    systemctl daemon-reload
    
    # 启动服务
    systemctl start $SERVICE_NAME
    
    # 设置服务为开机自动启动
    systemctl enable $SERVICE_NAME
    
elif [ "$INIT_SYSTEM" = "openrc" ]; then
    echo "创建 OpenRC 服务"
    # 创建 OpenRC 服务脚本
    bash -c "cat > $SERVICE_PATH" <<EOL
#!/sbin/openrc-run

name="serverwatch"
description="My Client Service"
command="/root/client"
command_args="UUID=$UUID URL=$URL Client_ID=$Client_ID"
pidfile="/var/run/\${RC_SVCNAME}.pid"
command_background="yes"

depend() {
    need net
    after net
}
EOL
    
    # 设置执行权限
    chmod +x $SERVICE_PATH
    
    # 启动服务
    rc-service $SERVICE_NAME start
    
    # 设置服务为开机自动启动
    rc-update add $SERVICE_NAME default
fi

echo "启动成功"
