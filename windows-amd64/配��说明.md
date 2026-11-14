# eino-ops-agent 分发包

基于 CloudWeGo Eino 的 5G 核心网运维故障排查智能体。

## 一、最小可用配置

解压后进入对应平台目录，编辑 `.env`：

```
MODEL_PROVIDER=openai
OPENAI_API_KEY=你的API密钥
OPENAI_MODEL=gpt-4o-mini
OPENAI_BASE_URL=https://api.openai.com/v1

SERVER_PORT=8080
SERVER_MODE=release
KNOWLEDGE_BASE_PATH=./data/knowledge_base/

# 只读文件工具（list_files / read_file / search_file）
FILE_READER_WATCH_DIR=./data
FILE_READER_CHUNK_SIZE=30000
FILE_READER_MAX_SEARCH_RESULTS=50

# 默认只启用上面的 3 个文件工具；设 true 恢复 4 个演示运维工具
OPS_TOOLS_ENABLED=false

# ReAct 单次推理最大工具调用轮次（默认 40），复杂场景可调大
AGENT_MAX_STEP=40
```

要点：
- `OPENAI_API_KEY`：必填，不能保留 `sk-xxx` 占位值。
- `OPENAI_MODEL`：必填，必须与 `OPENAI_BASE_URL` 所属服务商支持的模型名一致。
- `OPENAI_BASE_URL`：填 API 根地址，以 `/v1` 结尾，例如 `https://api.openai.com/v1`。
  误填成 `.../v1/chat/completions` 也能自动纠正。
- 值两边的引号、空格会自动去掉。
- `.env` 必须与可执行文件在同一目录；服务按“当前工作目录”读取 `.env`。
- 修改 `.env` 后必须重启进程才会生效。
- `FILE_READER_WATCH_DIR`：文件工具的监控根目录，相对路径以进程工作目录为基准；
  三个文件工具只能访问该目录内的相对路径，绝对路径、`..` 越权和符号链接逃逸都会被拒绝。
  该目录不存在时 `list_files` 返回 `目录不存在`，需先创建并放入数据文件。
- `FILE_READER_CHUNK_SIZE` / `FILE_READER_MAX_SEARCH_RESULTS` 可省略，默认 30000 字符 / 50 条。
- `OPS_TOOLS_ENABLED=false`（默认）：只注册 `list_files`、`read_file`、`search_file`。
  设为 `true` 会额外注册网元状态、告警、ping、知识库 4 个演示工具；修改后需重启。
- `AGENT_MAX_STEP`：单轮推理允许的工具调用步数，默认 40。大目录场景下模型容易反复翻文件，
  调到 60 会留更多轮次但更慢；出现“达到最大推理步数”时，服务会用已收集的工具结果做一次
  兜底总结，仍会返回结论而不是空回答。

## 二、启动

### Windows

推荐直接双击 `start-agent.cmd`，或在命令行执行：

```bat
cd windows-amd64
notepad .env
start-agent.cmd
```

关于 `start.ps1`：Windows 默认把 `.ps1` 关联到记事本，双击只会打开文件而不会运行，这是系统默认行为，不是文件损坏。若要运行它：

```powershell
cd windows-amd64
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

或在文件上右键选择“使用 PowerShell 运行”。若系统执行策略为 Restricted，需要临时绕过：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

也可以直接运行可执行文件：

```powershell
.\eino-ops-agent.exe
```

### Linux

```bash
cd linux-amd64
chmod +x eino-ops-agent start.sh
vi .env
./start.sh
```

或直接运行：

```bash
./eino-ops-agent
```

## 三、启动成功的判断标准

启动日志应出现：

```
模型配置: provider=openai model=... base_url=... api_key=sk-x****abcd
✅ Eino运维智能体初始化成功
🚀 服务启动成功，监听端口: 8080
```

健康检查：

```bash
curl http://localhost:8080/health
```

正常返回：

```json
{"agent_ready":true,"service":"eino-ops-agent","status":"ok"}
```

- `agent_ready: true`：模型客户端已初始化。
- `agent_ready: false`：服务在运行，但模型配置无效，日志会给出具体原因。

注意：`agent_ready` 只代表客户端初始化成功，真正是否可用还要发一次对话请求确认。

## 四、Web 控制台

服务启动后，用浏览器打开：

```
http://localhost:8080/
```

页面提供：
- 顶部实时连接状态：绿=服务与模型就绪，黄=服务在线但模型未配置，红=连接断开（每 8 秒自动重检）
- 对话区：流式打字输出，支持 Markdown（表格、代码块、列表）
- 排查过程卡片：展示每次工具调用的名称、参数和返回结果，可整体折叠
- 左侧会话列表：点击“新会话”会新建会话，原有会话保留在列表中；点击任意列表项可恢复该会话的提问、回答与工具调用过程
- 会话记录保存在浏览器 `localStorage`（最多保留 30 个会话，每个会话最多 40 条消息），刷新页面后仍在；点击会话右侧“×”会弹出确认框，可选择“导出并关闭”“直接关闭”或“取消”，空会话直接关闭
- 输入框：Enter 发送、Shift+Enter 换行
- 导出 Markdown：会话列表每项右侧的下载图标可导出该会话（顶栏不再提供导出按钮）。
  文件名以导出时间戳开头，后接截断到 24 字符的提问标题，例如
  `20261111193330_读取 alarm_示例告警.csv 并统计各级别.md`，按文件名排序即按导出时间排序。
- 导出内容默认只包含会话元信息、每轮提问与回答和异常标记，**不包含**工具调用参数与结果。
  如需包含工具调用过程，可在页面地址后加 `?exportTools=1`（临时打开，无需重新构建），
  或把 `internal/webui/static/app.js` 中的 `EXPORT_INCLUDE_TOOLS` 改为 `true` 后重新构建。
  导出的文件为 UTF-8 with BOM，Windows 记事本与常见 Markdown 阅读器均可正常显示中文

页面已内嵌进可执行文件，无需单独部署静态文件，也无需额外安装依赖。

## 五、内置工具

**当前默认只启用 3 个只读文件工具**（按 `file-reader-接口文档.md` 实现，能力与 MCP
`file-reader-server` 一致）。原有 4 个演示运维工具（`get_network_element_status`、
`query_alerts`、`ping_target`、`search_knowledge_base`）暂时禁用，代码保留在
`internal/tools/ops_tools.go`，把 `.env` 中 `OPS_TOOLS_ENABLED` 改为 `true` 并重启即可恢复。

| 工具 | 参数 | 说明 |
|---|---|---|
| `list_files` | `subdir`(可选，默认根)、`recursive`(可选，默认 true) | 列出监控目录下的子目录与文件（相对路径），过滤 `.`/`~` 开头的隐藏项 |
| `read_file` | `filepath`(必填)、`chunk`(可选，默认 1) | 按扩展名选择解析器读取内容，大文件按字符分块翻页 |
| `search_file` | `filepath`、`keyword`(必填，≤200 字符) | 文件内大小写不敏感搜索，返回分块号、行号与前 200 字符片段 |

返回字段、错误文案与分块规则对齐接口文档：`directory/directories/files`、`parser_used/size/content/total_chunks/total_rows/chunk/rows_in_chunk/navigation`、
`total_matches/matches/hint`，错误含 `目录不存在`、`禁止访问: 路径越权`、`文件不存在`、
`文件解析失败: ...`、`不支持的文件类型: ...`、`无效的分块号: N，有效范围 1-M`。

解析支持：
- `.xlsx` / `.xls`：每个 sheet 以 `--- Sheet: 名称 ---` 标记，单元格以 Tab 连接，行尾空单元格剔除、空行跳过。
- `.docx`：非空段落逐行输出，表格以 `--- Table N ---` 标记，单元格以 ` | ` 连接。
- `.txt` / 其他文本：按行原样输出，编码自动回退 `utf-8-sig` → `gb18030`；含 NUL 字节视为二进制并拒绝。

安全约束：只读，无写入/修改/删除能力；拒绝绝对路径、含 `..` 的路径，以及解析后越出
`FILE_READER_WATCH_DIR` 的符号链接。

准备数据文件示例（Windows）：

```powershell
New-Item -ItemType Directory -Path .\data\alarm -Force
Copy-Item .\你的告警.csv .\data\alarm\告警.csv
```

随后可直接提问，例如“列出 data 目录文件，读取告警文件并找出 Critical 记录”。

说明：默认关闭网元状态/告警/ping/知识库工具后，问“查一下 SMF-01 为什么掉线”这类问题时，
智能体会明确说明只能用文件数据分析，并请用户提供对应导出文件，而不会编造实时网元或告警结果。

## 六、对话验证

```bash
curl -X POST http://localhost:8080/api/v1/chat \
  -H "Content-Type: application/json" \
  -d "{\"session_id\":\"demo\",\"query\":\"帮我查一下SMF-01为什么掉线了\"}"
```

成功返回：

```json
{"code":200,"message":"success","data":{"answer":"..."}}
```

SSE 流式：

```bash
curl -N -X POST http://localhost:8080/api/v1/chat/stream \
  -H "Content-Type: application/json" \
  -d "{\"session_id\":\"demo\",\"query\":\"帮我排查UPF-02丢包问题\"}"
```

清空会话：

```bash
curl -X DELETE http://localhost:8080/api/v1/session/demo
```

## 七、常见错误与处理

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `agent_ready:false`，日志提示配置有效的 OPENAI_API_KEY | 密钥为空或仍是 `sk-xxx` | 填入真实密钥后重启 |
| 启动即退出，提示端口占用 | 8080 被占用 | 修改 `SERVER_PORT` 或停止占用进程 |
| 调用返回 401 / Unauthorized | 密钥错误、过期或不属于该地址 | 核对密钥与 `OPENAI_BASE_URL` 是否同属一个服务商 |
| 调用返回 404 | `OPENAI_BASE_URL` 路径不对 | 只填到 `/v1`，不要填 `/chat/completions` |
| 调用返回 500 或“系统异常” | 服务商侧故障、模型名不支持或额度不足 | 先用下面的探测脚本确认，再联系服务商 |
| `invalid character 'd' looking for beginning of value` | 服务端把非流式请求也用 SSE 返回 | 已内置自动兼容转换（v1.1+）；若仍出现请升级到最新包 |
| 回答内容乱码 | 终端编码问题 | 用 `curl` 输出到文件后按 UTF-8 查看 |

## 八、模型接入自检

先用标准请求确认模型本身可用，再排查本服务：

```bash
curl -sS https://你的地址/v1/chat/completions \
  -H "Authorization: Bearer 你的密钥" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"你的模型\",\"messages\":[{\"role\":\"user\",\"content\":\"只回复：OK\"}],\"stream\":false}"
```

必须返回标准 `choices[0].message.content`，且响应头是 `application/json`。
若这里就返回 500/401/HTML，本服务配置再正确也无法对话。

## 九、说明

- 4 个演示运维工具默认禁用（`OPS_TOOLS_ENABLED=false`），代码在 `internal/tools/ops_tools.go`；3 个文件工具为真实只读实现，代码在 `internal/tools/file_tools.go` 与 `internal/tools/file_parsers.go`。
- 服务端会话记忆在进程内存中，服务重启后模型上下文会清空；页面列表恢复的是浏览器本地的展示历史。
- 可执行文件为静态链接，目标机器无需安装 Go。
- v1.1+ 内置 SSE 兼容层：部分服务商（如 ai.in-caps.com）即使 `stream=false` 也返回 `data:{...}`，服务会自动还原为标准 JSON，包括工具调用的增量拼接。
- 若服务商不支持 `stream=true`（返回 401/500），流式接口会自动降级为非流式推理，再按块推送 SSE，前端无需改动。
- Linux 包需要在目标机执行 `chmod +x`。