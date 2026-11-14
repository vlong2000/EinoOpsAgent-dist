#!/bin/bash
# 快速启动脚本

echo "🚀 正在启动Eino通信运维智能体..."

# 检查.env文件
if [ ! -f .env ]; then
    echo "⚠️  未找到.env文件，正在从模板复制..."
    cp .env.example .env
    echo "⚠️  请先编辑.env文件填写大模型API密钥，然后重新运行脚本"
    exit 1
fi

# 加载环境变量
export $(grep -v '^#' .env | xargs)

# 安装依赖
echo "📦 安装依赖..."
go mod tidy

# 运行服务
echo "🔧 启动服务..."
go run main.go
