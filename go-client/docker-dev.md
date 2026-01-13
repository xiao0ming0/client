# Docker开发环境使用指南

## 快速开始

### 1. 构建Docker镜像
```bash
docker-compose build
```

或者直接使用docker命令：
```bash
docker build -t server-monitor-dev .
```

### 2. 启动开发容器

使用docker-compose（推荐）：
```bash
docker-compose up -d
docker-compose exec go-dev sh
```

或者使用docker命令：
```bash
docker run -it --rm -v ${PWD}:/app -w /app server-monitor-dev sh
```

在Windows PowerShell中：
```powershell
docker run -it --rm -v ${PWD}:/app -w /app server-monitor-dev sh
```

### 3. 在容器内编译

进入容器后，你可以手动执行编译命令：

#### Linux x86_64 (静态链接)
```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-extldflags "-static" -s -w' -o bin/server-monitor-linux-amd64 main.go
```

#### Linux ARM64 (静态链接)
```bash
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -ldflags '-extldflags "-static" -s -w' -o bin/server-monitor-linux-arm64 main.go
```

#### Windows x86_64
```bash
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags '-s -w' -o bin/server-monitor-windows-amd64.exe main.go
```

#### macOS x86_64
```bash
CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags '-s -w' -o bin/server-monitor-darwin-amd64 main.go
```

#### macOS ARM64 (Apple Silicon)
```bash
CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags '-s -w' -o bin/server-monitor-darwin-arm64 main.go
```

### 4. 使用构建脚本

容器内也可以使用项目自带的构建脚本：
```bash
# 使用bash脚本（Linux/macOS）
bash build.sh

# 或者直接执行go命令
go build -o bin/server-monitor-linux-amd64 main.go
```

## 常用命令

### 进入运行中的容器
```bash
docker-compose exec go-dev sh
```

### 查看容器日志
```bash
docker-compose logs go-dev
```

### 停止容器
```bash
docker-compose down
```

### 重新构建镜像
```bash
docker-compose build --no-cache
```

## 注意事项

1. **代码映射**: 项目代码通过volume映射到容器中，修改代码后容器内会立即看到变化
2. **构建产物映射**: `bin/` 目录已明确映射到宿主机，编译后的二进制文件会直接保存到宿主机的 `bin/` 目录中
3. **依赖缓存**: Go模块缓存被映射到独立volume，可以加速后续构建
4. **跨平台编译**: 在容器内可以轻松进行跨平台编译，无需在宿主机安装Go环境
5. **实时同步**: 在容器内编译后，宿主机立即可以看到构建产物，无需手动复制

## 如果需要Docker监控功能

如果程序需要访问宿主机的Docker（用于Docker监控功能），需要挂载Docker socket：

在 `docker-compose.yml` 中取消注释相关配置：
```yaml
volumes:
  - .:/app
  - go-mod-cache:/go/pkg/mod
  - /var/run/docker.sock:/var/run/docker.sock  # Linux
  # Windows: //var/run/docker.sock:/var/run/docker.sock
```

## 故障排除

### 权限问题
如果遇到权限问题，可能需要以root用户运行：
```bash
docker-compose exec --user root go-dev sh
```

### 网络问题
如果下载依赖失败，检查网络连接或配置代理：
```bash
# 在容器内设置代理（如果需要）
export HTTP_PROXY=http://your-proxy:port
export HTTPS_PROXY=http://your-proxy:port
```
