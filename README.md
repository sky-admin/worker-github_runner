# README.md

<div align="center">

# GitHub Action | Worker

</div>

## Overview

This repository hosts the code for deploying a GitHub Actions worker on the Runpod platform. This worker is designed to be part of your CI/CD pipeline, running tests, or performing any compute-intensive tasks that are best offloaded from your local development environment or GitHub-hosted runners.

## Table of Contents

- [README.md](#readmemd)
- [GitHub Action | Worker](#github-action--worker)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Prerequisites](#prerequisites)
  - [Getting Started](#getting-started)
  - [Documentation](#documentation)
  - [Contributing](#contributing)
  - [License](#license)

## Features

- Deploy a GitHub Actions worker on the Runpod serverless platform.
- Can be integrated into your CI/CD pipeline for running tests and other tasks.
- Uses Docker to ensure a consistent runtime environment across multiple deployments.
- Support for both GPU and CPU versions:
  - **GPU version**: Includes NVIDIA CUDA 12.6.3 and cuDNN for GPU-accelerated workloads
  - **CPU version**: Lightweight version without CUDA dependencies for CPU-only tasks

## Choosing the Right Version

This worker is available in two versions to suit different workload requirements:

### GPU Version (Recommended for ML/AI workloads)
- **Base Image**: `nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04`
- **Use Cases**:
  - Machine learning model training and inference
  - GPU-accelerated testing (PyTorch, TensorFlow, etc.)
  - CUDA-dependent applications
  - Compute-intensive tasks requiring GPU acceleration
- **Docker Tags**: `:dev-gpu`, `:latest-gpu`, `:v1.0.0-gpu`

### CPU Version (Recommended for general CI/CD)
- **Base Image**: `ubuntu:24.04`
- **Use Cases**:
  - Standard CI/CD pipelines
  - Unit and integration testing
  - Code linting and formatting
  - Documentation generation
  - General-purpose automation tasks
- **Docker Tags**: `:dev-cpu`, `:latest-cpu`, `:v1.0.0-cpu`

**Note**: Both versions use GitHub Actions Runner v2.330.0 and support the same RunPod serverless features.

## Prerequisites

- Docker installed on your machine.
- An active account on Runpod.
- Runpod API key.

## Getting Started

1. Clone this repository.

   ```bash
   git clone https://github.com/your-org/worker-github_runner.git
   ```

2. Change the directory to `worker-github_runner`.

   ```bash
   cd worker-github_runner
   ```

3. Build the Docker image:

   **For GPU version:**
   ```bash
   docker build -t your-org/worker-github_runner:gpu .
   ```

   **For CPU version:**
   ```bash
   docker build --build-arg BUILD_TYPE=cpu -t your-org/worker-github_runner:cpu .
   ```

   **Or pull pre-built images:**
   ```bash
   # GPU version
   docker pull runpod/worker-github_runner:latest-gpu

   # CPU version
   docker pull runpod/worker-github_runner:latest-cpu
   ```

4. Set up your Runpod API key and other necessary environment variables.

5. Deploy your worker to the Runpod platform.

## Technical Details

### Docker Images

#### GPU Version
- **Base Image**: `nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04`
- **GitHub Runner Version**: `2.330.0`
- **CUDA Support**: Yes (12.6.3 with cuDNN)
- **Image Size**: ~4.5GB
- **Python Dependencies**:
  - `runpod~=1.7.0`
  - `requests==2.31.0`

#### CPU Version
- **Base Image**: `ubuntu:24.04`
- **GitHub Runner Version**: `2.330.0`
- **CUDA Support**: No
- **Image Size**: ~1.2GB
- **Python Dependencies**:
  - `runpod~=1.7.0`
  - `requests==2.31.0`

### Build Arguments

You can customize the build using the following arguments:

| Argument | Description | Default | Example |
|----------|-------------|---------|---------|
| `BUILD_TYPE` | Build type (gpu/cpu) | `gpu` | `--build-arg BUILD_TYPE=cpu` |
| `RUNNER_VERSION` | GitHub Runner version | `2.330.0` | `--build-arg RUNNER_VERSION=2.330.0` |
| `CUDA_VERSION` | CUDA version (GPU only) | `12.6.3` | `--build-arg CUDA_VERSION=12.6.3` |
| `KANIKO_VERSION` | Kaniko executor version | `v1.23.2` | `--build-arg KANIKO_VERSION=v1.23.2` |

## Building Docker Images in RunPod Environment

### The Challenge

RunPod manages the Docker daemon for you, which means you cannot run your own Docker instance inside a Pod. This prevents using standard `docker build` commands or Docker-in-Docker (DinD) approaches.

**Error you might encounter:**
```
failed to connect to the docker API at unix:///var/run/docker.sock
dial unix /var/run/docker.sock: connect: no such file or directory
```

### The Solution: Kaniko

This runner image includes **Kaniko**, a tool for building container images without requiring a Docker daemon. Kaniko executes each command within a Dockerfile completely in userspace, making it perfect for restricted environments like RunPod.

### Using Kaniko

#### Basic Usage

```bash
# Build and push an image
kaniko \
  --dockerfile=./Dockerfile \
  --context=. \
  --destination=docker.io/username/image:tag \
  --cache=true \
  --cache-repo=docker.io/username/cache
```

#### In GitHub Actions Workflow

```yaml
name: Build with Kaniko
on: [push]

jobs:
  build:
    runs-on: self-hosted  # Your RunPod runner
    steps:
      - uses: actions/checkout@v4

      - name: Setup Kaniko auth
        env:
          DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
          DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
        run: |
          mkdir -p /kaniko/.docker
          echo '{"auths":{"https://index.docker.io/v1/":{"auth":"'$(echo -n $DOCKER_USERNAME:$DOCKER_PASSWORD | base64)'"}}}'  > /kaniko/.docker/config.json

      - name: Build and push
        run: |
          kaniko \
            --dockerfile=./Dockerfile \
            --context=. \
            --destination=docker.io/${{ secrets.DOCKER_USERNAME }}/image:${{ github.sha }} \
            --cache=true
```

#### Complete Example

See [`.github/workflows/example-kaniko-build.yml`](./.github/workflows/example-kaniko-build.yml) for a complete working example with:
- Docker Hub authentication
- Multi-tag support
- Caching configuration
- Metadata labels

### Kaniko Features

- ✅ **No Docker daemon required** - Works in RunPod environment
- ✅ **No privileged mode needed** - More secure
- ✅ **Layer caching** - Speeds up builds
- ✅ **Multi-stage builds** - Full Dockerfile support
- ✅ **Registry push** - Direct push to Docker Hub, GCR, ECR, etc.

### Kaniko vs Docker

| Feature | Docker | Kaniko |
|---------|--------|--------|
| Requires daemon | Yes | No |
| Privileged mode | Required | Not required |
| Build speed | Faster | Slightly slower |
| Cache support | Full | Good |
| Dockerfile compatibility | 100% | ~95% |
| RunPod compatible | ❌ No | ✅ Yes |

## Documentation

For more details on how this GitHub Actions worker functions and how to integrate it into your CI/CD pipeline, please refer to the [Documentation](./docs).

## Contributing

We welcome contributions from the community! Please read our [Contributing Guide](./CONTRIBUTING.md) for more details on how to contribute to this project.

## License

This project is licensed under the [MIT License](./LICENSE). Please read the [LICENSE](./LICENSE) file for more details.
