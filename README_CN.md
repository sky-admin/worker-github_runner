# README_CN.md

<div align="center">

# GitHub Actions | RunPod Worker

</div>

## 概述

本仓库提供了在 RunPod 平台上部署 GitHub Actions Runner 的代码。该 Worker 专为 CI/CD 流水线设计,可用于运行测试或执行计算密集型任务,将这些任务从本地开发环境或 GitHub 托管的 Runner 中卸载到 RunPod 的 GPU 基础设施上。

## 目录

- [概述](#概述)
- [目录](#目录)
- [功能特性](#功能特性)
- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [使用说明](#使用说明)
  - [环境变量配置](#环境变量配置)
  - [输入参数](#输入参数)
  - [工作流程](#工作流程)
- [在 GitHub Actions 中使用](#在-github-actions-中使用)
- [文档](#文档)
- [贡献指南](#贡献指南)
- [许可证](#许可证)

## 功能特性

- 在 RunPod Serverless 平台上部署 GitHub Actions Runner
- 可集成到 CI/CD 流水线中运行测试和其他任务
- 使用 Docker 确保跨多个部署的一致运行环境
- 支持 NVIDIA CUDA 和 cuDNN,适合 GPU 密集型工作负载
- 自动注册和注销 Runner,确保资源清理
- 单次作业执行模式,每个 Worker 处理一个作业后退出

## 前置要求

- 本地机器上已安装 Docker
- 拥有活跃的 RunPod 账户
- RunPod API 密钥
- GitHub 个人访问令牌 (PAT),具有以下权限:
  - `repo` (完整仓库访问权限)
  - `admin:org` (用于组织级 Runner)
- GitHub 组织或仓库用于注册 Runner

## 快速开始

1. 克隆本仓库:

   ```bash
   git clone https://github.com/runpod-workers/worker-github_runner.git
   ```

2. 切换到项目目录:

   ```bash
   cd worker-github_runner
   ```

3. 构建 Docker 镜像:

   ```bash
   docker build -t your-org/worker-github_runner .
   ```

4. 配置必要的环境变量(参见下方[环境变量配置](#环境变量配置))。

5. 将 Worker 部署到 RunPod 平台。

## 使用说明

### 环境变量配置

#### 必需的环境变量

以下环境变量必须配置,可以通过环境变量或作业输入参数提供:

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `GITHUB_PAT` | GitHub 个人访问令牌,用于注册 Runner | `ghp_xxxxxxxxxxxx` |
| `GITHUB_ORG` | GitHub 组织名称或仓库路径 | `your-organization` 或 `owner/repo` |

**注意**: `GITHUB_ORG` 支持两种格式:
- **组织级 Runner**: 传入组织名称,例如 `your-organization`
- **仓库级 Runner**: 传入完整仓库路径,例如 `username/repository-name`

个人仓库使用仓库路径格式即可。

#### 自动设置的环境变量

以下环境变量由 RunPod 平台自动设置:

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `RUNPOD_POD_ID` | RunPod Pod ID,用作 Runner 名称 | `serverless-runpod-runner` |
| `JOB_INPUT` | 传递给 Runner 环境的事件输入 | 自动设置 |

#### 系统环境变量

以下环境变量在 Dockerfile 中预设:

| 变量名 | 说明 | 值 |
|--------|------|-----|
| `RUNNER_ALLOW_RUNASROOT` | 允许 Runner 以 root 用户运行 | `1` |
| `DEBIAN_FRONTEND` | Debian 包管理器前端模式 | `noninteractive` |

#### 过滤的环境变量

为避免冲突,以下 RunPod 特定的环境变量会在启动 Runner 前被移除:

- `RUNPOD_WEBHOOK_GET_JOB`
- `RUNPOD_POD_ID`
- `RUNPOD_WEBHOOK_POST_OUTPUT`
- `RUNPOD_WEBHOOK_POST_STREAM`
- `RUNPOD_WEBHOOK_PING`
- `RUNPOD_AI_API_KEY`

### 输入参数

Handler 接受以下输入参数(通过 RunPod 作业输入):

```json
{
  "input": {
    "github_pat": "ghp_xxxxxxxxxxxx",
    "github_org": "your-organization"
  }
}
```

**注意:** 如果在作业输入中提供了 `github_pat` 和 `github_org`,它们将覆盖环境变量中的值。

### 获取 GitHub Token

#### 组织级 Runner

1. 进入组织设置页面
2. 导航到 Actions > Runners
3. 点击 "New runner" 获取注册 token

#### 仓库级 Runner (个人仓库)

1. 进入仓库设置页面
2. 导航到 Settings > Actions > Runners
3. 点击 "New self-hosted runner"
4. 页面会显示注册 token 和配置命令

### 工作流程

1. **获取注册令牌**: Handler 使用 GitHub PAT 从 GitHub API 获取 Runner 注册令牌
2. **配置 Runner**: 使用组织 URL、注册令牌和标签(`runpod`, Pod ID)配置 Runner
3. **启动 Runner**: 以 `--once` 模式启动 Runner(单次作业执行)
4. **执行作业**: Runner 执行单个 GitHub Actions 作业
5. **清理**: 作业完成后,Runner 自动注销并移除

## 在 GitHub Actions 中使用

### 配置 GitHub Secrets

在您的 GitHub 仓库或组织中设置以下 Secrets:

- `RUNPOD_API_KEY`: RunPod API 密钥
- `RUNPOD_ENDPOINT`: RunPod Serverless 端点 ID
- `GITHUB_PAT`: GitHub 个人访问令牌
- `GITHUB_ORG`: GitHub 组织名称或仓库路径 (例如 `your-organization` 或 `username/repository-name`)

### 工作流示例

#### 组织级 Runner 示例

在您的 GitHub Actions 工作流中使用 RunPod Runner:

```yaml
name: Run Tests on RunPod

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  initialize_worker:
    runs-on: ubuntu-latest
    outputs:
      job_id: ${{ steps.start_job.outputs.job_id }}
    steps:
      - name: Start RunPod Worker
        id: start_job
        uses: fjogeleit/http-request-action@v1
        with:
          url: 'https://api.runpod.ai/v2/${{ secrets.RUNPOD_ENDPOINT }}/run'
          method: 'POST'
          customHeaders: '{"Authorization": "Bearer ${{ secrets.RUNPOD_API_KEY }}"}'
          data: '{"input": {"github_pat": "${{ secrets.GITHUB_PAT }}", "github_org": "${{ secrets.GITHUB_ORG }}"}}'

  run_tests:
    needs: initialize_worker
    runs-on: [self-hosted, runpod]
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Run tests
        run: |
          python -m pytest tests/

  terminate_worker:
    needs: [initialize_worker, run_tests]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Terminate RunPod Worker
        uses: fjogeleit/http-request-action@v1
        with:
          url: 'https://api.runpod.ai/v2/${{ secrets.RUNPOD_ENDPOINT }}/cancel/${{ needs.initialize_worker.outputs.job_id }}'
          method: 'POST'
          customHeaders: '{"Authorization": "Bearer ${{ secrets.RUNPOD_API_KEY }}"}'
```

### Runner 标签

RunPod Worker 会自动注册以下标签:

- `runpod`: 标识这是一个 RunPod Runner
- `{RUNPOD_POD_ID}`: Pod 的唯一标识符

在工作流中使用这些标签来指定作业运行位置:

```yaml
runs-on: [self-hosted, runpod]
```

#### 个人仓库 Runner 示例

对于个人仓库,只需将 `GITHUB_ORG` 设置为仓库路径格式:

```yaml
name: Run Tests on RunPod (Personal Repo)

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  initialize_worker:
    runs-on: ubuntu-latest
    outputs:
      job_id: ${{ steps.start_job.outputs.job_id }}
    steps:
      - name: Start RunPod Worker
        id: start_job
        uses: fjogeleit/http-request-action@v1
        with:
          url: 'https://api.runpod.ai/v2/${{ secrets.RUNPOD_ENDPOINT }}/run'
          method: 'POST'
          customHeaders: '{"Authorization": "Bearer ${{ secrets.RUNPOD_API_KEY }}"}'
          data: '{"input": {"github_pat": "${{ secrets.GITHUB_PAT }}", "github_org": "username/repository-name"}}'

  run_tests:
    needs: initialize_worker
    runs-on: [self-hosted, runpod]
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Run tests
        run: |
          python -m pytest tests/

  terminate_worker:
    needs: [initialize_worker, run_tests]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Terminate RunPod Worker
        uses: fjogeleit/http-request-action@v1
        with:
          url: 'https://api.runpod.ai/v2/${{ secrets.RUNPOD_ENDPOINT }}/cancel/${{ needs.initialize_worker.outputs.job_id }}'
          method: 'POST'
          customHeaders: '{"Authorization": "Bearer ${{ secrets.RUNPOD_API_KEY }}"}'
```

**注意**: 将 `username/repository-name` 替换为您的实际仓库路径。

## 文档

更多关于 GitHub Actions Worker 的工作原理以及如何集成到 CI/CD 流水线的详细信息,请参阅 [文档](./docs)。

### 相关文档

- [使用说明](./docs/usage.md) - CI/CD 工作流配置详解
- [贡献指南](./CONTRIBUTING.md) - 如何为本项目做贡献

## 贡献指南

我们欢迎社区贡献!请阅读我们的 [贡献指南](./CONTRIBUTING.md) 了解如何为本项目做贡献的详细信息。

## 许可证

本项目采用 [MIT 许可证](./LICENSE)。详情请阅读 [LICENSE](./LICENSE) 文件。

---

## 技术细节

### Docker 镜像

- **基础镜像**: `nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04`
- **GitHub Runner 版本**: `2.305.0`
- **Python 依赖**:
  - `runpod~=1.7.0` (使用兼容版本操作符 `~=`)
  - `requests==2.31.0`

### 架构说明

- **单次执行模式**: 每个 Worker 使用 `--once` 标志,处理一个作业后退出
- **Runner 命名**: Runner 名称设置为 RunPod Pod ID,便于追踪
- **Worker 刷新**: Handler 使用 `refresh_worker: True` 配置,确保作业间的清洁状态
- **版本固定**: GitHub Runner 版本在 Dockerfile ARG 中硬编码(当前为 2.305.0)

### 故障排查

如果遇到问题,请检查:

1. GitHub PAT 是否具有正确的权限
2. GitHub 组织名称是否正确
3. RunPod API 密钥是否有效
4. Runner 标签是否在工作流中正确指定
5. 查看 RunPod 日志以获取详细错误信息
