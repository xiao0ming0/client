# Go开发环境Dockerfile
# 用于构建server-monitor-client项目

FROM golang:1.21-alpine

# 安装必要的工具
RUN apk add --no-cache \
    git \
    make \
    bash \
    curl \
    ca-certificates

# 设置工作目录
WORKDIR /app

# 创建bin目录用于存放构建产物
RUN mkdir -p /app/bin

# 复制go mod文件（利用Docker缓存）
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 默认命令保持容器运行，方便手动操作
CMD ["/bin/sh"]
