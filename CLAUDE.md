# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a RunPod serverless worker that deploys GitHub Actions runners on the RunPod platform. It enables running GitHub Actions workflows on RunPod's GPU infrastructure, particularly useful for compute-intensive CI/CD tasks.

The worker is available in two versions:
- **GPU version**: Includes NVIDIA CUDA 12.6.3 for GPU-accelerated workloads
- **CPU version**: Lightweight version for CPU-only tasks

## Architecture

### Core Components

**Handler (`src/handler.py`)**: The main entry point that:
- Obtains GitHub registration tokens via GitHub API
- Configures and starts a GitHub Actions runner using the official GitHub runner binary
- Runs the runner with `--once` flag (single job execution)
- Cleans up by removing the runner registration after job completion
- Integrates with RunPod's serverless framework via `runpod.serverless.start()`

**Docker Image (`Dockerfile`)**: Multi-stage build that:
- Supports both GPU and CPU versions via `BUILD_TYPE` ARG parameter
- **GPU version**:
  - Uses NVIDIA CUDA base image (12.6.3-cudnn-runtime-ubuntu24.04)
  - Includes CUDA and cuDNN for GPU acceleration
- **CPU version**:
  - Uses Ubuntu base image (24.04)
  - Lightweight without CUDA dependencies
- Downloads and installs GitHub Actions runner binary (v2.330.0)
- Installs Python dependencies from `builder/requirements.txt`
- Sets `RUNNER_ALLOW_RUNASROOT=1` to allow root execution

### Key Flow

1. RunPod invokes the handler with job input containing `github_pat` and `github_org`
2. Handler fetches registration token from GitHub API
3. Runner is configured with organization URL and labels (`runpod`, pod ID)
4. Runner executes single GitHub Actions job
5. Runner is deregistered and removed

### Environment Variables

**Required**:
- `GITHUB_PAT`: GitHub Personal Access Token (can be passed via input or env)
- `GITHUB_ORG`: GitHub organization name (can be passed via input or env)

**Automatic**:
- `RUNPOD_POD_ID`: Used as runner name (defaults to "serverless-runpod-runner")
- `JOB_INPUT`: Event input passed to runner environment

**Filtered**: The handler removes RunPod-specific env vars before starting the runner to avoid conflicts.

## Development Commands

### Build Docker Image

**GPU version (default):**
```bash
docker build -t your-org/worker-github_runner:gpu .
```

**CPU version:**
```bash
docker build --build-arg BUILD_TYPE=cpu -t your-org/worker-github_runner:cpu .
```

**Custom runner version:**
```bash
docker build --build-arg RUNNER_VERSION=2.330.0 -t your-org/worker-github_runner:gpu .
```

**Available build arguments:**
- `BUILD_TYPE`: `gpu` (default) or `cpu`
- `RUNNER_VERSION`: GitHub Runner version (default: `2.330.0`)
- `CUDA_VERSION`: CUDA version for GPU builds (default: `12.6.3`)

### Local Testing
The handler expects RunPod serverless input format:
```python
python3 src/handler.py
```

### Dependency Management
Dependencies are in `builder/requirements.txt`:
- `runpod~=1.7.0` (uses compatible release operator `~=`)
- `requests==2.31.0`

Note: The project uses `~=` for runpod to allow patch updates within the same major.minor version.

## CI/CD Workflows

### Automated Dependency Updates (`CI-update_runpod_pkg.yml`)
- Monitors PyPI for new runpod package versions
- Only updates when major.minor version changes (e.g., 1.7.x → 1.8.x)
- Automatically creates PR with version bump

### Docker Image Publishing
- **Dev builds** (`CD-docker_dev.yml`):
  - Builds both GPU and CPU versions on every main branch push
  - Pushes to `:dev-gpu` and `:dev-cpu` tags
  - Uses matrix strategy for parallel builds
- **Release builds** (`CD-docker_release.yml`):
  - Builds both GPU and CPU versions on release
  - Pushes to `:v{version}-gpu`, `:v{version}-cpu`, `:latest-gpu`, and `:latest-cpu` tags
  - Uses matrix strategy for parallel builds

### Version Selection Guide
- **Use GPU version** for:
  - ML/AI model training and inference
  - GPU-accelerated testing (PyTorch, TensorFlow, etc.)
  - CUDA-dependent applications
- **Use CPU version** for:
  - Standard CI/CD pipelines
  - Unit and integration testing
  - Code linting and formatting
  - General-purpose automation

## Important Notes

- The runner uses `--once` flag, meaning each worker handles exactly one job then exits
- Runner name is set to the RunPod pod ID for traceability
- The handler uses `refresh_worker: True` in RunPod config to ensure clean state between jobs
- Both GPU and CPU versions use the same handler code and support identical features
- GPU version image size: ~4.5GB; CPU version: ~1.2GB
- Default build type is GPU for backward compatibility
- GitHub runner version updated from 2.305.0 to 2.330.0
- CUDA version updated from 11.7.1 to 12.6.3 (GPU only)
- Ubuntu version updated from 20.04 to 24.04
