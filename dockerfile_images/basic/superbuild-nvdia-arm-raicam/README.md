
# README: ARM64 Docker Image Build on AMD64 Host

## Overview
This image is based on an ARM64 (`linux/arm64`) platform image, which differs from typical AMD64 (`linux/amd64`) host machines. Building requires Docker's `buildx` feature for cross-platform compilation.

## Prerequisites

### 1. Create an ARM64 Builder
```bash
docker buildx create --platform linux/arm64
```

## Building the Image

### On AMD64 Host
```bash
docker buildx build --platform linux/arm64 \
    --build-arg START_IMG="nvcr.io/nvidia/l4t-jetpack:r36.4.0" \
    -f ./Dockerfile \
    --load \
    -t raicam-jetpack-test:v1 .
```

## Validating the Image

### Register QEMU for ARM64
```bash
docker run --privileged --rm tonistiigi/binfmt --install arm64
```

### Run Container
```bash
docker run -it --rm --platform linux/arm64 raicam-jetpack-test:v1 /bin/bash
```

## ⚠️ Important Limitations

Running this ARM64 container on an AMD64 host via QEMU has significant limitations:
- **NVIDIA packages cannot be fully virtualized** by QEMU
- Performance is heavily degraded
- Full testing **must be performed on actual Jetson hardware**

Use QEMU validation only for basic functionality checks, not for NVIDIA-specific features.
