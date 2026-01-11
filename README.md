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

## Documentation

For more details on how this GitHub Actions worker functions and how to integrate it into your CI/CD pipeline, please refer to the [Documentation](./docs).

## Contributing

We welcome contributions from the community! Please read our [Contributing Guide](./CONTRIBUTING.md) for more details on how to contribute to this project.

## License

This project is licensed under the [MIT License](./LICENSE). Please read the [LICENSE](./LICENSE) file for more details.
