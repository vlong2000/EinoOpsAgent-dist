# 配置说明

## 环境变量

项目使用 `.env` 文件管理配置。首次运行时无需手动创建，启动脚本会自动从 `.env.example` 复制一份。

### 配置项说明

| 变量 | 示例值 | 必填 | 说明 |
|---|---|---|---|
| `MODEL_PROVIDER` | `openai` | ✅ | 大模型提供商，目前仅支持 `openai`（兼容 OpenAI 格式的 API） |
| `OPENAI_API_KEY` | `sk-xxx` | ✅ | API 密钥，请替换为真实有效的 Key |
| `OPENAI_MODEL` | `gpt-4o-mini` | ✅ | 模型名称，例如 `gpt-4o-mini`、`gpt-4o`、`claude-3-haiku-20240307`（Anthropic 经 OpenAI 格式代理）等 |
| `OPENAI_BASE_URL` | `https://api.openai.com/v1` | ✅ | API 端点，支持所有兼容 OpenAI 协议的第三方服务 |
| `SERVER_PORT` | `8080` | 否 | Web 服务端口 |
| `SERVER_MODE` | `debug` | 否 | 运行模式，`debug` 开启详细日志，`release` 仅输出警告以上级别 |
| `KNOWledge_BASE_PATH` | `./data/knowledge_base/` | 否 | 知识库路径（可选） |
| `FILE_READER_WATCH_DIR` | `./data` | 否 | 文件工具监控根目录，list_files/read_file/search_file 只能访问此目录 |
| `FILE_READER_CHUNK_SIZE` | `30000` | 否 | 文件读取分块大小（按字符累计切块） |
| `FILE_READER_MAX_SEARCH_RESULTS` | `50` | 否 | search_file 单文件最多返回的匹配条数 |
| `OPS_TOOLS_ENABLED` | `false` | 否 | 是否启用额外运维工具（网元状态、告警、ping、知识库），默认关闭 |

## 常见场景配置

### 使用本地部署的 Ollama

```ini
MODEL_PROVIDER=openai
OPENAI_API_KEY=sk-fake
OPENAI_MODEL=llama3
OPENAI_BASE_URL=http://localhost:11434/v1
```

### 使用 OpenRouter

```ini
MODEL_PROVIDER=openai
OPENAI_API_KEY=sk-or-xxx
OPENAI_MODEL=mistral-medium
OPENAI_BASE_URL=https://openrouter.ai/api/v1
```

### 使用 360 智海

```ini
MODEL_PROVIDER=openai
OPENAI_API_KEY=xxx
OPENAI_MODEL=qwen2.5-72b-instruct
OPENAI_BASE_URL=https://ai.360.cn/api/v1
```

## 快速启动

### Windows
```cmd
# 双击运行
start-agent.cmd
# 或
start-agent.ps1
```

### Linux
```bash
chmod +x start.sh
./start.sh
```

## 验证服务

```bash
curl http://localhost:8080/health
```

预期响应：
```json
{"status":"ok","service":"eino-ops-agent","agent_ready":true}
```

## 常见问题

### 1. 连接模型失败
- 检查 `OPENAI_BASE_URL` 是否可达：`curl -I <base_url>`
- 检查 `OPENAI_API_KEY` 是否有效
- 本地 Ollama 需确保 `ollama serve` 正在运行

### 2. 端口被占用
修改 `SERVER_PORT` 为其他端口（如 8081）

### 3. 文件工具权限限制
`FILE_READER_WATCH_DIR` 限制了文件工具只能访问指定目录，如需访问其他目录，修改该路径即可。
