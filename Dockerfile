# Build arguments
ARG BUILD_TYPE=gpu
ARG RUNNER_VERSION=2.330.0
ARG CUDA_VERSION=12.6.3

# Base image selection based on build type
FROM nvidia/cuda:${CUDA_VERSION}-cudnn-runtime-ubuntu24.04 AS base-gpu
FROM ubuntu:24.04 AS base-cpu

# Select the appropriate base
FROM base-${BUILD_TYPE} AS base

# Use bash shell with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set the working directory
WORKDIR /

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_ALLOW_RUNASROOT=1

# Update and upgrade the system packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    libssl-dev \
    libffi-dev \
    openssh-server \
    python3 \
    python3-dev \
    python3-pip \
    ca-certificates \
    jq \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY builder/requirements.txt /requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install --upgrade pip && \
    pip3 install --upgrade -r /requirements.txt --no-cache-dir && \
    rm /requirements.txt

# Download and install GitHub Actions runner
RUN mkdir actions-runner && cd actions-runner && \
    curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm -rf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Install additional dependencies
RUN /actions-runner/bin/installdependencies.sh

# Add build type label for identification
ARG BUILD_TYPE
ARG RUNNER_VERSION
ENV BUILD_TYPE=${BUILD_TYPE}
LABEL build_type=${BUILD_TYPE}
LABEL runner_version=${RUNNER_VERSION}

# Add src files
ADD src .

CMD python3 -u /handler.py
